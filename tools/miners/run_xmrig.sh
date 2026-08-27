#!/usr/bin/env bash
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
USER="${YARNRAKE_WORKER:-device-1}"
PASS="${YARNRAKE_PASS:-x}"
ALGO="${YARNRAKE_ALGO:-randomx}"
case "$ALGO" in
  randomx|rx|rx/0|monero) XA="rx/0" ;;
  randomx_wow|rx/wow|wownero) XA="rx/wow" ;;
  ghostrider|gr|rtm) XA="gr" ;;
  *) XA="rx/0"; echo "note: xmrig defaulting to rx/0 for algo=$ALGO" ;;
esac
exec xmrig -o "stratum+tcp://${HOST}:${PORT}" -u "$USER" -p "$PASS" -a "$XA" --donate-level=1 "$@"
