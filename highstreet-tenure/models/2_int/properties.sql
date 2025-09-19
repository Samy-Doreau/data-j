{{ config(materialized='table') }}

with properties_new as (
    select distinct full_property_address as property_address, property_reference_number as property_id from {{ ref('stg_new_businesses') }}

),

properties_accounts_no_relief as (
    select distinct full_property_address as property_address, property_reference_number as property_id from {{ ref('stg_accounts_no_relief') }}

),

properties_accounts_relief as (
    select distinct full_property_address as property_address, property_reference_number as property_id from {{ ref('stg_accounts_relief') }}

),

properties_accounts_closed as (
    select distinct full_property_address as property_address, property_reference_number as property_id from {{ ref('stg_accounts_closed') }}

),

combined_properties as (

    select * from properties_new
    union 
    select * from properties_accounts_no_relief
    union 
    select * from properties_accounts_relief
    union 
    select * from properties_accounts_closed
)

select distinct property_id, property_address from combined_properties