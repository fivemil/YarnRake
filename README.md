# YarnRake

Self-hosted mining pool companion to [MagiMDM](https://github.com/5mil/MagiMDM).

## Quick start

```bash
zig build && ./zig-out/bin/yarnrake
./tools/fleet_launch.sh --all-lab
# http://127.0.0.1:8787/launch
```

## Home workers (LAN)

```bash
export YARNRAKE_HOST=192.168.1.50   # pool PC on your LAN
./tools/home_workers/setup.sh --check
./tools/home_workers/setup.sh --xmrig --run
./tools/home_workers/run_home.sh --xmrig --worker desk-pc
```

Guide: [docs/HOME_WORKERS.md](docs/HOME_WORKERS.md)

## Docs

| Doc | Topic |
|-----|--------|
| [HOME_WORKERS.md](docs/HOME_WORKERS.md) | LAN CPUs/GPUs/ASICs |
| [LAUNCH.md](docs/LAUNCH.md) | Fleet launch console |
| [CONTROL.md](docs/CONTROL.md) | Pool ↔ worker assignment |
| [CLOUD.md](docs/CLOUD.md) | VPS control plane |
| [FREE_WORKERS.md](docs/FREE_WORKERS.md) | Capped lab/smoke only |
| [ALGORITHMS.md](docs/ALGORITHMS.md) | Algo registry |
