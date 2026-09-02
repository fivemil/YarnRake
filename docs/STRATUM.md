# Stratum session

Live path in `src/pool/stratum.zig`:

1. Connect → `mining.set_difficulty`
2. `subscribe` → extra1 `yr01` + `job.notify` (`yr-N`); `Gate.setJob`
3. `authorize` → `store.touch(worker)`
4. `submit` `[worker, job_id, en2, ntime, nonce]`
   - not authorized / empty → `bad_format` reject
   - wrong job → `stale_job`
   - same job+nonce → `dup`
   - `sha256d` + `native_validate` → lab PoW or `bad_pow`
   - else accept (stub/external)
   - fail replies `{result:false, error:[21, reason, null]}`

Gate is per-session. Algo + start_diff come from server config (`YARNRAKE_ALGO`).
