# YarnRake

Self-hosted **optional mining pool** companion to [MagiMDM](https://github.com/5mil/MagiMDM), with a **multi-algorithm registry** and **integrated miner launchers**.

Repo: https://github.com/fivemil/YarnRake

## Algorithms

**20+ popular PoW names** registered (`GET /algos`): RandomX, KawPow, Etchash, Autolykos2, Equihash, SHA256d, Scrypt, X11, Skein, YescryptR16, GhostRider, kHeavyHash, Blake3, and more.

| Status | Meaning |
|--------|--------|
| `native_validate` | Zig checks lab PoW (`sha256d` today) |
| `stratum_stub` | Jobs + format/dup/stale (Skein / Yescrypt lineage) |
| `external` | Point **xmrig / cpuminer-opt / lolMiner** at this stratum |

Full table: [docs/ALGORITHMS.md](docs/ALGORITHMS.md)

## Integrated mining software

Launchers (binaries **not** bundled — install from upstream):

| Script | Software |
|--------|----------|
| `tools/miners/run_xmrig.sh` | [XMRig](https://github.com/xmrig/xmrig) — RandomX, GhostRider |
| `tools/miners/run_cpuminer.sh` | [cpuminer-opt](https://github.com/JayDDee/cpuminer-opt) — Skein, Yescrypt, Scrypt, … |
| `tools/miners/run_lolminer.sh` | [lolMiner](https://github.com/Lolliedieb/lolMiner-releases) — KawPow, Etchash, … |

Lab client: `python3 tools/stratum_client.py`

## Quick start

```bash
zig build
YARNRAKE_ALGO=randomx ./zig-out/bin/yarnrake
# http://127.0.0.1:8787/algos
# stratum+tcp://127.0.0.1:3333
```

| Env | Default |
|-----|--------|
| `YARNRAKE_ALGO` | `skein` |
| `YARNRAKE_STRATUM_PORT` | `3333` (`0` = off) |
| `PORT` | `8787` |

## MagiMDM

Mining stays **off** unless policy sets `mining.enabled`.
