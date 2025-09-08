{{ config(materialized='table') }}

with source as (
    select * from {{ source('highstreet', 'filename_mapping') }}
),

extracted as (
    select
        id,
        source_file,
        loaded_at,
        -- Extract fields from the JSON data column
        data->>'file_name' as file_name,
        data->>'table_name' as table_name,
        data->>'valid_from' as valid_from,
        data->>'valid_to' as valid_to
    from source
)

select * from extracted

