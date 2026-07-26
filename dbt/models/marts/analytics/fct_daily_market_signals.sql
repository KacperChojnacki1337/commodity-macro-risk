-- Reconciles the mixed-frequency sources onto a single DAILY grain for Power BI.
-- Daily series (FX, oil, eSTR, weather), monthly (Eurostat) and annual (GUS) are
-- all brought to each day via ASOF JOIN = last-known-value ("as of" that day),
-- so there is exactly ONE row per day and no fan-out.
--
-- Grain: one row per market_date.

with bounds as (

    select min(rate_date) as start_date, max(rate_date) as end_date
    from {{ ref('fct_fx_rates') }}

),

spine as (

    select d.full_date as market_date
    from {{ ref('dim_date') }} d
    cross join bounds b
    where d.full_date between b.start_date and b.end_date

),

fx as (
    select
        rate_date,
        max(case when currency_code = 'USD' then mid_rate end) as usd_pln,
        max(case when currency_code = 'EUR' then mid_rate end) as eur_pln
    from {{ ref('fct_fx_rates') }}
    group by rate_date
),

oil as (
    select
        price_date,
        max(case when series = 'RWTC'  then price end) as wti_usd_bbl,
        max(case when series = 'RBRTE' then price end) as brent_usd_bbl
    from {{ ref('fct_commodity_prices') }}
    group by price_date
),

estr as (
    select rate_date, rate_pct from {{ ref('fct_interest_rates') }}
),

weather as (
    select weather_date, temp_avg_c, heating_degree_days
    from {{ ref('fct_weather_daily') }}
),

eurostat as (
    select period_date, value as civil_eng_index
    from {{ ref('fct_construction_activity') }}
    where source_name = 'eurostat'
),

gus as (
    select period_date, value as motorway_km
    from {{ ref('fct_construction_activity') }}
    where source_name = 'gus'
)

select
    to_number(to_char(s.market_date, 'YYYYMMDD')) as date_key,   -- FK -> dim_date
    s.market_date,
    -- daily (ASOF also forward-fills weekends with the last trading day)
    fx.usd_pln,
    fx.eur_pln,
    oil.wti_usd_bbl,
    oil.brent_usd_bbl,
    estr.rate_pct                    as estr_pct,
    weather.temp_avg_c,
    weather.heating_degree_days      as heating_degree_days,
    -- monthly, last-known as of the day
    eurostat.civil_eng_index,
    -- annual, last-known as of the day
    gus.motorway_km
from spine s
asof join fx       match_condition (s.market_date >= fx.rate_date)
asof join oil      match_condition (s.market_date >= oil.price_date)
asof join estr     match_condition (s.market_date >= estr.rate_date)
asof join weather  match_condition (s.market_date >= weather.weather_date)
asof join eurostat match_condition (s.market_date >= eurostat.period_date)
asof join gus      match_condition (s.market_date >= gus.period_date)
