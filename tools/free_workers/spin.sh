#!/usr/bin/env bash
# Spin free-tier-friendly workers within catalog limits only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CATALOG="$ROOT/tools/free_workers/catalog.json"
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
WORKER="${YARNRAKE_WORKER:-free-worker}"
DURATION=""
BACKEND=""
PRINT_ONLY=0

die() { echo "error: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 <backend>|--list [--worker NAME] [--duration SEC] [--host HOST] [--print]

Backends: local-lab, docker-lab, compose-worker, fly-lab, smoke-ci
EOF
}

catalog_field() {
  local id="$1" field="$2"
  python3 - "$CATALOG" "$id" "$field" <<'PY'
import json,sys
cat=json.load(open(sys.argv[1]))
bid,field=sys.argv[2],sys.argv[3]
for b in cat["backends"]:
    if b["id"]==bid:
        v=b.get(field)
        if isinstance(v,bool):
            print("true" if v else "false")
        else:
            print(v if v is not None else "")
        raise SystemExit(0)
raise SystemExit(f"unknown backend {bid}")
PY
}

list_backends() {
  python3 - "$CATALOG" <<'PY'
import json,sys
cat=json.load(open(sys.argv[1]))
print(f"{'ID':<16} {'ON':<5} {'MAX_S':>6}  TITLE")
for b in cat["backends"]:
    on="yes" if b.get("enabled") else "no"
    print(f"{b['id']:<16} {on:<5} {b.get('max_duration_s',0):>6}  {b.get('title','')}")
    print(f"  limits: {b.get('limits','')}")
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) list_backends; exit 0 ;;
    --worker) WORKER="$2"; shift ;;
    --duration) DURATION="$2"; shift ;;
    --host) HOST="$2"; shift ;;
    --print) PRINT_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown flag $1" ;;
    *) BACKEND="$1" ;;
  esac
  shift
done

[[ -n "$BACKEND" ]] || { usage; exit 1; }
[[ -f "$CATALOG" ]] || die "missing $CATALOG"

enabled=$(catalog_field "$BACKEND" enabled)
[[ "$enabled" == "true" ]] || die "backend '$BACKEND' disabled — see catalog"

max_s=$(catalog_field "$BACKEND" max_duration_s)
def_s=$(catalog_field "$BACKEND" default_duration_s)
needs_pub=$(catalog_field "$BACKEND" needs_public_pool)

if [[ -z "$DURATION" ]]; then DURATION="$def_s"; fi
if [[ "$DURATION" -gt "$max_s" ]]; then
  echo "warn: duration $DURATION > max $max_s for $BACKEND — clamping"
  DURATION="$max_s"
fi
[[ "$DURATION" -ge 1 ]] || die "duration must be >= 1"

if [[ "$needs_pub" == "true" ]]; then
  if [[ "$HOST" == "127.0.0.1" || "$HOST" == "localhost" ]]; then
    die "$BACKEND needs a public YARNRAKE_HOST (not localhost)"
  fi
fi

echo "== free worker =="
echo "  backend=$BACKEND pool=$HOST:$PORT worker=$WORKER duration=${DURATION}s (max ${max_s}s)"

case "$BACKEND" in
  local-lab)
    [[ "$PRINT_ONLY" -eq 1 ]] && { echo "python3 tools/stratum_client.py --host $HOST --port $PORT --user $WORKER --duration $DURATION"; exit 0; }
    exec python3 "$ROOT/tools/stratum_client.py" --host "$HOST" --port "$PORT" --user "$WORKER" --duration "$DURATION"
    ;;
  docker-lab)
    command -v docker >/dev/null || die "docker not installed"
    cmd=(docker run --rm --name "yr-free-$WORKER" --network host
      -v "$ROOT/tools/stratum_client.py:/app/stratum_client.py:ro"
      python:3.12-slim
      python3 /app/stratum_client.py --host "$HOST" --port "$PORT" --user "$WORKER" --duration "$DURATION")
    [[ "$PRINT_ONLY" -eq 1 ]] && { printf '%q ' "${cmd[@]}"; echo; exit 0; }
    "${cmd[@]}"
    ;;
  compose-worker)
    [[ "$PRINT_ONLY" -eq 1 ]] && { echo "docker compose --profile workers up -d"; exit 0; }
    command -v docker >/dev/null || die "docker not installed"
    (cd "$ROOT" && docker compose --profile workers up -d)
    echo "stop: docker compose --profile workers down"
    ;;
  fly-lab)
    if [[ "$PRINT_ONLY" -eq 1 ]]; then
      echo "fly machine run python:3.12-slim --rm --restart=no --command '… stratum_client duration=$DURATION …'"
      exit 0
    fi
    FLY=$(command -v flyctl 2>/dev/null || command -v fly || true)
    [[ -n "$FLY" ]] || die "flyctl not installed"
    $FLY machine run python:3.12-slim --rm --restart=no \
      --command "bash -c 'apt-get update -qq && apt-get install -y -qq curl ca-certificates >/dev/null && curl -fsSL -o /tmp/c.py https://raw.githubusercontent.com/fivemil/YarnRake/main/tools/stratum_client.py && python3 /tmp/c.py --host $HOST --port $PORT --user $WORKER --duration $DURATION'"
    ;;
  smoke-ci)
    echo "Workflow: .github/workflows/stratum-smoke.yml (cap ${max_s}s)"
    if command -v gh >/dev/null 2>&1; then
      gh workflow run stratum-smoke.yml -f "worker=$WORKER" -f "duration=$DURATION" -f "host=$HOST" || true
    else
      echo "Set vars.YARNRAKE_HOST and run from Actions UI"
    fi
    ;;
  *) die "unhandled backend $BACKEND" ;;
esac
