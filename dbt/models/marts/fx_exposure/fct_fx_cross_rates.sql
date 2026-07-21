-- Cross rates derived from NBP (which quotes everything vs PLN):
--   currency in USD = (currency/PLN) / (USD/PLN)
--   currency in EUR = (currency/PLN) / (EUR/PLN)
-- Grain: one row per (rate_date, currency_code). Materialized as a table.

with rates as (

    select effective_date as rate_date, currency_code, mid_rate
    from {{ ref('stg_nbp__fx_rates') }}

),

-- The PLN value of 1 USD and 1 EUR on each date (the anchors for the crosses).
anchors as (

    select
        rate_date,
        max(case when currency_code = 'USD' then mid_rate end) as usd_pln,
        max(case when currency_code = 'EUR' then mid_rate end) as eur_pln
    from rates
    group by rate_date

)

select
    to_number(to_char(r.rate_date, 'YYYYMMDD')) as date_key,   -- FK -> dim_date
    r.currency_code,                                            -- FK -> dim_currency
    r.rate_date,
    r.mid_rate                                  as pln_per_unit,  -- PLN per 1 unit (NBP native)
    round(r.mid_rate / nullif(a.usd_pln, 0), 6) as usd_per_unit,  -- USD per 1 unit
    round(r.mid_rate / nullif(a.eur_pln, 0), 6) as eur_per_unit   -- EUR per 1 unit
from rates r
join anchors a using (rate_date)
