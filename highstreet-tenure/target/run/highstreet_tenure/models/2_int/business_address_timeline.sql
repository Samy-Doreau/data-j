
  
    

  create  table "highstreet"."analytics_analytics"."business_address_timeline__dbt_tmp"
  
  
    as
  
  (
    

with account_ends as (
    select distinct
        primary_liable_party_name as business_name,
        full_property_address as business_address,
        account_start_date,
        account_end_date,
        account_end_date as event_date,
        'account_end' as event_type,
        property_reference_number as property_id,
        source_file as source_file_name
    from "highstreet"."analytics_analytics"."stg_accounts_closed"
),

accounts_new as (
    select distinct
        primary_liable_party_name as business_name, 
        full_property_address as business_address,
        liable_responsibility_start_date as account_start_date,
        NULL as account_end_date,
        liable_responsibility_start_date as event_date,
        'account_start' as event_type,
        property_reference_number as property_id,
        source_file as source_file_name
    from "highstreet"."analytics_analytics"."stg_new_businesses"
),

accounts_no_relief_active as (
    select distinct
        primary_liable_party_name as business_name, 
        full_property_address as business_address,
        liable_responsibility_start_date as account_start_date,
        NULL as account_end_date,
        valid_to as event_date, -- Event date derived from file metadata (filename)
        'account_active' as event_type,
        property_reference_number as property_id,
        source_file as source_file_name
    from "highstreet"."analytics_analytics"."stg_accounts_no_relief"
),

accounts_relief_active as (
    select distinct
        primary_liable_party_name as business_name, 
        full_property_address as business_address,
        liable_responsibility_start_date as account_start_date,
        NULL as account_end_date,
        valid_to as event_date, 
        'account_active' as event_type,
        property_reference_number as property_id,
        source_file as source_file_name
    from "highstreet"."analytics_analytics"."stg_accounts_relief"
),

combined_accounts as (
    select distinct business_name, business_address, event_date, event_type, source_file_name from account_ends
    union 
    select distinct business_name, business_address, event_date, event_type, source_file_name from accounts_new
    union all
    select distinct business_name, business_address, event_date, event_type, source_file_name from accounts_no_relief_active
    union all
    select distinct business_name, business_address, event_date, event_type, source_file_name from accounts_relief_active
)

select 
    
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
    business_address, event_date, event_type, source_file_name,
    concat('https://www.stalbans.gov.uk/sites/default/files/attachments/', source_file_name) as source_file_url,
    to_char(event_date::date, 'YYYYMM')::int as year_month_key 
from combined_accounts order by business_name, business_address, event_date
  );
  