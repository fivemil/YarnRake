#!/usr/bin/env bash
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
USER="${YARNRAKE_WORKER:-device-1}"
ALGO="${YARNRAKE_ALGO:-etchash}"
exec teamredminer -a "$ALGO" -o "stratum+tcp://${HOST}:${PORT}" -u "$USER" -p x "$@"
