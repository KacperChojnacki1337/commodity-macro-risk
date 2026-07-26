-- Eurostat JSON-stat: observations are a flat {flatIndex: value} map, and each
-- dimension maps its categories to an index. Here all dimensions except time
-- are size 1, so the flat index equals the time index. We flatten the time
-- index (KEY = period, VALUE = index) and look up value[index]. Monthly.

with source as (

    select raw, _src_file, _loaded_at
    from {{ source('bronze', 'eurostat_civil_eng_raw') }}

),

observations as (

    select
        to_date(t.key || '-01')                              as period_date,   -- '2024-03' -> 2024-03-01
        get(source.raw:value, t.value::string)::number(18, 4) as index_value,
        source._src_file,
        source._loaded_at
    from source,
         lateral flatten(input => source.raw:dimension:time:category:index) as t
    where get(source.raw:value, t.value::string) is not null

),

final as (

    select
        md5(to_varchar(period_date) || '|PL|civil_eng') as construction_key,
        period_date,
        'PL'         as geo,
        index_value,
        _src_file,
        _loaded_at
    from observations
    qualify row_number() over (
        partition by period_date
        order by _loaded_at desc
    ) = 1

)

select * from final
