-- Calendar dimension. Generated with dbt_utils.date_spine so it has a row for
-- every day (not just business days) — lets charts fill gaps, enables time
-- intelligence, and gives every fact a single conformed calendar to join to.

with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="to_date('2026-01-01')",
        end_date="to_date('2027-01-01')"
    ) }}

)

select
    to_number(to_char(date_day, 'YYYYMMDD')) as date_key,   -- integer surrogate key (YYYYMMDD)
    date_day::date                           as full_date,
    year(date_day)                           as year,
    quarter(date_day)                        as quarter,
    month(date_day)                          as month,
    monthname(date_day)                      as month_name,
    day(date_day)                            as day_of_month,
    dayname(date_day)                        as day_name,
    dayname(date_day) not in ('Sat', 'Sun')  as is_weekday
from spine
