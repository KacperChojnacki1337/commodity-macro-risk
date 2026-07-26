-- GUS BDL: length of expressways and motorways, annual (km). The document is
-- results[] per area, each with a values[] array of {year, val}. We flatten
-- both levels; period_date is the year's first day.

with source as (

    select raw, _src_file, _loaded_at
    from {{ source('bronze', 'gus_roads_raw') }}

),

flattened as (

    select
        to_date(v.value:year::string || '-01-01') as period_date,
        r.value:name::string                      as area,
        v.value:val::number(18, 2)                as road_km,
        source._src_file,
        source._loaded_at
    from source,
         lateral flatten(input => source.raw:results) as r,
         lateral flatten(input => r.value:values) as v
    where v.value:val is not null

),

final as (

    select
        md5(to_varchar(period_date) || '|' || area) as road_key,
        period_date,
        area,
        road_km,
        _src_file,
        _loaded_at
    from flattened
    qualify row_number() over (
        partition by period_date, area
        order by _loaded_at desc
    ) = 1

)

select * from final
