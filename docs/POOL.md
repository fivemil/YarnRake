# YarnRake pool + MagiMDM

Agent mines only if policy mining.enabled is true.

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

Parental/default templates leave enabled false.

Stratum V1: subscribe, authorize, submit, set_difficulty.
Chain validation stays in Magister until vendored.
