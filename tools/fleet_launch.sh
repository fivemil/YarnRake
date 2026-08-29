#!/usr/bin/env bash
# MagiMDM + YarnRake fleet quick launcher
# Usage:
#   ./tools/fleet_launch.sh --yarnrake --lab-client
#   ./tools/fleet_launch.sh --yarnrake --xmrig --worker pc1 --algo randomx
#   ./tools/fleet_launch.sh --all-lab   # yarnrake + lab stratum client
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PID_DIR="${YARNRAKE_PID_DIR:-$ROOT/.run}"
mkdir -p "$PID_DIR"

DO_YARNRAKE=0
DO_MDM=0
DO_MOCK=0
DO_LAB=0
DO_XMRIG=0
DO_CPUMINER=0
DO_LOLMINER=0
DO_ONBOARD=0
WORKER="${YARNRAKE_WORKER:-device-1}"
ALGO="${YARNRAKE_ALGO:-skein}"
MDM_PATH="${MAGIMDM_PATH:-}"
MDM_PORT="${MAGIMDM_PORT:-8788}"
YR_PORT="${YARNRAKE_PORT:-8787}"
STRATUM_PORT="${YARNRAKE_STRATUM_PORT:-3333}"
STOP=0

usage() {
  cat <<EOF
YarnRake / MagiMDM fleet launcher

Options (checkboxes as flags):
  --yarnrake          Start YarnRake (HTTP + stratum)
  --mdm               Start MagiMDM if MAGIMDM_PATH points at a built tree
  --mock-agent        Python mock MagiMDM agent (needs MagiMDM on MDM_PORT)
  --lab-client        YarnRake lab stratum client (no external miner binary)
  --xmrig             Launch xmrig → YarnRake
  --cpuminer          Launch cpuminer-opt → YarnRake
  --lolminer          Launch lolMiner → YarnRake
  --onboard           Register a local device in YarnRake
  --all-lab           --yarnrake --lab-client --onboard
  --worker NAME       Worker name (default: device-1)
  --algo NAME         Algo (default: skein)
  --stop              Stop processes started by this script
  -h, --help          This help

Env:
  MAGIMDM_PATH        Path to MagiMDM repo with zig-out/bin/zig-mdm
  YARNRAKE_PORT       HTTP port (default 8787)
  YARNRAKE_STRATUM_PORT  Stratum (default 3333)
  MAGIMDM_PORT        MagiMDM HTTP (default 8788)

Examples:
  $0 --all-lab
  $0 --yarnrake --xmrig --algo randomx --worker office-pc
  $0 --yarnrake --mdm --mock-agent
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yarnrake) DO_YARNRAKE=1 ;;
    --mdm) DO_MDM=1 ;;
    --mock-agent) DO_MOCK=1 ;;
    --lab-client) DO_LAB=1 ;;
    --xmrig) DO_XMRIG=1 ;;
    --cpuminer) DO_CPUMINER=1 ;;
    --lolminer) DO_LOLMINER=1 ;;
    --onboard) DO_ONBOARD=1 ;;
    --all-lab) DO_YARNRAKE=1; DO_LAB=1; DO_ONBOARD=1 ;;
    --worker) WORKER="$2"; shift ;;
    --algo) ALGO="$2"; shift ;;
    --stop) STOP=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

