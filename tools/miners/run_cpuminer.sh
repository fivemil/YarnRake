#!/usr/bin/env bash
# Integrated miner helper: cpuminer-opt → local YarnRake stratum
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
USER="${YARNRAKE_WORKER:-device-1}"
PASS="${YARNRAKE_PASS:-x}"
ALGO="${YARNRAKE_ALGO:-skein}"
case "$ALGO" in
  skein|skein-512) CA="skein" ;;
  yescrypt_r16|yescrypt|yescryptr16) CA="yescrypt" ;;
  sha256d|sha256) CA="sha256d" ;;
  scrypt) CA="scrypt" ;;
  x11) CA="x11" ;;
  neoscrypt) CA="neoscrypt" ;;
  lyra2rev3|lyra2re3) CA="lyra2rev3" ;;
  blake2s) CA="blake2s" ;;
  *) CA="$ALGO" ;;
esac
exec cpuminer -o "stratum+tcp://${HOST}:${PORT}" -u "$USER" -p "$PASS" -a "$CA" "$@"
