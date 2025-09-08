{{ config(materialized='table') }}

with source as (
    select * from {{ source('highstreet', 'accounts_closed') }}
),

filemap as (
    select file_name, valid_from, valid_to from {{ ref('stg_filemap') }}
    where table_name = 'accounts_closed'
),

extracted as (
    select
        source.id,
        source.source_file,
        source.loaded_at,
        -- Extract fields from the JSON data column
        data->>'account_start_date' as account_start_date,
        data->>'account_end_date' as account_end_date,
        (data->>'outstanding_debt')::numeric as outstanding_debt,
        data->>'full_property_address' as full_property_address,
        data->>'primary_liable_party_name' as primary_liable_party_name,
        data->>'property_reference_number' as property_reference_number,
        filemap.valid_from as valid_from,
        filemap.valid_to as valid_to
    from source
    left join filemap on source.source_file = filemap.file_name
)

select * from extracted

