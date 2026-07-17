-- NBP Table A: one raw JSON document per file -> one typed row per
-- (effective_date, currency). Materialized as a view (see dbt_project.yml).

with source as (

    select
        raw,
        _src_file,
        _loaded_at
    from {{ source('bronze', 'nbp_fx_rates_raw') }}

),

-- The NBP response is an array of table documents; unnest it.
documents as (

    select
        d.value:"table"::string     as table_name,
        d.value:no::string          as table_no,
        d.value:effectiveDate::date as effective_date,
        d.value:rates               as rates,
        source._src_file,
        source._loaded_at
    from source,
         lateral flatten(input => source.raw) as d

),

-- Each document holds an array of currency rates; unnest that too.
rates as (

    select
        documents.effective_date,
        documents.table_no,
        r.value:code::string      as currency_code,
        r.value:currency::string  as currency_name,
        r.value:mid::number(18, 6) as mid_rate,
        documents._src_file,
        documents._loaded_at
    from documents,
         lateral flatten(input => documents.rates) as r

),

final as (

    select
        md5(to_varchar(effective_date) || '|' || currency_code) as fx_rate_key,
        effective_date,
        currency_code,
        currency_name,
        mid_rate,
        table_no,
        _src_file,
        _loaded_at
    from rates
    -- A day can land more than once (re-runs, backfills). Keep the most
    -- recently loaded row per (date, currency) so the grain stays unique.
    qualify row_number() over (
        partition by effective_date, currency_code
        order by _loaded_at desc
    ) = 1

)

select * from final
