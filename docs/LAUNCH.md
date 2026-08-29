# Quick launch console

Start **YarnRake**, optional **MagiMDM**, and mining workers from one place.

## Web console (checkboxes)

1. Build and run YarnRake:
   ```bash
   zig build && ./zig-out/bin/yarnrake
   ```
2. Open **http://127.0.0.1:8787/launch**
3. Tick options → **Copy command** → paste in a terminal

The page does **not** remote-exec miners (safer). It builds the matching `fleet_launch.sh` line.

## CLI (same options)

```bash
chmod +x tools/fleet_launch.sh

# Lab path: pool + onboard + lab stratum client
./tools/fleet_launch.sh --all-lab

# CPU RandomX (needs xmrig on PATH)
./tools/fleet_launch.sh --yarnrake --xmrig --algo randomx --worker office-pc

# DigiByte-style CPU (needs cpuminer-opt)
./tools/fleet_launch.sh --yarnrake --cpuminer --algo skein --worker dgb1

# With MagiMDM (local tree that builds)
export MAGIMDM_PATH=/path/to/MagiMDM
./tools/fleet_launch.sh --yarnrake --mdm --mock-agent --worker phone1

# Stop everything this script started
./tools/fleet_launch.sh --stop
```

## Checkbox → flag map

| Checkbox | Flag | Effect |
|----------|------|--------|
| YarnRake pool | `--yarnrake` | HTTP + stratum |
| MagiMDM console | `--mdm` | Needs `MAGIMDM_PATH` + built `zig-mdm` |
| Mock MDM agent | `--mock-agent` | Python poll/ack against MagiMDM |
| Lab stratum client | `--lab-client` | No external miner binary |
| XMRig | `--xmrig` | RandomX / GhostRider |
| cpuminer-opt | `--cpuminer` | Skein / Yescrypt / Scrypt… |
| lolMiner | `--lolminer` | GPU KawPow / Etchash… |
| Onboard worker | `--onboard` | Register worker on YarnRake |

## MagiMDM + mining policy

Mobile agents only mine when policy has:

```json
"mining": { "enabled": true, "algo": "skein", "stratum_url": "stratum+tcp://HOST:3333", "max_cpu_pct": 25 }
```

Parental / Work / Monitor templates keep **mining off** by default.

## Ports

| Service | Default |
|---------|---------|
| YarnRake HTTP | 8787 |
| YarnRake stratum | 3333 |
| MagiMDM HTTP | 8788 (when launched via script) |

## Cloud

For **Fly / Docker VPS / worker VMs**, see **[CLOUD.md](./CLOUD.md)**.

- Control plane: `docker compose up -d --build` or `fly deploy`
- Workers: separate VM + `tools/cloud_worker_setup.sh --xmrig`
