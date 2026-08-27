#!/usr/bin/env bash
# Integrated mining software setup for YarnRake.
# Does not download large GPU/ASIC binaries by default (license + size).
# Prints install hints and verifies PATH.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
echo "YarnRake miner setup (repo: $ROOT)"
echo

need() {
  local bin="$1" url="$2"
  if command -v "$bin" >/dev/null 2>&1; then
    echo "  [ok] $bin -> $(command -v "$bin")"
  else
    echo "  [ ] $bin  not on PATH — $url"
  fi
}

echo "CPU"
need xmrig "https://github.com/xmrig/xmrig/releases"
need cpuminer-opt "https://github.com/JayDDee/cpuminer-opt"
need srbminer-multi "https://github.com/doktor83/SRBMiner-Multi"

echo "GPU"
need lolMiner "https://github.com/Lolliedieb/lolMiner-releases"
need t-rex "https://github.com/trexminer/T-Rex"
need bzminer "https://www.bzminer.com/"
need teamredminer "https://github.com/todxx/teamredminer"
need miniZ "https://miniz.ch/"

echo "ASIC / classic"
need cgminer "https://github.com/ckolivas/cgminer"

echo
echo "Lab client (no external miner):"
echo "  python3 $ROOT/tools/stratum_client.py --user lab1 --duration 30"
echo
echo "Run examples:"
echo "  YARNRAKE_WORKER=pc1 YARNRAKE_ALGO=randomx $ROOT/tools/miners/run_xmrig.sh"
echo "  YARNRAKE_WORKER=dgb1 YARNRAKE_ALGO=skein $ROOT/tools/miners/run_cpuminer.sh"
echo "  YARNRAKE_WORKER=gpu1 YARNRAKE_ALGO=kawpow $ROOT/tools/miners/run_lolminer.sh"
