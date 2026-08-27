# YarnRake pool

Stratum V1 on :3333: subscribe → set_difficulty + mining.notify (placeholder job `yr-N`) → authorize → submit → shares.jsonl.

`GET /pool` includes subscribe/authorize/submit/sessions/miners/shares_total/rejected_total.

Lab: `python3 tools/stratum_client.py --user phone-1 --duration 20`

Hash validation still pending Magister vendor. Mining only if MagiMDM policy mining.enabled.
