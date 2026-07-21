-- Reusable FX analytics per (rate_date, currency_code): day-over-day returns,
-- moving averages and rolling volatility. Building block for the FX marts.
-- Materialized as a view (intermediate layer).

with rates as (

    select
        effective_date as rate_date,
        currency_code,
        currency_name,
        mid_rate
    from {{ ref('stg_nbp__fx_rates') }}

),

with_prev as (

    select
        *,
        lag(mid_rate) over (
            partition by currency_code
            order by rate_date
        ) as prev_mid_rate
    from rates

),

with_returns as (

    select
        *,
        mid_rate - prev_mid_rate                                as change_abs,
        mid_rate / nullif(prev_mid_rate, 0) - 1                 as daily_return
    from with_prev

)

select
    rate_date,
    currency_code,
    currency_name,
    mid_rate,
    prev_mid_rate,
    change_abs,
    daily_return,
    -- Rolling windows are per currency, ordered by date.
    avg(mid_rate) over (
        partition by currency_code order by rate_date
        rows between 6 preceding and current row
    ) as ma_7d,
    avg(mid_rate) over (
        partition by currency_code order by rate_date
        rows between 29 preceding and current row
    ) as ma_30d,
    -- Rolling volatility = standard deviation of daily returns (a risk measure).
    stddev(daily_return) over (
        partition by currency_code order by rate_date
        rows between 29 preceding and current row
    ) as volatility_30d
from with_returns
