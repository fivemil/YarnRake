# Miner control pool console

**URL:** http://127.0.0.1:8787/control

Assign **any or all** registered pools to workers, with operational modes.

## Modes

| Mode | Behavior |
|------|----------|
| **manual** | Use listed pool id(s) only |
| **automatic** | Enabled pools matching worker algo |
| **failover** | Ordered list (priority / list order) |
| **round_robin** | Rotate among selected pools |
| **all_pools** | Every enabled pool |
| **custom** | Free-form stratum URL (ignores registry) |

Unassigned workers resolve as **automatic**.

## API

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/control` | Console UI |
| GET | `/control/state` | Pools + assignments JSON |
| GET | `/control/resolve?worker=&algo=` | Effective URL list |
| POST | `/control/pools` | Add pool |
| POST | `/control/pools/enable` | Enable/disable |
| POST | `/control/assign` | Assign worker mode + pools |

Persistence: `control.tsv` (or `YARNRAKE_CONTROL`).
