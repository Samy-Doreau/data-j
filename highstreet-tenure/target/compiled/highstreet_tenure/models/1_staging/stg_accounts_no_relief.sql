

with source as (
    select * from "highstreet"."public"."accounts_no_relief"
),

filemap as (
    select file_name, valid_from, valid_to from "highstreet"."analytics_analytics"."stg_filemap"
    where table_name = 'accounts_no_relief'
),

extracted as (
    select
        source.id,
        source_file,
        loaded_at,
        -- Extract fields from the JSON data column
        data->>'billing_period' as billing_period,
        data->>'full_property_address' as full_property_address,
        (data->>'current_rateable_value')::numeric as current_rateable_value,
        data->>'primary_liable_party_name' as primary_liable_party_name,
        data->>'property_reference_number' as property_reference_number,
        (data->>'a_c_summary_current_liability')::numeric as a_c_summary_current_liability,
        data->>'liable_responsibility_start_date' as liable_responsibility_start_date,
        filemap.valid_from as valid_from,
        filemap.valid_to as valid_to
    from source
    left join filemap on source.source_file = filemap.file_name
)

select * from extracted