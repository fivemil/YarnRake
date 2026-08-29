# Cloud hosting — control plane + miner workers

This guide covers **working** ways to host:

1. **Control plane** — YarnRake (HTTP + Stratum), optional MagiMDM
2. **Miner workers** — machines that point hashrate at your stratum

## Design rule

| Role | Where it should run | Why |
|------|---------------------|-----|
| Pool + MDM console | Always-on VPS / Fly / Docker host | Needs stable TCP, disk for shares |
| Hash workers | **Separate** VMs or your hardware | CPU/GPU load; often against free-tier ToS |

Do **not** use GitHub Actions, GitLab CI, Colab, or Kaggle as miners (ToS + unstable).

---

## A. Control plane (host the whole stack)

### Option 1 — Docker on any VPS (most robust)

Works on **Hetzner, DigitalOcean, Linode, Vultr**, home server, etc.

```bash
git clone https://github.com/fivemil/YarnRake.git
cd YarnRake
docker compose up -d --build yarnrake
# Console:  http://YOUR_IP:8787/launch
# Stratum:  stratum+tcp://YOUR_IP:3333
```

Firewall: allow 22, 8787/tcp, 3333/tcp.

### Option 2 — Fly.io

```bash
fly auth login
fly apps create yarnrake-pool
fly volumes create yr_data --size 1 --region iad
fly deploy
fly apps open
```

Config: `fly.toml`. Keep min_machines_running ≥ 1 for stratum if miners must stay connected.

### Option 3 — Render

Blueprint: `render.yaml`. Free web tier **sleeps** when idle → bad for live stratum. Prefer paid or VPS for production mining.

### MagiMDM beside YarnRake

| Service | Port |
|---------|------|
| YarnRake | 8787 HTTP, 3333 Stratum |
| MagiMDM | 8788 HTTP |

Policy mining block:

```json
"mining": {
  "enabled": true,
  "algo": "skein",
  "stratum_url": "stratum+tcp://pool.example.com:3333",
  "max_cpu_pct": 25
}
```

---

## B. Miner workers (cloud hashrate)

| Host | Fit |
|------|-----|
| Hetzner Cloud / Dedicated | Best $/hash for CPU — check fair-use |
| DO / Linode / Vultr | Read ToS — many ban crypto mining |
| Your PC / GPU / ASIC | Best for real hashrate |
| Fly / Render free | Poor for workers |

### Worker bootstrap

```bash
export YARNRAKE_HOST=pool.example.com
export YARNRAKE_WORKER=hetzner-1
export YARNRAKE_ALGO=randomx
./tools/cloud_worker_setup.sh --xmrig
# or:
xmrig -o stratum+tcp://pool.example.com:3333 -u hetzner-1 -p x -a rx/0 --donate-level=1
```

### Checklist

- [ ] `curl -s https://HOST/pool`
- [ ] `nc -vz HOST 3333`
- [ ] Persistent volume for shares
- [ ] Provider ToS allows worker workload
- [ ] MDM parental templates keep mining **off** unless intentional

See [LAUNCH.md](./LAUNCH.md), [POOL.md](./POOL.md).
