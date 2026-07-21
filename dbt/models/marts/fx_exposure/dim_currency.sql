-- Currency dimension. One row per currency quoted by NBP Table A, with a flag
-- for the majors (used for slicers / filtering to the key exposure currencies).

with currencies as (

    select distinct
        currency_code,
        currency_name
    from {{ ref('stg_nbp__fx_rates') }}

)

select
    currency_code,   -- ISO 4217; natural key referenced by the facts
    currency_name,
    currency_code in ('USD', 'EUR', 'GBP', 'CHF', 'JPY', 'CAD', 'AUD', 'CNY') as is_major
from currencies
