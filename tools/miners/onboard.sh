#!/bin/bash
# Register a local mining device with YarnRake HTTP API
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_PORT:-8787}"
NAME=""
TYPE="cpu"
WORKER=""
ALGO=""
SOFTWARE=""
PLATFORM="linux"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --worker) WORKER="$2"; shift 2 ;;
    --algo) ALGO="$2"; shift 2 ;;
    --software) SOFTWARE="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --type cpu|gpu|asic|mobile|hybrid|other --name NAME --worker WORKER [--algo A] [--software S]"
      exit 0
      ;;
    *) echo "unknown arg $1"; exit 1 ;;
  esac
done

[[ -n "$NAME" ]] || { echo "need --name"; exit 1; }
[[ -n "$WORKER" ]] || WORKER="$NAME"

BODY="name=${NAME}&type=${TYPE}&worker=${WORKER}&algo=${ALGO}&software=${SOFTWARE}&platform=${PLATFORM}"
echo "POST http://${HOST}:${PORT}/onboard"
curl -sS -X POST "http://${HOST}:${PORT}/onboard" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "$BODY"
echo
