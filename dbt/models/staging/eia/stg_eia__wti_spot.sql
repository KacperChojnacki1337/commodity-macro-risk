-- EIA WTI crude oil spot price: flatten the raw JSON document's data array into
-- one typed row per (price_date, series). Materialized as a view.

with source as (

    select raw, _src_file, _loaded_at
    from {{ source('bronze', 'eia_wti_spot_raw') }}

),

flattened as (

    select
        d.value:period::date              as price_date,
        d.value:series::string            as series,
        d.value:"product-name"::string    as product_name,
        d.value:value::number(18, 6)      as price,           -- USD/barrel; decimal, not float
        d.value:units::string             as units,
        source._src_file,
        source._loaded_at
    from source,
         lateral flatten(input => source.raw:response:data) as d
    where d.value:value is not null   -- EIA returns null on non-trading days

),

final as (

    select
        md5(to_varchar(price_date) || '|' || series) as price_key,
        price_date,
        series,
        product_name,
        price,
        units,
        _src_file,
        _loaded_at
    from flattened
    -- Keep the most recently loaded row per (date, series) if a day reloads.
    qualify row_number() over (
        partition by price_date, series
        order by _loaded_at desc
    ) = 1

)

select * from final
