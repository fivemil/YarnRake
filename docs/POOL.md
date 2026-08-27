# YarnRake pool + MagiMDM

Agent mines only if policy `mining.enabled` is true.
MagiMDM: https://github.com/5mil/MagiMDM (`MiningController.kt`).

```json
{
  "schema": 1,
  "template": "work",
  "mining": {
    "enabled": false,
    "algo": "skein",
    "stratum_url": "stratum+tcp://127.0.0.1:3333",
    "worker": "device-uuid",
    "max_cpu_pct": 25,
    "schedule": "02:00-06:00"
  }
}
```

When enabled is false or missing, the agent clears `mining_enabled` prefs and will not point at stratum.
Parental/default templates leave enabled false.

Stratum V1 here: subscribe, authorize, submit → `shares.jsonl`.
Chain validation still belongs in Magister until vendored.
