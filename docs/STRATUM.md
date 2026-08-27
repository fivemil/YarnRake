# Stratum session

1. Connect → `mining.set_difficulty`
2. `mining.subscribe` → extra1 `yr01` + `job.notify(n)` (`yr-n` placeholder header)
3. `mining.authorize` → store.touch(worker)
4. `mining.submit`
   - authorized → `store.accept`
   - no worker yet → `store.reject` (worker `anon`)

`src/pool/stratum.zig` handleLine uses `@import("job.zig").notify`.
