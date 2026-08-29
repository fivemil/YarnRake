# Onboard mining devices (MDM-style)

Register **CPU, GPU, ASIC, mobile, hybrid** like MagiMDM registers phones: admin form or one-time token, inventory fields, list at `/devices`.

## Types

| Type | Hardware | Software examples |
|------|----------|-------------------|
| cpu | Desktop/server | xmrig, cpuminer-opt |
| gpu | NVIDIA/AMD | lolMiner, T-Rex |
| asic | Antminer, Whatsminer | stock firmware |
| mobile | Android | MagiMDM agent |
| hybrid | CPU+GPU rig | mixed |

## Web

http://127.0.0.1:8787/onboard — presets for S19, L7, 3080, 4090, CPU, mobile.

## CLI

```bash
./tools/miners/onboard.sh --preset s19
./tools/miners/onboard.sh --preset 4090 --name living-4090
./tools/miners/onboard.sh --type gpu --name 3080-rig --worker gpu1 \
  --algo kawpow --software lolMiner --vendor NVIDIA --model "RTX 3080" --hashrate "48 MH/s"
```

## Token claim

```bash
curl -s -X POST http://127.0.0.1:8787/onboard/token -d 'type=asic&label=garage'
./tools/miners/onboard.sh --claim TOKEN --name S19-a --worker asic-a --preset s19
```

## API

| Method | Path |
|--------|------|
| POST | `/onboard` |
| POST | `/onboard/token` |
| GET | `/onboard/tokens` |
| POST | `/api/device/enroll` |
| GET | `/devices` |

After onboard: point miner/firmware at `stratum+tcp://POOL:3333` with the registered **worker** name. Home: [HOME_WORKERS.md](./HOME_WORKERS.md).
