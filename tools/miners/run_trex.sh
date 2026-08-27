#!/usr/bin/env bash
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
USER="${YARNRAKE_WORKER:-device-1}"
ALGO="${YARNRAKE_ALGO:-kawpow}"
case "$ALGO" in
  kawpow) TA="kawpow" ;;
  etchash) TA="etchash" ;;
  octopus) TA="octopus" ;;
  autolykos2|autolykos) TA="autolykos2" ;;
  *) TA="kawpow" ;;
esac
exec t-rex -a "$TA" -o "stratum+tcp://${HOST}:${PORT}" -u "$USER" -p x "$@"
