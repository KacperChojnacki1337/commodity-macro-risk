-- Open-Meteo stores each measurement as its own array, aligned by position with
-- daily.time. We flatten the time array to get the index, then index into the
-- parallel arrays to "zip" them into one row per day.
-- Temperatures/precip are physical measurements -> float is fine here.

with source as (

    select raw, _src_file, _loaded_at
    from {{ source('bronze', 'openmeteo_weather_raw') }}

),

flattened as (

    select
        t.value::date                                          as weather_date,
        source.raw:latitude::number(9, 4)                      as latitude,
        source.raw:longitude::number(9, 4)                     as longitude,
        source.raw:daily:temperature_2m_max[t.index]::float    as temp_max_c,
        source.raw:daily:temperature_2m_min[t.index]::float    as temp_min_c,
        source.raw:daily:precipitation_sum[t.index]::float     as precip_mm,
        source._src_file,
        source._loaded_at
    from source,
         lateral flatten(input => source.raw:daily:time) as t
    where source.raw:daily:temperature_2m_max[t.index] is not null

),

final as (

    select
        md5(to_varchar(weather_date) || '|' || latitude || '|' || longitude) as weather_key,
        weather_date,
        latitude,
        longitude,
        temp_max_c,
        temp_min_c,
        round((temp_max_c + temp_min_c) / 2, 2) as temp_avg_c,
        precip_mm,
        _src_file,
        _loaded_at
    from flattened
    qualify row_number() over (
        partition by weather_date, latitude, longitude
        order by _loaded_at desc
    ) = 1

)

select * from final
