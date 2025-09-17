{{
  config(
    materialized='table',
    schema='analytics'
  )
}}

with date_spine as (
    select 
        ('1991-01-01'::date + interval '1 month' * (row_number() over (order by null) - 1))::date as date_month
    from generate_series(1, 432)  -- 432 months from Jan 1991 to Dec 2026
)

select 
    date_month,
    to_char(date_month, 'YYYYMM') as year_month_key,
    to_char(date_month, 'Mon-YYYY') as formatted_month_year,
    extract(year from date_month) as year,
    extract(month from date_month) as month,
    to_char(date_month, 'Month') as month_name,
    to_char(date_month, 'Mon') as month_abbr
from date_spine
order by date_month
