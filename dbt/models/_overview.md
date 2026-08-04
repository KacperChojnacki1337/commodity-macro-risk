{% docs __overview__ %}

# Commodity & Macro Risk — dbt project

Transforms raw public-API data landed in Snowflake `BRONZE` into an analytics
layer for commodity price risk, FX exposure and demand signals.

## Medallion layers

- **staging** (`stg_`) — one model per source table: parse the raw JSON, type,
  rename, deduplicate. Materialized as **views**.
- **intermediate** (`int_`) — reusable business logic (FX returns, moving
  averages, rolling volatility). Views.
- **marts** (`fct_` / `dim_`) — the star schema consumed by Power BI, as
  **tables**. Facts join to conformed dimensions (`dim_date`, `dim_currency`).

## Sources modelled

- **NBP** — daily FX mid rates → `fct_fx_rates`, `fct_fx_cross_rates`
- **EIA** — WTI & Brent crude spot → `fct_commodity_prices`
- **ECB** — euro short-term rate (eSTR) → `fct_interest_rates`
- **Open-Meteo** — Warsaw daily weather → `fct_weather_daily`
- **Eurostat / GUS** — construction index + road length → `fct_construction_activity`
  (Eurostat also has an SCD2 `eurostat_civil_eng_snapshot`)
- All sources reconciled to a daily grain → `fct_daily_market_signals` (ASOF JOIN)

Explore the DAG (top-right graph icon) to see lineage from `source` through
staging and intermediate to the marts.

{% enddocs %}
