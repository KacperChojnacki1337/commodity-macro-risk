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

## Cost controls (measured)

**Warehouse `WH_XS_ELT`** — X-Small (the smallest tier, ~1 credit/hour) with
`AUTO_SUSPEND = 60s` and `AUTO_RESUME`. You pay only for seconds of real query
time; nothing while idle.

**Resource monitor `rm_commodity_risk`** (`snowflake/07_resource_monitor.sql`)
caps account credit use at **20 credits/month** and acts as a circuit breaker:
NOTIFY at 75% / 90%, SUSPEND at 100%, SUSPEND_IMMEDIATE at 110%. A runaway query
loop therefore cannot burn the trial budget.

**Real usage so far (whole project, ~30 days):**

| Metric | Value |
|--------|-------|
| Snowflake credits consumed (30d) | **~2.3 credits** total (≈ a few USD) |
| `COMMODITY_RISK` storage | **~0.3 MB** |
| Dev clone `COMMODITY_RISK_DEV` extra storage | **~0** (zero-copy; shares micro-partitions) |
| Monthly credit cap (resource monitor) | 20 credits |

At X-Small (~1 credit/hour), 2.3 credits across a month means compute is
effectively free; storage at ~0.3 MB is a rounding error against Snowflake's
~$23-40/TB/month. The 20-credit cap is ~10x headroom over real use — purely a
safety net.

_Azure trial has expired (subscription read-only, zero cost); Azure resources
are being decommissioned automatically. Rebuild from Terraform on a fresh trial._

## Teardown runbook

1. `cd infra/envs/dev && terraform destroy` (and `prod` if provisioned).
2. In Snowflake: suspend/drop the warehouse; optionally drop the database.
3. Confirm no lingering Azure resource groups incur cost.
4. In Snowflake, `DROP DATABASE COMMODITY_RISK_DEV` (the clone) when idle; the
   resource monitor keeps compute capped regardless.
