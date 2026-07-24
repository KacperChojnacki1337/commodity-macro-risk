-- Daily commodity spot prices with day-over-day movement, for Power BI.
-- Grain: one row per (price_date, series). Currently WTI crude (EIA); more
-- commodities plug in here as their staging models arrive.

with prices as (

    select
        price_date,
        series,
        product_name,
        price,
        units
    from {{ ref('stg_eia__wti_spot') }}

),

with_change as (

    select
        *,
        lag(price) over (
            partition by series
            order by price_date
        ) as prev_price
    from prices

)

select
    {{ dbt_utils.generate_surrogate_key(['price_date', 'series']) }} as price_key,
    to_number(to_char(price_date, 'YYYYMMDD')) as date_key,   -- FK -> dim_date
    price_date,
    series,
    product_name,
    price,
    units,
    prev_price,
    price - prev_price                                    as change_abs,
    round((price / nullif(prev_price, 0) - 1) * 100, 4)   as change_pct
from with_change
