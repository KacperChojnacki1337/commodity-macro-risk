# Commodity & Macro Risk Intelligence Platform

End-to-end data platform that ingests **real, public, regularly-updated** data
on commodity prices, FX rates, interest rates, and construction/weather demand
signals — lands it in Azure, models it in Snowflake with dbt, and surfaces
**commodity price risk**, **FX exposure**, and **demand signals** in Power BI.

Built as a portfolio project to demonstrate **Snowflake (SnowPro Core)** and
**Azure Data Factory** skills, in a domain that mirrors real hedging and
margin reporting in petroleum-products trading.

> **No synthetic data.** Every source is a real public API. See the source
> table below.

## Architecture

```
8 public APIs
   → Azure Data Factory (metadata-driven ingestion)
   → ADLS Gen2 (raw zone, partitioned by source + ingest_date)
   → Snowflake (bronze → Streams/Tasks → staging)
   → dbt Core (staging → intermediate → marts)
   → Power BI (commodity risk / FX exposure / demand signals)
```

Full write-up: [docs/architecture.md](docs/architecture.md) ·
Cost & teardown: [docs/cost_model.md](docs/cost_model.md) ·
Project charter: [CLAUDE.md](CLAUDE.md).

## Data sources

| Source | Data | Auth | Frequency |
|--------|------|------|-----------|
| NBP API | USD/PLN, EUR/PLN FX rates | none | daily |
| EIA API | crude / petroleum product prices | api key | daily/weekly |
| stooq.pl | WTI/Brent futures | none | daily |
| World Bank Pink Sheet | global commodity price indices | none | monthly |
| ECB SDW | Euribor / ECB policy rates | none | daily/monthly |
| GUS BDL | Polish construction/production | api key* | monthly/quarterly |
| Eurostat | EU construction output, PPI | none | monthly |
| Open-Meteo | weather (history + forecast) | none | daily |

## Tech stack

Azure Data Factory · ADLS Gen2 · Azure Key Vault · Snowflake · dbt Core ·
Terraform · GitHub Actions · Power BI.

## Repository layout

| Path | Purpose |
|------|---------|
| `infra/` | Terraform for Azure (ADLS, ADF, Key Vault) |
| `ingestion/` | Metadata-driven ingestion config + ADF definitions |
| `snowflake/` | Non-dbt DDL: databases, RBAC, stages, streams/tasks |
| `dbt/` | dbt Core project (medallion: staging → intermediate → marts) |
| `powerbi/` | Power BI report + notes |
| `docs/` | Architecture, cost model, data dictionary |

## Status

Early build. Progress is tracked as GitHub Issues on a project board.

## Cost

Designed to run on free tiers / trial credit (Azure, Snowflake, GitHub
Actions on a public repo). Every resource has a documented teardown path.
