#!/usr/bin/env bash
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
USER="${YARNRAKE_WORKER:-device-1}"
# miniZ equihash variants — adjust -a for your coin
exec miniZ --url "${USER}@${HOST}:${PORT}" --pass x -a 144,5 "$@"
