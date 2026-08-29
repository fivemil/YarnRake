#!/usr/bin/env bash
# Bootstrap a Linux VM as a YarnRake stratum worker (not the pool itself).
#   export YARNRAKE_HOST=pool.example.com
#   ./tools/cloud_worker_setup.sh --xmrig
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${YARNRAKE_HOST:-}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
WORKER="${YARNRAKE_WORKER:-$(hostname -s 2>/dev/null || echo worker-1)}"
ALGO="${YARNRAKE_ALGO:-randomx}"
INSTALL_XMRIG=0
INSTALL_CPU=0
CHECK_ONLY=0

usage() {
  cat <<EOF
Cloud worker setup (hash → remote YarnRake stratum)

  --xmrig         Check xmrig + print run command
  --cpuminer      Hints for cpuminer-opt
  --check         Only test TCP reachability to pool
  --host HOST     Pool hostname/IP
  --worker NAME   Worker name
  --algo NAME     Algo (default: randomx)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --xmrig) INSTALL_XMRIG=1 ;;
    --cpuminer) INSTALL_CPU=1 ;;
    --check) CHECK_ONLY=1 ;;
    --host) HOST="$2"; shift ;;
    --worker) WORKER="$2"; shift ;;
    --algo) ALGO="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown: $1"; usage; exit 1 ;;
  esac
  shift
done

if [[ -z "$HOST" ]]; then
  echo "error: set YARNRAKE_HOST or --host" >&2
  exit 1
fi

echo "== Reachability $HOST:$PORT =="
if command -v nc >/dev/null 2>&1; then
  if nc -z -w 3 "$HOST" "$PORT" 2>/dev/null; then
    echo "OK: TCP $HOST:$PORT open"
  else
    echo "FAIL: cannot connect — open firewall / confirm pool is running"
    exit 1
  fi
else
  echo "(nc not installed; skip TCP probe)"
fi

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  exit 0
fi

export YARNRAKE_HOST="$HOST"
export YARNRAKE_STRATUM_PORT="$PORT"
export YARNRAKE_WORKER="$WORKER"
export YARNRAKE_ALGO="$ALGO"

echo "== Worker config =="
echo "  host=$HOST port=$PORT worker=$WORKER algo=$ALGO"

if [[ "$INSTALL_XMRIG" -eq 1 ]]; then
  if command -v xmrig >/dev/null 2>&1; then
    echo "xmrig: $(command -v xmrig)"
  else
    echo "Install xmrig: https://github.com/xmrig/xmrig/releases"
    echo "Then: YARNRAKE_HOST=$HOST YARNRAKE_WORKER=$WORKER YARNRAKE_ALGO=$ALGO $ROOT/tools/miners/run_xmrig.sh"
    exit 0
  fi
  echo "Run:"
  echo "  YARNRAKE_HOST=$HOST YARNRAKE_STRATUM_PORT=$PORT YARNRAKE_WORKER=$WORKER YARNRAKE_ALGO=$ALGO \\"
  echo "    $ROOT/tools/miners/run_xmrig.sh"
fi

if [[ "$INSTALL_CPU" -eq 1 ]]; then
  if command -v cpuminer-opt >/dev/null 2>&1; then
    echo "cpuminer-opt: $(command -v cpuminer-opt)"
  else
    echo "Install cpuminer-opt: https://github.com/JayDDee/cpuminer-opt"
  fi
  echo "Run:"
  echo "  YARNRAKE_HOST=$HOST YARNRAKE_WORKER=$WORKER YARNRAKE_ALGO=$ALGO \\"
  echo "    $ROOT/tools/miners/run_cpuminer.sh"
fi

if [[ "$INSTALL_XMRIG" -eq 0 && "$INSTALL_CPU" -eq 0 ]]; then
  usage
  echo
  echo "Pool URL: stratum+tcp://${HOST}:${PORT}"
fi
