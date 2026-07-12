# Architecture

> Stub — expanded as the build progresses. High-level summary lives in
> [CLAUDE.md](../CLAUDE.md) §3.

## Data flow

```
8 public APIs
   → Azure Data Factory (metadata-driven: Lookup sources.json → ForEach → Copy)
   → ADLS Gen2 RAW zone   (land as-is; source=<id>/dataset=<ds>/ingest_date=YYYY-MM-DD/)
   → Snowflake BRONZE     (external stage + COPY INTO; VARIANT landing tables)
   → Snowflake            (Streams + Tasks → incremental load to working tables)
   → dbt Core             (staging → intermediate → marts)
   → Power BI             (read-only analyst role)
```

## Components

- **Azure Data Factory** — orchestration. One generic parameterized pipeline
  driven by `ingestion/control/sources.json`.
- **ADLS Gen2** — immutable raw landing zone, partitioned by source + date.
- **Azure Key Vault** — API keys; referenced by name, never stored in repo.
- **Snowflake** — external stage, bronze VARIANT tables, Streams+Tasks for
  incremental loads, RBAC (loader vs analyst), Time Travel, zero-copy clone.
- **dbt Core** — medallion transformation with tests and docs, run in CI.
- **Power BI** — three report pages: price risk, FX exposure, demand signals.

## Open design questions

- Reconciling mixed frequencies (daily / monthly / quarterly) via a calendar
  spine + last-known-value joins in the intermediate layer.
- Which single source gets the Snowpipe auto-ingest demo.

## Diagrams

See [diagrams/](diagrams/).
