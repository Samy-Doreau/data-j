{{ config(materialized='table') }}

with properties as (
    select * from {{ref('properties')}}
)

select distinct property_address from properties