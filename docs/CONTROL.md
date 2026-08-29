# Miner control pool console

**URL:** `http://127.0.0.1:8787/control` (after `main.zig` is wired — see [CONTROL_WIRE.md](./CONTROL_WIRE.md))

Assign **any or all** registered pools to workers.

## Modes

| Mode | Behavior |
|------|----------|
| **manual** | Listed pool id(s) only |
| **automatic** | Enabled pools matching worker algo |
| **failover** | Ordered list / priority |
| **round_robin** | Rotate among selected pools |
| **all_pools** | Every enabled pool |
| **custom** | Free-form stratum URL |

Unassigned workers resolve as **automatic**.

## API

| Method | Path |
|--------|------|
| GET | `/control` |
| GET | `/control/state` |
| GET | `/control/resolve?worker=&algo=` |
| POST | `/control/pools` |
| POST | `/control/pools/enable` |
| POST | `/control/assign` |

Persistence: `control.tsv` (`YARNRAKE_CONTROL`).

Core board: `src/pool/control.zig`.
