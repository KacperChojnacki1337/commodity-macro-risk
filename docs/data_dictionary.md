# Data dictionary

> Stub — populated as dbt marts are built. Each mart's columns will be
> documented here and in dbt `schema.yml` (the source of truth).

## Marts (planned)

### price_risk
- `fct_commodity_prices` — commodity/product prices over time (EIA, stooq,
  World Bank).

### fx_exposure
- `fct_fx_rates` — daily FX rates (NBP): USD/PLN, EUR/PLN.

### demand_signals
- `fct_demand_signals` — construction activity (GUS, Eurostat) and weather
  (Open-Meteo) aligned on a calendar spine.

## Conventions

- Grain of every fact table is documented explicitly (to avoid fan-out when
  joining sources of different frequencies).
- Dates are stored as `DATE`; timestamps as `TIMESTAMP_NTZ` in UTC.
