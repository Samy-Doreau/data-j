

with source as (
    select * from "highstreet"."public"."accounts_relief"
),

filemap as (
    select file_name, valid_from, valid_to from "highstreet"."analytics_analytics"."stg_filemap"
    where table_name = 'accounts_with_relief'
),

extracted as (
    select
        source.id,
        source_file,
        loaded_at,
        -- Extract fields from the JSON data column
        data->>'current_relief_type' as current_relief_type,
        data->>'full_property_address' as full_property_address,
        (data->>'current_rateable_value')::numeric as current_rateable_value,
        data->>'primary_liable_party_name' as primary_liable_party_name,
        data->>'property_reference_number' as property_reference_number,
        data->>'current_relief_award_start_date' as current_relief_award_start_date,
        data->>'current_relief_type_description' as current_relief_type_description,
        data->>'liable_responsibility_start_date' as liable_responsibility_start_date,
        (data->>'current_relief_award_perc_awarded')::numeric as current_relief_award_perc_awarded,
        filemap.valid_from as valid_from,
        filemap.valid_to as valid_to
    from source
    left join filemap on source.source_file = filemap.file_name
)

select * from extracted