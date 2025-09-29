
  
    

  create  table "highstreet"."analytics_analytics"."business_addresses__dbt_tmp"
  
  
    as
  
  (
    

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

select distinct 
     
    regexp_replace(
        lower(
            trim(
                regexp_replace(                   -- collapse multiple spaces
                    regexp_replace(               -- remove non-alphanumeric (keep space)
                        regexp_replace(           -- replace "&" with "and"
                            business_name,
                            '&', 'and', 'gi'
                        ),
                        '[^a-zA-Z0-9 ]', '', 'g'
                    ),
                    '\\s+', ' ', 'g'
                )
            )
        ),
        '^ta ', '', 'g'
    )
 as business_name,
    business_address,
    split_part(business_address, ',', -1) as postcode
from combined_business_addresses
-- where lower(business_address) like '%st peters street%' 
-- or lower(business_address) like '%market place%'
-- or lower(business_address) like '%french row%'
-- or lower(business_address) like '%checker st%'
-- or lower(business_address) like '%george st%'
-- or lower(business_address) like '%holywell hill%'
-- or lower(business_address) like '%london r%'
-- or lower(business_address) like '%victoria st%'
-- or lower(business_address) like '%hatfield r%'
  );
  