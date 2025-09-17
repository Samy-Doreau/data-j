

with business_addresses_new as (
    select distinct full_property_address as business_address, primary_liable_party_name as business_name from "highstreet"."analytics_analytics"."stg_new_businesses"

),

business_addresses_accounts_no_relief as (
    select distinct full_property_address as business_address, primary_liable_party_name as business_name from "highstreet"."analytics_analytics"."stg_accounts_no_relief"

),

business_addresses_accounts_relief as (
    select distinct full_property_address as business_address, primary_liable_party_name as business_name from "highstreet"."analytics_analytics"."stg_accounts_relief"

),

business_addresses_accounts_closed as (
    select distinct full_property_address as business_address, primary_liable_party_name as business_name from "highstreet"."analytics_analytics"."stg_accounts_closed"

),

combined_business_addresses as (

    select * from business_addresses_new
    union 
    select * from business_addresses_accounts_no_relief
    union 
    select * from business_addresses_accounts_relief
    union 
    select * from business_addresses_accounts_closed
)

select distinct business_name, business_address from combined_business_addresses