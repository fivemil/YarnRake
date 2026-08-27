# MineBright → YarnRake

Source: https://github.com/5mil/MineBright

MineBright dispatched miners onto GitHub Actions, Colab, Kaggle, Replit, Render, Fly — pointed at mining-dutch.nl. That does not fit MagiMDM.

## Kept
- Stratum V1 client loop → `tools/stratum_client.py` (defaults: localhost YarnRake)
- Worker stats: shares, rejected, uptime, report interval
- Policy knobs: pool URL, algo, worker, duration_s, threads
- Algo alias `yescryptr16` → `yescrypt_r16`
- Dark status card on `GET /`

## Discarded
- CI / Colab / Kaggle / Replit / Fly dispatch
- cpuminer-opt on free tiers
- Default public pool mining-dutch.nl
- Supabase bench-relay and keys in config.js
- Browser PAT / Discord webhook UI
