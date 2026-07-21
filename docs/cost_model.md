# Cost model & teardown

> Goal: run the whole platform on free tiers / trial credit, and be able to
> tear everything down to **zero standing cost** when not actively working.

## Per-component cost

| Component | Cost when active | How we minimize | Teardown |
|-----------|------------------|-----------------|----------|
| Azure Data Factory | ~$0 idle; small per-activity-run + orchestration hours | daily (not real-time) runs; one generic pipeline; free trial | `terraform destroy` |
| ADLS Gen2 | cents/month (small volumes) | cool tier + lifecycle rules | `terraform destroy` |
| Azure Key Vault | ~$0 (10k ops free) | negligible | `terraform destroy` |
| Snowflake | trial credit (30 days) | `WH_XS_ELT` X-Small, auto-suspend ≤60s, resource monitor cap | suspend / drop warehouse; DB rebuildable from code |
| GitHub Actions | $0 (public repo) | keep repo public | n/a |
| Power BI | Desktop is free | stay on Desktop; publish screenshots to `docs/`, don't require Pro/Fabric | n/a |

## Principles

1. **Daily, not real-time.** No streaming unless a source truly needs it.
2. **Smallest warehouse + aggressive auto-suspend.** X-Small, suspend after
   ≤60s idle, plus a Snowflake resource monitor to cap credits.
3. **Reproducible from code.** Snowflake DDL + dbt + Terraform mean the whole
   thing can be rebuilt on a fresh trial after teardown.

## Zero-copy clone (dev environment) — near-zero storage

`COMMODITY_RISK_DEV` is a **zero-copy clone** of prod (`snowflake/06_zero_copy_clone.sql`).

- **Creation is instant and copies no data** — the clone is metadata pointing at
  the same immutable micro-partitions as prod (a whole database cloned in ~5s).
- **Storage cost starts at ~0** and grows only by **copy-on-write**: when dev
  data diverges from prod, only the changed micro-partitions consume new
  storage. Unchanged data stays shared.
- **Refresh flow:** re-run `06_zero_copy_clone.sql`. `CREATE OR REPLACE DATABASE
  ... CLONE` drops the drifted clone and makes a fresh one from current prod —
  again instant, reclaiming any diverged storage.
- **Cost control:** don't let the dev clone drift far from prod; re-clone
  instead of accumulating changes. Drop it entirely when idle
  (`DROP DATABASE COMMODITY_RISK_DEV`).

> Note: cloning requires the clone's grants to be re-applied (clones do not
> inherit the source's privileges) — the script handles this.

## Teardown runbook

1. `cd infra/envs/dev && terraform destroy` (and `prod` if provisioned).
2. In Snowflake: suspend/drop the warehouse; optionally drop the database.
3. Confirm no lingering Azure resource groups incur cost.

_To be expanded with real numbers once resources are provisioned (M1)._
