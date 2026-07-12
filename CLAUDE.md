# CLAUDE.md — Commodity & Macro Risk Intelligence Platform

> Project charter. Read this first in every session so the full context is
> available without re-explaining it. Keep it up to date as decisions change.

## 1. Purpose

Personal portfolio project demonstrating **Snowflake (SnowPro Core)** and
**Azure Data Factory** skills for Data Analyst / Data Engineer job
applications.

Domain intentionally mirrors the author's day job (hedging monitoring and
margin reporting at an asphalt / petroleum-products trading company):
commodity **price risk**, **FX exposure**, and **demand signals** driven by
weather and construction activity.

Secondary goal: **learning**. Explanations of concrete processes should be
detailed and step by step.

## 2. Hard Rules (non-negotiable)

1. **Real data only.** Every source is a public API serving real historical
   and current data. No synthetic / Faker / generated data, ever.
2. **English everywhere in the repo** — code, comments, filenames, commits,
   README, docs, GitHub issues. (Conversations with the author may be Polish.)
3. **Low-cost / zero-cost first.** Every architectural choice states its cost
   and how it is minimized. A **teardown** path exists for every paid resource.
4. **Walking skeleton before scale.** One source goes fully end-to-end before
   we scale metadata-driven to all eight (see §7).

## 3. Architecture (component → component)

```
8 public APIs
   → Azure Data Factory (metadata-driven: Lookup sources.json → ForEach → Copy)
   → ADLS Gen2 RAW zone   (land as-is, partitioned by source + ingest_date)
   → Snowflake BRONZE     (external stage + COPY INTO / Snowpipe demo; VARIANT)
   → Snowflake (Streams + Tasks incremental → working tables)
   → dbt Core medallion   (staging → intermediate → marts)  [SILVER → GOLD]
   → Power BI             (connects with read-only analyst role)
```

Detailed diagram and narrative: [docs/architecture.md](docs/architecture.md).

## 4. Data Sources

| id         | source              | data                              | auth     | frequency        | cost |
|------------|---------------------|-----------------------------------|----------|------------------|------|
| nbp        | NBP API             | USD/PLN, EUR/PLN FX rates         | none     | daily            | free |
| eia        | EIA API             | crude / petroleum product prices  | api_key  | daily / weekly   | free |
| stooq      | stooq.pl            | WTI/Brent futures (CSV)           | none     | daily            | free |
| worldbank  | World Bank Pink Sheet | global commodity price indices  | none     | monthly          | free |
| ecb        | ECB SDW             | Euribor / ECB policy rates        | none     | daily / monthly  | free |
| gus        | GUS BDL API         | PL construction / production      | api_key* | monthly / quarterly | free |
| eurostat   | Eurostat API        | EU construction output, PPI       | none     | monthly          | free |
| openmeteo  | Open-Meteo          | weather (history + forecast, PL)  | none     | daily            | free |

\* GUS BDL works without a key at low rates; a free key raises limits.
Futures use **stooq.pl** (stable CSV), not Yahoo Finance (no official API).

## 5. Naming Conventions

- **Snowflake:** database `COMMODITY_RISK`; schemas `BRONZE` / `STAGING` /
  `MARTS`; roles `ROLE_LOADER` (write) and `ROLE_ANALYST` (read-only);
  warehouse `WH_XS_ELT` (X-Small).
- **dbt models:** `stg_<source>__<entity>`, `int_<concept>`,
  `fct_<entity>` / `dim_<entity>`.
- **ADLS paths:** `raw/source=<id>/dataset=<ds>/ingest_date=YYYY-MM-DD/`.
- **Git:** Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`);
  branches `feat/...`, `fix/...`, `chore/...`. Work on branches, PR into `main`.

## 6. Environments & CI/CD

- **dev vs prod** = separate Snowflake schemas (not separate accounts);
  dev may be a **zero-copy clone** of prod.
- **GitHub Actions:** on PR → `dbt build` against the **dev** target +
  `terraform plan`; on merge to `main` → `dbt run` against **prod**.
- **dbt** runs as **dbt Core** inside GitHub Actions (no dbt Cloud).

## 7. Build Order (milestones)

Walking skeleton first: **NBP** goes fully end-to-end before anything else,
because it is keyless, simple JSON, daily, and directly relevant (FX exposure).

- **M0** Foundations — repo, CLAUDE.md, Terraform skeleton, CI skeleton.
- **M1** Vertical slice (NBP) — ADF → ADLS → Snowflake → dbt → Power BI.
- **M2** Snowflake maturity — RBAC, Streams+Tasks, zero-copy clone, cost notes.
- **M3** dbt medallion + EIA (API-key pattern).
- **M4** Scale metadata-driven to the remaining sources.
- **M5** Power BI dashboard + ops, teardown, docs.

Tracked as GitHub Issues on a GitHub Project board.

## 8. Ingestion Pattern (metadata-driven)

One generic ADF pipeline reads [ingestion/control/sources.json](ingestion/control/sources.json)
via a Lookup activity, then a ForEach iterates enabled sources and calls a
parameterized child pipeline. Adding a source = a JSON entry, not a new
pipeline. Snowflake load: external stage + scheduled `COPY` via Task as the
main pattern; **Snowpipe auto-ingest demoed on one source only**.

## 9. Secrets

API keys live **only in Azure Key Vault**, referenced by name in
`sources.json` and by ADF/Snowflake at runtime. Never commit secrets;
`.gitignore` blocks `*.env`, `*.tfvars`, `profiles.yml`, `*.key`, `*.pem`.
GitHub Actions uses repository secrets.

## 10. Cost & Teardown

Full model: [docs/cost_model.md](docs/cost_model.md). Principles: X-Small
warehouse with aggressive auto-suspend + a Snowflake resource monitor; daily
(not real-time) refresh; ADLS lifecycle rules; `terraform destroy` when idle.
Snowflake and Azure both run on free trial credit — the project must be
**fully reproducible from code** so it can be rebuilt on a fresh trial.

## 11. Status

See GitHub Issues / Project board for current milestone and open work.
