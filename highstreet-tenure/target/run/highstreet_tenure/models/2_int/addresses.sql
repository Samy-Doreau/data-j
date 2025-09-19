
  
    

  create  table "highstreet"."analytics_analytics"."addresses__dbt_tmp"
  
  
    as
  
  (
    

with properties as (
    select * from "highstreet"."analytics_analytics"."properties"
)

select distinct property_address from properties
  );
  