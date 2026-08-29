#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PID_DIR="${YARNRAKE_HOME_PID_DIR:-$ROOT/.run/home}"
mkdir -p "$PID_DIR"
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
WORKER="${YARNRAKE_WORKER:-$(hostname -s 2>/dev/null || echo home)}"
ALGO="${YARNRAKE_ALGO:-randomx}"
DO_XMRIG=0 DO_CPU=0 DO_LOL=0 DO_LAB=0 STOP=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --xmrig) DO_XMRIG=1 ;;
    --cpuminer) DO_CPU=1 ;;
    --lolminer) DO_LOL=1 ;;
    --lab) DO_LAB=1 ;;
    --worker) WORKER="$2"; shift ;;
    --algo) ALGO="$2"; shift ;;
    --host) HOST="$2"; shift ;;
    --stop) STOP=1 ;;
    -h|--help) echo "$0 [--xmrig] [--cpuminer] [--lolminer] [--lab] [--stop]"; exit 0 ;;
    *) exit 1 ;;
  esac
  shift
done
if [[ "$STOP" -eq 1 ]]; then
  for f in "$PID_DIR"/*.pid; do
    [[ -f "$f" ]] || continue
    pid=$(cat "$f" 2>/dev/null || true)
    [[ -n "${pid:-}" ]] && kill "$pid" 2>/dev/null || true
    rm -f "$f"
  done
  exit 0
fi
start(){ local n="$1"; shift; env YARNRAKE_HOST="$HOST" YARNRAKE_STRATUM_PORT="$PORT" YARNRAKE_WORKER="$WORKER" YARNRAKE_ALGO="$ALGO" "$@" >"$PID_DIR/$n.log" 2>&1 & echo $! >"$PID_DIR/$n.pid"; echo "started $n pid $(cat $PID_DIR/$n.pid)"; }
[[ "$DO_LAB" -eq 1 ]] && start "lab-$WORKER" python3 "$ROOT/tools/stratum_client.py" --host "$HOST" --port "$PORT" --user "$WORKER" --duration 86400
[[ "$DO_XMRIG" -eq 1 ]] && start "xmrig-$WORKER" bash "$ROOT/tools/miners/run_xmrig.sh"
[[ "$DO_CPU" -eq 1 ]] && start "cpuminer-$WORKER" bash "$ROOT/tools/miners/run_cpuminer.sh"
[[ "$DO_LOL" -eq 1 ]] && start "lolminer-$WORKER" bash "$ROOT/tools/miners/run_lolminer.sh"
echo "Stop: $0 --stop"
