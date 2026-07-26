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

),

gus as (

    select
        period_date,
        'gus'                                  as source_name,
        'PL'                                   as geo,
        'expressway_motorway_length'           as indicator,
        'annual'                               as frequency,
        road_km                                as value,
        'km'                                   as unit
    from {{ ref('stg_gus__expressways') }}
    where area = 'POLSKA'

),

combined as (
    select * from eurostat
    union all
    select * from gus
)

select
    {{ dbt_utils.generate_surrogate_key(['period_date', 'source_name', 'indicator']) }} as activity_key,
    to_number(to_char(period_date, 'YYYYMMDD')) as date_key,   -- FK -> dim_date (period start)
    period_date,
    source_name,
    geo,
    indicator,
    frequency,
    value,
    unit
from combined
