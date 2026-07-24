-- Daily weather for the demand-signals domain, for Power BI.
-- Grain: one row per (weather_date, latitude, longitude). Includes heating
-- degree days (base 18C) as a proxy for heating demand.

with weather as (

    select
        weather_key,
        weather_date,
        latitude,
        longitude,
        temp_max_c,
        temp_min_c,
        temp_avg_c,
        precip_mm
    from {{ ref('stg_openmeteo__warsaw_daily') }}

)

select
    weather_key,
    to_number(to_char(weather_date, 'YYYYMMDD')) as date_key,   -- FK -> dim_date
    weather_date,
    latitude,
    longitude,
    temp_max_c,
    temp_min_c,
    temp_avg_c,
    precip_mm,
    -- Heating degree days (base 18C): how far below 18C the day averaged.
    -- A common proxy for heating (and heating-fuel) demand.
    greatest(0, 18 - temp_avg_c)  as heating_degree_days,
    precip_mm > 0                 as is_rainy
from weather
