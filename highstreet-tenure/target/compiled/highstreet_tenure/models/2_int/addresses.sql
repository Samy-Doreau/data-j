

with properties as (
    select * from "highstreet"."analytics_analytics"."properties"
)

select distinct property_address from properties