# YarnRake algorithms & integrated miners

YarnRake is a **multi-algo stratum front-end**, not a full replacement for every coin daemon.

| Layer | What it does |
|-------|----------------|
| **Registry** | `GET /algos` — popular PoW names, hardware class, recommended miner |
| **Stratum** | One active algo per process (`YARNRAKE_ALGO`) on `:3333` |
| **Validation** | Always: job id + nonce format, stale, dup. **Native PoW:** `sha256d` lab only |
| **Integrated software** | Shell launchers under `tools/miners/` for xmrig / cpuminer-opt / lolMiner |

## Popular algorithms (registry)

| Id | Hardware | Status | Typical coins | Integrated miner |
|----|----------|--------|---------------|------------------|
| `skein` | CPU | stratum_stub | DigiByte | cpuminer-opt |
| `yescrypt_r16` | CPU | stratum_stub | DigiByte | cpuminer-opt |
| `randomx` | CPU | external | Monero | **xmrig** |
| `ghostrider` | CPU | external | Raptoreum | xmrig |
| `argon2d` | CPU | external | various | cpuminer-opt |
| `kawpow` | GPU | external | Ravencoin | lolMiner / T-Rex |
| `etchash` | GPU | external | Ethereum Classic | lolMiner |
| `ethash` | GPU | external | ETH forks | lolMiner |
| `autolykos2` | GPU | external | Ergo | lolMiner / SRBMiner |
| `equihash` | GPU/ASIC | external | Zcash | lolMiner / miniZ |
| `verthash` | GPU | external | Vertcoin | verthashminer |
| `blake3` | GPU | external | Alephium / Decred | lolMiner |
| `octopus` | GPU | external | Conflux | T-Rex |
| `sha256d` | ASIC | **native_validate** (lab) | Bitcoin | cpuminer-opt |
| `scrypt` | ASIC | external | Litecoin / DOGE | cpuminer-opt |
| `x11` | ASIC | external | Dash | cpuminer-opt |
| `kheavyhash` | ASIC | external | Kaspa | SRBMiner |
| `neoscrypt` | GPU | external | Feathercoin etc. | cpuminer-opt |
| `lyra2rev3` | GPU | external | legacy VTC | cpuminer-opt |
| `blake2b` / `blake2s` | mixed | external | Sia / Kadena | cpuminer-opt |

`stratum_stub` / `external` = pool accepts well-formed shares after authorize; **does not** prove chain work until a real hash module is wired (Magister or coin daemon).

## Run

```bash
YARNRAKE_ALGO=skein zig-out/bin/yarnrake
YARNRAKE_ALGO=sha256d zig-out/bin/yarnrake
YARNRAKE_ALGO=randomx zig-out/bin/yarnrake
```

```bash
./tools/miners/run_xmrig.sh
./tools/miners/run_cpuminer.sh
YARNRAKE_ALGO=kawpow ./tools/miners/run_lolminer.sh
```

```bash
curl -s http://127.0.0.1:8787/algos | jq .
curl -s http://127.0.0.1:8787/pool  | jq .
```

## MagiMDM policy

```json
"mining": {
  "enabled": false,
  "algo": "randomx",
  "stratum_url": "stratum+tcp://pool.example:3333",
  "max_cpu_pct": 25
}
```

## Honest limits

- Not embedding XMRig/lolMiner binaries in the Zig binary (license + size).
- Not validating RandomX/KawPow in pure Zig in this tree yet.
- Multi-coin payouts still need a wallet/daemon or Magister vault.
- ASIC farms are out of scope for a 1–10 device MDM companion.
