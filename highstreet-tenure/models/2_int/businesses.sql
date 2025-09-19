{{ config(materialized='table') }}

with businesses_new as (
    select distinct primary_liable_party_name as business_name from {{ ref('stg_new_businesses') }}

),

businesses_accounts_closed as (
    select distinct primary_liable_party_name as business_name from {{ ref('stg_accounts_closed') }}

),

businesses_accounts_no_relief as (
    select distinct primary_liable_party_name as business_name from {{ ref('stg_accounts_no_relief') }}

),

businesses_accounts_relief as (
    select distinct primary_liable_party_name as business_name from {{ ref('stg_accounts_relief') }}

),


combined_businesses as (

    select business_name from businesses_new
    union 
    select business_name from businesses_accounts_closed
    union 
    select business_name from businesses_accounts_no_relief
    union 
    select business_name from businesses_accounts_relief

)

select distinct business_name from combined_businesses