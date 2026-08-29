#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOST="${YARNRAKE_HOST:-}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
WORKER="${YARNRAKE_WORKER:-$(hostname -s 2>/dev/null || echo home-1)}"
ALGO="${YARNRAKE_ALGO:-randomx}"
DO_CHECK=0 DO_XMRIG=0 DO_CPU=0 DO_LOL=0 DO_ONBOARD=0 RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift ;;
    --worker) WORKER="$2"; shift ;;
    --algo) ALGO="$2"; shift ;;
    --check) DO_CHECK=1 ;;
    --xmrig) DO_XMRIG=1 ;;
    --cpuminer) DO_CPU=1 ;;
    --lolminer) DO_LOL=1 ;;
    --onboard) DO_ONBOARD=1 ;;
    --run) RUN=1 ;;
    -h|--help) echo "Home worker: --check --xmrig|--cpuminer|--lolminer [--run] [--host IP]"; exit 0 ;;
    *) echo "unknown $1"; exit 1 ;;
  esac
  shift
done
[[ -n "$HOST" ]] || HOST=127.0.0.1
echo "pool=$HOST:$PORT worker=$WORKER algo=$ALGO"
if command -v nc >/dev/null; then
  nc -z -w 3 "$HOST" "$PORT" && echo "stratum OK" || echo "stratum FAIL"
fi
if command -v curl >/dev/null; then
  curl -fsS -m 3 "http://$HOST:8787/pool" >/dev/null && echo "console OK" || echo "console optional"
fi
[[ "$DO_CHECK" -eq 1 ]] && exit 0
if [[ "$DO_ONBOARD" -eq 1 ]]; then
  curl -fsS -X POST "http://$HOST:8787/onboard" -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "name=$WORKER" --data-urlencode "type=cpu" --data-urlencode "worker=$WORKER" \
    --data-urlencode "algo=$ALGO" --data-urlencode "software=home-worker" --data-urlencode "platform=linux" || true
fi
export YARNRAKE_HOST="$HOST" YARNRAKE_STRATUM_PORT="$PORT" YARNRAKE_WORKER="$WORKER" YARNRAKE_ALGO="$ALGO"
run_script() {
  local s="$1" bin="$2"
  echo "YARNRAKE_HOST=$HOST YARNRAKE_WORKER=$WORKER YARNRAKE_ALGO=$ALGO $ROOT/tools/miners/$s"
  if [[ "$RUN" -eq 1 ]]; then
    command -v "$bin" >/dev/null || { echo "install $bin"; exit 1; }
    exec env YARNRAKE_HOST="$HOST" YARNRAKE_STRATUM_PORT="$PORT" YARNRAKE_WORKER="$WORKER" YARNRAKE_ALGO="$ALGO" bash "$ROOT/tools/miners/$s"
  fi
}
if [[ "$DO_XMRIG" -eq 1 ]]; then run_script run_xmrig.sh xmrig
elif [[ "$DO_CPU" -eq 1 ]]; then run_script run_cpuminer.sh cpuminer-opt
elif [[ "$DO_LOL" -eq 1 ]]; then run_script run_lolminer.sh lolMiner
else echo "use --xmrig | --cpuminer | --lolminer"; fi
