
  create view "highstreet"."analytics_analytics"."business_with_full_timeline__dbt_tmp"
    
    
  as (
    with 

business_timeline as (
    select * from "highstreet"."analytics_analytics"."business_timeline"
),

new_event_counts_by_business as (
    select 
        business_name,
        count(*) as new_event_count
    from business_timeline
    where event_type = 'account_start'
    group by 1
    having count(*) > 1
),

end_event_counts_by_business as (
    select 
        business_name,
        count(*) as end_event_count
    from business_timeline
    where event_type = 'account_end'
    group by 1
    having count(*) > 1
)

select business_timeline.* 
from business_timeline
inner join new_event_counts_by_business on business_timeline.business_name = new_event_counts_by_business.business_name
inner join end_event_counts_by_business on business_timeline.business_name = end_event_counts_by_business.business_name
order by business_timeline.business_name, business_timeline.event_date desc
  );