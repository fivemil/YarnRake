# Cloud hosting — control plane + miner workers

See full guide in repo history; free limited workers: [FREE_WORKERS.md](./FREE_WORKERS.md).

## Control plane

```bash
docker compose up -d --build yarnrake
# or: fly deploy
```

## Workers

Paid/home hardware for real hashrate. Free tier = lab/smoke only:

```bash
./tools/free_workers/spin.sh --list
./tools/free_workers/spin.sh local-lab --duration 60
```
