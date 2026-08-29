# YarnRake

Self-hosted **optional mining pool** companion to [MagiMDM](https://github.com/5mil/MagiMDM), with a **multi-algorithm registry** and **integrated miner launchers**.

Repo: https://github.com/fivemil/YarnRake

## Algorithms

**20+ popular PoW names** registered (`GET /algos`): RandomX, KawPow, Etchash, Autolykos2, Equihash, SHA256d, Scrypt, X11, Skein, YescryptR16, GhostRider, kHeavyHash, Blake3, and more.

Full table: [docs/ALGORITHMS.md](docs/ALGORITHMS.md)

## Integrated mining software

| Script | Software |
|--------|----------|
| `tools/miners/run_xmrig.sh` | XMRig — RandomX, GhostRider |
| `tools/miners/run_cpuminer.sh` | cpuminer-opt — Skein, Yescrypt, Scrypt, … |
| `tools/miners/run_lolminer.sh` | lolMiner — KawPow, Etchash, … |

## Quick launch console

```bash
zig build && ./zig-out/bin/yarnrake
# open http://127.0.0.1:8787/launch  — checkboxes → copy command
./tools/fleet_launch.sh --all-lab
```

Full flags: [docs/LAUNCH.md](docs/LAUNCH.md) · Cloud: [docs/CLOUD.md](docs/CLOUD.md)

## Quick start

```bash
zig build
YARNRAKE_ALGO=randomx ./zig-out/bin/yarnrake
# http://127.0.0.1:8787/launch
# stratum+tcp://127.0.0.1:3333
```

## Cloud (control plane + workers)

```bash
# VPS / home server
docker compose up -d --build yarnrake

# Fly.io
fly deploy

# Worker VM → your pool
export YARNRAKE_HOST=your.pool.ip
./tools/cloud_worker_setup.sh --xmrig
```

Details: [docs/CLOUD.md](docs/CLOUD.md)
