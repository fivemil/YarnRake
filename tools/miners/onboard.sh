#!/usr/bin/env bash
# Onboard CPU / GPU / ASIC / mobile — MagiMDM-style registration
set -euo pipefail
HOST="${YARNRAKE_HOST:-127.0.0.1}"
PORT="${YARNRAKE_PORT:-8787}"
NAME="" TYPE="cpu" WORKER="" ALGO="" SOFTWARE="" PLATFORM=""
VENDOR="" MODEL="" HASHRATE="" NOTES="" PRESET="" TOKEN="" CLAIM=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --worker) WORKER="$2"; shift 2 ;;
    --algo) ALGO="$2"; shift 2 ;;
    --software) SOFTWARE="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --vendor) VENDOR="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --hashrate) HASHRATE="$2"; shift 2 ;;
    --notes) NOTES="$2"; shift 2 ;;
    --preset) PRESET="$2"; shift 2 ;;
    --claim) TOKEN="$2"; CLAIM=1; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    -h|--help) echo "onboard.sh --preset s19|l7|3080|4090|xmrig-cpu|mobile | --type gpu --name ..."; exit 0 ;;
    *) echo "unknown $1"; exit 1 ;;
  esac
done
case "$PRESET" in
  s19) TYPE=asic; NAME="${NAME:-Antminer-S19}"; WORKER="${WORKER:-asic-s19}"; ALGO="${ALGO:-sha256d}"; SOFTWARE="${SOFTWARE:-stock}"; VENDOR="${VENDOR:-Bitmain}"; MODEL="${MODEL:-S19}"; PLATFORM=firmware; HASHRATE="${HASHRATE:-95 TH/s}" ;;
  l7) TYPE=asic; NAME="${NAME:-Antminer-L7}"; WORKER="${WORKER:-asic-l7}"; ALGO="${ALGO:-scrypt}"; SOFTWARE="${SOFTWARE:-stock}"; VENDOR="${VENDOR:-Bitmain}"; MODEL="${MODEL:-L7}"; PLATFORM=firmware; HASHRATE="${HASHRATE:-9 GH/s}" ;;
  3080) TYPE=gpu; NAME="${NAME:-RTX-3080}"; WORKER="${WORKER:-gpu-3080}"; ALGO="${ALGO:-kawpow}"; SOFTWARE="${SOFTWARE:-lolMiner}"; VENDOR=NVIDIA; MODEL="RTX 3080"; PLATFORM=linux; HASHRATE="${HASHRATE:-48 MH/s}" ;;
  4090) TYPE=gpu; NAME="${NAME:-RTX-4090}"; WORKER="${WORKER:-gpu-4090}"; ALGO="${ALGO:-kawpow}"; SOFTWARE="${SOFTWARE:-lolMiner}"; VENDOR=NVIDIA; MODEL="RTX 4090"; PLATFORM=linux; HASHRATE="${HASHRATE:-50 MH/s}" ;;
  xmrig-cpu) TYPE=cpu; NAME="${NAME:-CPU-xmrig}"; WORKER="${WORKER:-cpu-1}"; ALGO="${ALGO:-randomx}"; SOFTWARE=xmrig; PLATFORM=linux ;;
  mobile) TYPE=mobile; NAME="${NAME:-Android-agent}"; WORKER="${WORKER:-phone-1}"; SOFTWARE=magimdm-agent; PLATFORM=android ;;
esac
[[ -n "$NAME" ]] || { echo "need --name or --preset"; exit 1; }
[[ -n "$WORKER" ]] || WORKER="$NAME"
[[ -n "$PLATFORM" ]] || case "$TYPE" in asic) PLATFORM=firmware ;; mobile) PLATFORM=android ;; *) PLATFORM=linux ;; esac
if [[ "$CLAIM" -eq 1 ]]; then
  curl -sS -X POST "http://${HOST}:${PORT}/api/device/enroll" -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "token=$TOKEN" --data-urlencode "name=$NAME" --data-urlencode "worker=$WORKER" \
    --data-urlencode "type=$TYPE" --data-urlencode "algo=$ALGO" --data-urlencode "software=$SOFTWARE" \
    --data-urlencode "platform=$PLATFORM" --data-urlencode "vendor=$VENDOR" --data-urlencode "model=$MODEL" \
    --data-urlencode "hashrate=$HASHRATE"; echo; exit 0
fi
curl -sS -X POST "http://${HOST}:${PORT}/onboard" -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "name=$NAME" --data-urlencode "type=$TYPE" --data-urlencode "worker=$WORKER" \
  --data-urlencode "algo=$ALGO" --data-urlencode "software=$SOFTWARE" --data-urlencode "platform=$PLATFORM" \
  --data-urlencode "vendor=$VENDOR" --data-urlencode "model=$MODEL" --data-urlencode "hashrate=$HASHRATE" \
  --data-urlencode "notes=$NOTES"; echo
