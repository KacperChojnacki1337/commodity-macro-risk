-- Construction activity indicators (demand-signals domain), as a tall fact so
-- heterogeneous sources/frequencies conform to one shape:
--   (period_date, source, geo, indicator, frequency, value, unit).
-- Eurostat civil engineering (monthly) now; GUS road data unions in next.
-- Monthly rows are keyed to the month's first day, which exists in dim_date.

with eurostat as (

    select
        period_date,
        'eurostat'                             as source_name,
        geo,
        'civil_engineering_production_index'   as indicator,
        'monthly'                              as frequency,
        index_value                            as value,
        'index_2021_100'                       as unit
    from {{ ref('stg_eurostat__civil_eng') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['period_date', 'source_name', 'indicator']) }} as activity_key,
    to_number(to_char(period_date, 'YYYYMMDD')) as date_key,   -- FK -> dim_date (month start)
    period_date,
    source_name,
    geo,
    indicator,
    frequency,
    value,
    unit
from eurostat
