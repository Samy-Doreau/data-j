{{config(materialized='table')}}

with business_address_timeline as (
    select * from {{ ref('business_address_timeline') }} where lower(business_name) not like '%ratepayer%'
),

-- Normalise names
business_address_timeline_normalised as (
    select
        business_address,
        event_date,
        business_name
       
    from business_address_timeline
),

business_address_tenures as (
    select 
        business_name,       
        business_address,
        min(event_date) as tenure_start_date,
        max(event_date) as tenure_end_date
    from business_address_timeline_normalised
    group by 1,2
)

select 
    business_name,
    business_address,
    tenure_start_date,
    case 
        when tenure_end_date = tenure_start_date then null 
        else tenure_end_date 
    end as tenure_end_date,
    round((tenure_end_date::date - tenure_start_date::date)/365.25,1) as tenure_duration_years
from business_address_tenures
