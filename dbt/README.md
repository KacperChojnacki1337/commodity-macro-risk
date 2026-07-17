# dbt project — commodity_risk

Transforms the raw data landed in Snowflake `BRONZE` into the medallion layers:
**staging → intermediate → marts**. dbt Core, run locally and in CI (no dbt Cloud).

## Layout

| Path | Purpose |
|------|---------|
| `models/staging/` | 1:1 with sources — parse JSON, type, rename, dedupe. Materialized as **views**. |
| `models/intermediate/` | Cross-source logic, frequency/currency alignment. Views. |
| `models/marts/` | GOLD facts/dims for Power BI. Materialized as **tables**. |
| `macros/generate_schema_name.sql` | Override so models land in the exact schemas `STAGING` / `MARTS` (no target prefix). |

Schema/materialization defaults live in `dbt_project.yml`.

## Setup

Use a virtualenv so this project's `dbt-snowflake` doesn't clash with other
dbt projects (e.g. a BigQuery one) on the machine:

```bash
python -m venv .venv                      # from the repo root
.venv/Scripts/python -m pip install dbt-snowflake   # Windows
# .venv/bin/python -m pip install dbt-snowflake     # macOS/Linux
```

Copy the credential-free profile template and supply values via environment
variables — **never commit credentials**:

```bash
cd dbt
cp profiles.example.yml profiles.yml      # profiles.yml is gitignored
```

| Variable | Example / default |
|----------|-------------------|
| `SNOWFLAKE_ACCOUNT` | `MYORG-AB12345` |
| `SNOWFLAKE_USER` | your Snowflake login |
| `SNOWFLAKE_PASSWORD` | secret — env var only |
| `SNOWFLAKE_ROLE` | `ACCOUNTADMIN` (until `ROLE_LOADER` exists, #10) |
| `SNOWFLAKE_WAREHOUSE` | `WH_XS_ELT` |
| `SNOWFLAKE_DATABASE` | `COMMODITY_RISK` |

## Run

```bash
cd dbt
dbt debug --profiles-dir .    # check the connection
dbt build --profiles-dir .    # run models + tests
dbt docs generate --profiles-dir . && dbt docs serve --profiles-dir .
```

## Models

| Model | Grain | Notes |
|-------|-------|-------|
| `stg_nbp__fx_rates` | one row per (`effective_date`, `currency_code`) | Flattens the raw NBP Table A JSON, types `mid_rate` as `number(18,6)` (decimal, not float — FX/money), dedupes by latest `_loaded_at`. |

## CI

`.github/workflows/dbt-ci.yml` runs `dbt build` against the **dev** target on PRs
touching `dbt/**`, using GitHub Actions secrets. It skips cleanly when the
Snowflake secrets are not configured, so the repo stays green without a live
warehouse.
