-- Daily NBP FX rates with day-over-day movement, ready for Power BI.
-- Grain: one row per (rate_date, currency_code). Materialized as a table
-- (marts default) so the dashboard reads it fast.

with rates as (

    select
        effective_date as rate_date,
        currency_code,
        currency_name,
        mid_rate
    from {{ ref('stg_nbp__fx_rates') }}

),

with_change as (

    select
        rate_date,
        currency_code,
        currency_name,
        mid_rate,
        lag(mid_rate) over (
            partition by currency_code
            order by rate_date
        ) as prev_mid_rate
    from rates

),

final as (

    select
        md5(to_varchar(rate_date) || '|' || currency_code) as fx_rate_key,
        rate_date,
        currency_code,
        currency_name,
        mid_rate,
        prev_mid_rate,
        mid_rate - prev_mid_rate                                      as change_abs,
        round((mid_rate / nullif(prev_mid_rate, 0) - 1) * 100, 4)     as change_pct
    from with_change

)

select * from final
