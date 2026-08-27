# Stratum session

1. Connect → set_difficulty
2. subscribe → extra1 yr01 + job.notify (`yr-N`); Gate.setJob(`yr-N`)
3. authorize → store.touch(worker)
4. submit params `[worker, job_id, en2, ntime, nonce]`
   - unauthorized / empty → reject bad_format
   - job_id ≠ current → reject stale_job
   - same job+nonce → reject dup
   - else accept (Magister hash still TODO)

`src/pool/validate.zig`
