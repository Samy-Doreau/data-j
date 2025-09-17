
  
    

  create  table "highstreet"."analytics_analytics"."business_tenures__dbt_tmp"
  
  
    as
  
  (
    

with business_timeline as (
    select * from "highstreet"."analytics_analytics"."business_timeline"
),

business_tenures as (
    select 
        business_name, 
        min(event_date) as tenure_start_date,
        max(event_date) as tenure_end_date
    from business_timeline
    group by 1
)

select * from business_tenures
  );
  