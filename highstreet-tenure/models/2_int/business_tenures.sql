{{config(materialized='table')}}

with business_timeline as (
    select * from {{ ref('business_timeline') }}
),

business_tenures as (
    select 
        business_name, 
        min(event_date) as tenure_start_date,
        max(event_date) as tenure_end_date
    from business_timeline
    group by 1
)

select 
    business_name,
    tenure_start_date,
    tenure_end_date,
    round((tenure_end_date::date - tenure_start_date::date)/365.25,1) as tenure_duration_years
from business_tenures