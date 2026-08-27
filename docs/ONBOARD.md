# Onboard local mining devices

Register **any local miner class** with YarnRake so the pool knows who is expected to connect.

## Device types

| Type | Typical hardware | Typical software |
|------|------------------|------------------|
| `cpu` | Desktop / server CPU | xmrig, cpuminer-opt |
| `gpu` | NVIDIA / AMD cards | lolMiner, T-Rex, SRBMiner |
| `asic` | Antminer, Whatsminer, etc. | stock firmware / Braiins |
| `mobile` | Android under MagiMDM | agent (policy-gated only) |
| `hybrid` | CPU+GPU rig | mixed stack |
| `other` | FPGA / custom | custom |

## Web UI

1. Start YarnRake: `./zig-out/bin/yarnrake`
2. Open **http://127.0.0.1:8787/onboard**
3. Fill name, type, worker, algo, software → **Register**

## CLI

```bash
./tools/miners/onboard.sh --type cpu --name office-pc --worker pc1 --algo randomx --software xmrig
./tools/miners/onboard.sh --type gpu --name 3080-rig --worker gpu1 --algo kawpow --software lolMiner
./tools/miners/onboard.sh --type asic --name s19-basement --worker asic1 --algo sha256d --software stock
./tools/miners/onboard.sh --type mobile --name pixel-7 --worker phone1 --software magimdm-agent --platform android
```

## API

| Method | Path | |
|--------|------|--|
| `GET` | `/onboard` | HTML form |
| `POST` | `/onboard` | form or JSON fields |
| `GET` | `/devices` | registered devices JSON |
| `GET` | `/types` | type catalog |

POST fields: `name`, `type` (or `device_type`), `worker`, `algo`, `software`, `platform`.

Persistence: `devices.jsonl` (or `YARNRAKE_DEVICES`).

Schema: `mining_devices` in `sql/schema.sql`.

## After onboard

1. Point miner at `stratum+tcp://<host>:3333` with the **worker** name.
2. Or: `./tools/miners/setup.sh xmrig` then `YARNRAKE_WORKER=pc1 ./tools/miners/run_xmrig.sh`
3. MagiMDM mobiles still need `mining.enabled` in policy — registration alone does not mine.
