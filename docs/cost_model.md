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
caps account credit use at **8 credits/month** and acts as a circuit breaker:
NOTIFY at 75% (6 credits) / 90%, SUSPEND at 100%, SUSPEND_IMMEDIATE at 110%.
Sized at ~3x measured usage so the first alert is a real signal, not noise — a
runaway query loop is stopped long before it matters.

> Thresholds are set relative to **measured** usage, not guessed. An alert that
> only fires at many times the normal spend is not a safety net.

**Real usage so far (whole project, ~30 days):**

| Metric | Value |
|--------|-------|
| Snowflake credits consumed (30d) | **~2.3 credits** total (≈ a few USD) |
| `COMMODITY_RISK` storage | **~0.3 MB** |
| Dev clone `COMMODITY_RISK_DEV` extra storage | **~0** (zero-copy; shares micro-partitions) |
| Monthly credit cap (resource monitor) | 8 credits (SUSPENDs at 100%) |
| Azure monthly budget | 2 EUR (alerts only, at 50/80/100%) |

At X-Small (~1 credit/hour), 2.3 credits across a month means compute is
effectively free; storage at ~0.3 MB is a rounding error against Snowflake's
~$23-40/TB/month. The 20-credit cap is ~10x headroom over real use — purely a
safety net.

**Azure is now Pay-As-You-Go** (the free trial expired and was upgraded, keeping
the same subscription and resources). Real charges apply, but the footprint is
tiny: ADLS holds a few MB, ADF bills per pipeline run (a handful per day), Key
Vault operations are within the free allowance.

A **subscription budget** (`infra/subscription/`) notifies the Owner at
**50% / 80% / 100%** of a monthly cap. Note the difference from Snowflake:

| Guard | Behaviour |
|-------|-----------|
| Snowflake resource monitor | **suspends** the warehouse at 100% — a hard brake |
| Azure budget | **notifies only** — an early warning, not a cut-off |

So the actual brake on Azure is the habit of `terraform destroy` on `envs/dev`
between sessions. The budget exists to catch the case where that is forgotten.

## Teardown runbook

Goal: **zero standing cost** when idle. Do the Snowflake steps first (stop
compute), then Azure.

**Snowflake**

```sql
-- 1. Stop compute immediately.
ALTER WAREHOUSE WH_XS_ELT SUSPEND;

-- 2. Drop the dev clone (reclaims any diverged copy-on-write storage).
DROP DATABASE IF EXISTS COMMODITY_RISK_DEV;

-- 3. (Optional, full teardown) drop everything else. All of it is rebuildable
--    from snowflake/*.sql + dbt, so this is safe.
DROP DATABASE IF EXISTS COMMODITY_RISK;
DROP WAREHOUSE IF EXISTS WH_XS_ELT;
-- Roles, storage integration and the resource monitor can stay (they cost
-- nothing) or be dropped for a clean slate.
```

**Azure**

```bash
# Destroy per-environment resources (ADLS, ADF, Key Vault, resource group).
cd infra/envs/dev  && terraform destroy   # and infra/envs/prod if provisioned
```

> Leave `infra/subscription/` in place — the budget guard costs nothing and
> should outlive the environments. Verify in the Azure portal that no resource
> groups remain, then confirm the next invoice returns to ~0.

## Rebuild from scratch (reproducibility)

The whole platform is **reproducible from code**, so it can be rebuilt on a fresh
Azure/Snowflake trial after teardown:

1. **Azure infra** — `cd infra/envs/dev && terraform init && terraform apply`
   (creates ADLS, ADF, Key Vault, role assignments). Put API keys in Key Vault
   (`az keyvault secret set ...`); values never live in the repo.
2. **ADF** — deploy the exported ARM template
   ([ingestion/adf/](../ingestion/adf/)) and upload
   [sources.json](../ingestion/control/sources.json) to the `config` container
   (CI does this automatically on merge). Run the pipeline to land raw data.
3. **Snowflake** — run `snowflake/00`→`07` in order (databases/warehouse → RBAC →
   storage integration → bronze COPY → streams/tasks → zero-copy clone → resource
   monitor). Consent the storage integration on the Azure side when `02` prompts.
4. **dbt** — `dbt deps && dbt build` (CI runs this against the dev clone on PR and
   prod on merge).
5. **Power BI** — connect with `ROLE_ANALYST` (Import mode) to `MARTS` and refresh.

Because every layer is code, a rebuild is deterministic — the only manual inputs
are the API keys (into Key Vault) and the Snowflake storage-integration consent.
