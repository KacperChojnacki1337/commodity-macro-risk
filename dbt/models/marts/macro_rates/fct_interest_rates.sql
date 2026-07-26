-- Daily interest rates (macro domain) with day-over-day change, for Power BI.
-- Grain: one row per (rate_date, series_key). ECB euro short-term rate now;
-- other rate series plug in here.

with rates as (

    select
        rate_key,
        rate_date,
        series_key,
        series_name,
        rate_pct
    from {{ ref('stg_ecb__estr') }}

),

with_change as (

    select
        *,
        lag(rate_pct) over (
            partition by series_key
            order by rate_date
        ) as prev_rate_pct
    from rates

)

select
    rate_key,
    to_number(to_char(rate_date, 'YYYYMMDD')) as date_key,   -- FK -> dim_date
    rate_date,
    series_key,
    series_name,
    rate_pct,
    prev_rate_pct,
    round(rate_pct - prev_rate_pct, 6) as change_bps_pt   -- change in percentage points
from with_change
