-- ECB euro short-term rate. Bronze is already structured (projected from CSV),
-- so staging just renames, keeps the grain and deduplicates. Materialized view.

with source as (

    select
        series_key,
        obs_date as rate_date,
        obs_value as rate_pct,
        title as series_name,
        _src_file,
        _loaded_at
    from {{ source('bronze', 'ecb_estr_raw') }}
    where obs_value is not null

),

final as (

    select
        md5(to_varchar(rate_date) || '|' || series_key) as rate_key,
        rate_date,
        series_key,
        series_name,
        rate_pct,
        _src_file,
        _loaded_at
    from source
    qualify row_number() over (
        partition by rate_date, series_key
        order by _loaded_at desc
    ) = 1

)

select * from final
