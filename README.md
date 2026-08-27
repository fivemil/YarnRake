# YarnRake

Self-hosted **device management** plus an **optional mining pool**.

Repo: https://github.com/fivemil/YarnRake  
Sibling MDM source: https://github.com/5mil/MagiMDM  
Pool lineage: [5mil/magister](https://github.com/5mil/magister) Stratum V1 (Zig)

## What stayed from the old YarnRake

| Keep | Why |
|------|-----|
| Repo + name | Org write target |
| **Skein-512** | DigiByte algo YarnRake advertised |
| **YescryptR16** | Second DigiByte algo YarnRake advertised |
| Small-fleet / self-host | Same scale as MagiMDM (1-10 devices) |

## What was discarded

| Drop | Why |
|------|-----|
| SARN | Slogan only — no code |
| Rake integration wrapper | Empty |
| CI/Colab free-hash benches | Not for managed phones |

See [docs/ARCHIVE.md](docs/ARCHIVE.md).

Mining is a **policy flag**, off by default. Only on devices you own.

## Quick start

```bash
zig test src/pool.zig
zig build
./zig-out/bin/yarnrake
```

| Variable | Default |
|----------|--------|
| `YARNRAKE_PORT` / `PORT` | 8787 |
| `YARNRAKE_STRATUM_PORT` | 3333 |
| `YARNRAKE_ALGO` | skein |

Docs: [POOL](docs/POOL.md) · [TEMPLATES](docs/TEMPLATES.md) · MagiMDM: https://github.com/5mil/MagiMDM
