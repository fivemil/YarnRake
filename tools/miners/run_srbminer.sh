#!/usr/bin/env bash
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
USER="${YARNRAKE_WORKER:-device-1}"
ALGO="${YARNRAKE_ALGO:-kheavyhash}"
# SRBMiner-MULTI binary name varies by platform
BIN="${SRB_BIN:-srbminer-multi}"
exec "$BIN" --algorithm "$ALGO" --pool "${HOST}:${PORT}" --wallet "$USER" "$@"
