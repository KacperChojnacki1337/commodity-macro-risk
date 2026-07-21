-- Daily FX fact for Power BI: mid rate + day-over-day movement + moving averages
-- + rolling volatility, with foreign keys to dim_date and dim_currency.
-- Grain: one row per (rate_date, currency_code). Materialized as a table.

with enriched as (

    select * from {{ ref('int_fx_returns') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['rate_date', 'currency_code']) }} as fx_rate_key,
    to_number(to_char(rate_date, 'YYYYMMDD')) as date_key,       -- FK -> dim_date
    currency_code,                                                -- FK -> dim_currency
    rate_date,
    mid_rate,
    prev_mid_rate,
    change_abs,
    round(daily_return * 100, 4) as daily_change_pct,
    round(ma_7d, 6)             as ma_7d,
    round(ma_30d, 6)            as ma_30d,
    round(volatility_30d, 8)    as volatility_30d
from enriched
