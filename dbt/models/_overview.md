{% docs __overview__ %}

# Commodity & Macro Risk — dbt project

Transforms raw public-API data landed in Snowflake `BRONZE` into an analytics
layer for commodity price risk, FX exposure and (later) demand signals.

## Medallion layers

- **staging** (`stg_`) — one model per source table: parse the raw JSON, type,
  rename, deduplicate. Materialized as **views**.
- **intermediate** (`int_`) — reusable business logic (FX returns, moving
  averages, rolling volatility). Views.
- **marts** (`fct_` / `dim_`) — the star schema consumed by Power BI, as
  **tables**. Facts join to conformed dimensions (`dim_date`, `dim_currency`).

## Sources modelled so far

- **NBP** — daily FX mid rates → `fct_fx_rates`, `fct_fx_cross_rates`
- **EIA** — WTI crude oil spot price → `fct_commodity_prices`

Explore the DAG (top-right graph icon) to see lineage from `source` through
staging and intermediate to the marts.

{% enddocs %}
