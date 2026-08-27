#!/usr/bin/env bash
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
USER="${YARNRAKE_WORKER:-device-1}"
ALGO="${YARNRAKE_ALGO:-kawpow}"
case "$ALGO" in
  kawpow) LA="KAWPOW" ;;
  etchash) LA="ETCHASH" ;;
  ethash) LA="ETHASH" ;;
  autolykos2|autolykos) LA="AUTOLYKOS2" ;;
  equihash) LA="EQUI144_5" ;;
  blake3) LA="BLAKE3" ;;
  fishhash) LA="FISHHASH" ;;
  cuckatoo32|cuckatoo) LA="C32" ;;
  *) LA="KAWPOW"; echo "note: lolMiner defaulting to KAWPOW for algo=$ALGO" ;;
esac
exec lolMiner --algo "$LA" --pool "${HOST}:${PORT}" --user "$USER" "$@"