stop_all() {
  echo "Stopping fleet PIDs in $PID_DIR"
  for f in "$PID_DIR"/*.pid; do
    [[ -f "$f" ]] || continue
    pid=$(cat "$f" 2>/dev/null || true)
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "  kill $pid ($(basename "$f" .pid))"
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$f"
  done
}

if [[ "$STOP" -eq 1 ]]; then
  stop_all
  exit 0
fi

if [[ $DO_YARNRAKE -eq 0 && $DO_MDM -eq 0 && $DO_MOCK -eq 0 && $DO_LAB -eq 0 \
   && $DO_XMRIG -eq 0 && $DO_CPUMINER -eq 0 && $DO_LOLMINER -eq 0 && $DO_ONBOARD -eq 0 ]]; then
  echo "No options selected. Use --all-lab or --help"
  usage
  exit 1
fi

start_bg() {
  local name="$1"; shift
  echo "[start] $name: $*"
  "$@" >"$PID_DIR/$name.log" 2>&1 &
  echo $! >"$PID_DIR/$name.pid"
  echo "  pid $(cat "$PID_DIR/$name.pid") log $PID_DIR/$name.log"
}

if [[ "$DO_YARNRAKE" -eq 1 ]]; then
  BIN="$ROOT/zig-out/bin/yarnrake"
  if [[ ! -x "$BIN" ]]; then
    echo "Building YarnRake..."
    (cd "$ROOT" && zig build)
  fi
  if [[ ! -x "$BIN" ]]; then
    echo "error: $BIN missing after zig build" >&2
    exit 1
  fi
  export YARNRAKE_ALGO="$ALGO"
  export YARNRAKE_PORT="$YR_PORT"
  export YARNRAKE_STRATUM_PORT="$STRATUM_PORT"
  start_bg yarnrake "$BIN"
  sleep 0.5
fi

if [[ "$DO_MDM" -eq 1 ]]; then
  if [[ -z "$MDM_PATH" ]]; then
    echo "warn: --mdm set but MAGIMDM_PATH empty; skip MagiMDM"
  else
    MDM_BIN="$MDM_PATH/zig-out/bin/zig-mdm"
    if [[ ! -x "$MDM_BIN" ]]; then
      echo "Building MagiMDM in $MDM_PATH..."
      (cd "$MDM_PATH" && zig build) || echo "warn: MagiMDM build failed (tree may be incomplete on GitHub)"
    fi
    if [[ -x "$MDM_BIN" ]]; then
      start_bg magimdm env PORT="$MDM_PORT" "$MDM_BIN" || true
    else
      echo "warn: no MagiMDM binary at $MDM_BIN"
    fi
  fi
fi

if [[ "$DO_ONBOARD" -eq 1 ]]; then
  sleep 0.3
  if [[ -x "$ROOT/tools/miners/onboard.sh" ]]; then
    "$ROOT/tools/miners/onboard.sh" --type cpu --name "fleet-$WORKER" --worker "$WORKER" --algo "$ALGO" --software fleet-launch || true
  else
    curl -s -X POST "http://127.0.0.1:${YR_PORT}/onboard" \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      --data-urlencode "name=fleet-$WORKER" \
      --data-urlencode "type=cpu" \
      --data-urlencode "worker=$WORKER" \
      --data-urlencode "algo=$ALGO" \
      --data-urlencode "software=fleet-launch" || true
  fi
fi

export YARNRAKE_HOST=127.0.0.1
export YARNRAKE_STRATUM_PORT="$STRATUM_PORT"
export YARNRAKE_WORKER="$WORKER"
export YARNRAKE_ALGO="$ALGO"

if [[ "$DO_LAB" -eq 1 ]]; then
  start_bg lab-client python3 "$ROOT/tools/stratum_client.py" --user "$WORKER" --duration 3600
fi
if [[ "$DO_XMRIG" -eq 1 ]]; then
  start_bg xmrig bash "$ROOT/tools/miners/run_xmrig.sh"
fi
if [[ "$DO_CPUMINER" -eq 1 ]]; then
  start_bg cpuminer bash "$ROOT/tools/miners/run_cpuminer.sh"
fi
if [[ "$DO_LOLMINER" -eq 1 ]]; then
  start_bg lolminer bash "$ROOT/tools/miners/run_lolminer.sh"
fi

if [[ "$DO_MOCK" -eq 1 ]]; then
  MOCK=""
  if [[ -n "$MDM_PATH" && -f "$MDM_PATH/tools/mock_agent.py" ]]; then
    MOCK="$MDM_PATH/tools/mock_agent.py"
  elif [[ -f "$ROOT/../MagiMDM/tools/mock_agent.py" ]]; then
    MOCK="$ROOT/../MagiMDM/tools/mock_agent.py"
  fi
  if [[ -n "$MOCK" ]]; then
    start_bg mock-agent python3 "$MOCK" --auto --uuid "fleet-$WORKER" --interval 5 || true
  else
    echo "warn: mock_agent.py not found; set MAGIMDM_PATH"
  fi
fi

echo
echo "=== Fleet up ==="
echo "  YarnRake UI:  http://127.0.0.1:${YR_PORT}/launch"
echo "  Pool JSON:    http://127.0.0.1:${YR_PORT}/pool"
echo "  Stratum:      stratum+tcp://127.0.0.1:${STRATUM_PORT}"
if [[ "$DO_MDM" -eq 1 ]]; then
  echo "  MagiMDM:      http://127.0.0.1:${MDM_PORT}/login  (admin / changeme)"
fi
echo "  Stop:         $0 --stop"
echo "  Logs:         $PID_DIR/*.log"
