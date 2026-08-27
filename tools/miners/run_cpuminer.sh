#!/usr/bin/env bash
# cpuminer-opt → YarnRake stratum (Skein, Yescrypt, Scrypt, X11, …)
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_STRATUM_PORT:-3333}"
USER="${YARNRAKE_WORKER:-device-1}"
PASS="${YARNRAKE_PASS:-x}"
ALGO="${YARNRAKE_ALGO:-skein}"
case "$ALGO" in
  skein|skein-512) CA="skein" ;;
  yescrypt_r16|yescrypt|yescryptr16) CA="yescrypt" ;;
  scrypt) CA="scrypt" ;;
  x11) CA="x11" ;;
  neoscrypt) CA="neoscrypt" ;;
  lyra2rev3|lyra2re3) CA="lyra2rev3" ;;
  blake2s) CA="blake2s" ;;
  blake2b) CA="blake2b" ;;
  sha256d|sha256) CA="sha256d" ;;
  argon2d|argon2) CA="argon2d" ;;
  *) CA="$ALGO"; echo "note: passing algo=$CA to cpuminer-opt" ;;
esac
BIN="${CPUMiner_BIN:-cpuminer-opt}"
if ! command -v "$BIN" >/dev/null 2>&1; then
  echo "install cpuminer-opt or set CPUMiner_BIN" >&2
  exit 1
fi
exec "$BIN" -a "$CA" -o "stratum+tcp://${HOST}:${PORT}" -u "$USER" -p "$PASS" "$@"
