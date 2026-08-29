# Free worker backends (realistic limits only)

YarnRake can **smoke-test** stratum and run **short lab workers** on free tiers.
It does **not** turn GitHub Actions / Colab / Kaggle into a mining farm (ToS + unstable).

## What “free worker” means here

| Allowed | Not allowed in this repo |
|---------|---------------------------|
| Lab stratum client (`stratum_client.py`) | Sustained PoW on CI minutes |
| Short jobs within documented caps | Abusing free GPU notebooks for crypto |
| Your own Always-Free VM if **ToS allows** | Default configs that hide ToS risk |

Each backend has a **max runtime** enforced by `tools/free_workers/spin.sh`.

## Backend matrix

| ID | What runs | Hard limit |
|----|-----------|------------|
| `local-lab` | Lab client on your machine | 3600s |
| `docker-lab` | Lab client container | 3600s |
| `compose-worker` | compose profile workers | until stopped |
| `fly-lab` | Fly one-shot lab | **600s** |
| `smoke-ci` | GH Actions connect test | **120s** |
| `oracle-hint` | Manual only | disabled in spin |

## Quick spin

```bash
export YARNRAKE_HOST=127.0.0.1
./tools/free_workers/spin.sh --list
./tools/free_workers/spin.sh local-lab --worker free-1 --duration 60
./tools/free_workers/spin.sh docker-lab --worker free-docker
```

Real hashrate → [CLOUD.md](./CLOUD.md), not free CI.
