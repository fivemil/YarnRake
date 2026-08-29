# YarnRake

Self-hosted **optional mining pool** companion to [MagiMDM](https://github.com/5mil/MagiMDM).

Repo: https://github.com/fivemil/YarnRake

## Quick start

```bash
zig build && ./zig-out/bin/yarnrake
# http://127.0.0.1:8787/launch
./tools/fleet_launch.sh --all-lab
```

## Free workers (lab / smoke — capped)

```bash
./tools/free_workers/spin.sh --list
./tools/free_workers/spin.sh local-lab --duration 60
./tools/free_workers/spin.sh docker-lab --worker free-1
```

| Backend | Max |
|---------|-----|
| local-lab / docker-lab | 3600s |
| fly-lab | 600s |
| smoke-ci (GitHub Actions) | **120s** connect test only |

Details: [docs/FREE_WORKERS.md](docs/FREE_WORKERS.md) · Cloud: [docs/CLOUD.md](docs/CLOUD.md) · Launch: [docs/LAUNCH.md](docs/LAUNCH.md)

**Not supported:** CI/Colab hash farms (ToS). Real hashrate → VPS/home GPU + [CLOUD.md](docs/CLOUD.md).
