# YarnRake algorithm & miner support

## Honest scope

| Layer | Status |
|-------|--------|
| **Registry** (`GET /algos`) | Full popular-algo catalog (CPU / GPU / ASIC) |
| **Stratum V1** | Accepts connections for any configured algo; job/notify + share format gates |
| **Native PoW validate** | Lab **SHA256d** only today; Skein / Yescrypt stubbed |
| **Integrated software** | Launcher scripts + catalog — **does not ship** proprietary miner binaries |

"All popular algorithms" means: **name, hardware class, coin hints, recommended miner, and stratum path**. Production-grade hash verification per coin is a multi-release roadmap (often needs C/ASM libraries or a full node).

## Algorithm matrix

| Algo | HW | Coins (examples) | Integrated miner | Validate |
|------|-----|------------------|------------------|----------|
| `sha256d` | ASIC | BTC, BCH | cgminer, cpuminer-opt | **native lab** |
| `scrypt` | ASIC | LTC, DOGE | cgminer, cpuminer-opt | external |
| `randomx` | CPU | XMR | **xmrig** | external |
| `randomx_wow` | CPU | WOW | xmrig | external |
| `ghostrider` | CPU | RTM | xmrig | external |
| `kawpow` | GPU | RVN | lolMiner, T-Rex, SRB | external |
| `etchash` | GPU | ETC | lolMiner, T-Rex | external |
| `ethash` | GPU | ETHW | lolMiner | external |
| `autolykos2` | GPU | ERG | lolMiner, T-Rex | external |
| `equihash` | GPU | ZEC, Flux | lolMiner, miniZ | external |
| `blake3` | GPU | ALPH | lolMiner, BzMiner | external |
| `octopus` | GPU | CFX | T-Rex | external |
| `fishhash` | GPU | IRON | lolMiner, SRB | external |
| `kheavyhash` | ASIC/GPU | KAS | SRB, cpuminer | external |
| `eaglesong` | ASIC | CKB | SRB | external |
| `x11` | ASIC | DASH | cpuminer-opt | external |
| `skein` | CPU | DGB | **cpuminer-opt** | stratum stub |
| `yescrypt_r16` | CPU | DGB | **cpuminer-opt** | stratum stub |
| `verthash` | GPU | VTC | VerthashMiner | external |
| `cuckatoo32` | GPU | GRIN | lolMiner | external |
| `neoscrypt` / `lyra2rev3` / `blake2b` / `blake2s` / `argon2d` | mixed | various | cpuminer-opt / SRB | external |

## Integrated mining software

Install or place binaries on `PATH`, then:

```bash
# one-time hints / download links
./tools/miners/setup.sh

# CPU RandomX
YARNRAKE_WORKER=pc1 YARNRAKE_ALGO=randomx ./tools/miners/run_xmrig.sh

# DigiByte-style CPU
YARNRAKE_WORKER=dgb1 YARNRAKE_ALGO=skein ./tools/miners/run_cpuminer.sh

# GPU KawPow
YARNRAKE_WORKER=gpu1 YARNRAKE_ALGO=kawpow ./tools/miners/run_lolminer.sh
```

Catalog JSON: `GET /miners`

## Multi-algo ports (optional)

Base stratum port `3333` + per-algo offset (see `Algo.portOffset`):

| Port | Typical algo |
|------|----------------|
| 3333 | default / sha256d |
| 3334 | scrypt |
| 3335 | randomx |
| 3336 | kawpow |
| 3337 | etchash/ethash |
| 3338 | autolykos2 |
| 3339 | kheavyhash |
| 3340 | skein / yescrypt |

Set `YARNRAKE_ALGO=randomx` on the server process for the primary listener; multi-listener expansion is on the roadmap.

## MagiMDM

Mobile agents only mine when policy has `mining.enabled: true`. Prefer **desktop/ASIC** for real hashrate; phones stay optional and throttled (`max_cpu_pct`).

## API

| Path | Returns |
|------|---------|
| `GET /algos` | Full algo list + hw + status + miner hint |
| `GET /miners` | Integrated software catalog |
| `GET /pool` | Live shares / sessions |
| `GET /onboard` | Register a local device |
