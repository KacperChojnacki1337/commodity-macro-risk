# Data dictionary

Column-level docs live in the dbt `schema.yml` files (and the generated dbt docs
site) — those are the source of truth. This is the high-level map of the `MARTS`
layer.

## Dimensions (conformed)

- `dim_date` — calendar, one row per day; `date_key` (YYYYMMDD) joins every fact.
- `dim_currency` — one row per NBP-quoted currency; `is_major` flags the main ones.

## Facts

### fx_exposure
- `fct_fx_rates` — daily FX (NBP): mid rate, day-over-day change, 7/30-day moving
  averages, 30-day volatility. Grain: (rate_date, currency_code).
- `fct_fx_cross_rates` — each currency expressed in PLN / USD / EUR.
  Grain: (rate_date, currency_code).

### price_risk
- `fct_commodity_prices` — crude oil spot (EIA): WTI (`RWTC`) and Brent (`RBRTE`),
  USD/barrel, with day-over-day change. Grain: (price_date, series).

### macro_rates
- `fct_interest_rates` — ECB euro short-term rate (eSTR), percent.
  Grain: (rate_date, series_key).

### demand_signals
- `fct_weather_daily` — Warsaw daily weather (Open-Meteo) + heating-degree-days
  (heating-demand proxy). Grain: (weather_date, location).
- `fct_construction_activity` — tall fact: Eurostat civil-engineering index
  (monthly) + GUS expressway/motorway length (annual).
  Grain: (period_date, source_name, indicator).

### analytics
- `fct_daily_market_signals` — all sources reconciled onto one daily grain via
  `ASOF JOIN` (last-known-value). Grain: one row per day.

## History
- `eurostat_civil_eng_snapshot` (in `STAGING`) — SCD Type 2 history of the Eurostat
  index (a dbt snapshot): records revisions and withdrawals over time.

## Conventions

- Every fact's grain is documented explicitly (prevents fan-out across mixed
  frequencies).
- Dates are stored as `DATE`; timestamps as `TIMESTAMP_NTZ` in UTC.
- Column-level docs + tests: the dbt `schema.yml` files are authoritative.
