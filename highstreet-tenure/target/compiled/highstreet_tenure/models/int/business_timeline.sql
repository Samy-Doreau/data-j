

with account_ends as (
    select 
        primary_liable_party_name as business_name, 
        account_end_date  as event_date, 
        'account_end' as event_type
    from "highstreet"."analytics_analytics"."stg_accounts_closed"
),

accounts_new as (
    select 
        primary_liable_party_name as business_name, 
        liable_responsibility_start_date as event_date, 
        'account_start' as event_type
    from "highstreet"."analytics_analytics"."stg_new_businesses"
),

accounts_no_relief_active as (
    select 
        primary_liable_party_name as business_name, 
        liable_responsibility_start_date as event_date, 
        'account_active' as event_type
    from "highstreet"."analytics_analytics"."stg_accounts_no_relief"
),

accounts_relief_active as (
    select 
        primary_liable_party_name as business_name, 
        liable_responsibility_start_date as event_date, 
        'account_active' as event_type
    from "highstreet"."analytics_analytics"."stg_accounts_relief"
),

combined_accounts as (
    select * from account_ends
    union all
    select * from accounts_new
    union all
    select * from accounts_no_relief_active
    union all
    select * from accounts_relief_active
)

select * from combined_accounts order by business_name, event_date