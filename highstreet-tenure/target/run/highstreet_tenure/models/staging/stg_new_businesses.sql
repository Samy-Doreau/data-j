
  
    

  create  table "highstreet"."analytics_analytics"."stg_new_businesses__dbt_tmp"
  
  
    as
  
  (
    

with source as (
    select * from "highstreet"."public"."new_businesses"
),

filemap as (
    select file_name, valid_from, valid_to from "highstreet"."analytics_analytics"."stg_filemap"
    where table_name = 'new_businesses'
),

extracted as (
    select
        source.id,
        source_file,
        loaded_at,
        -- Extract fields from the JSON data column
        data->>'current_analysis_code_description' as current_analysis_code_description,
        data->>'primary_liable_party_name' as primary_liable_party_name,
        data->>'full_property_address' as full_property_address,
        data->>'liable_responsibility_start_date' as liable_responsibility_start_date,
        (data->>'current_rateable_value')::numeric as current_rateable_value,
        data->>'property_reference_number' as property_reference_number,
        filemap.valid_from as valid_from,
        filemap.valid_to as valid_to
    from source
    left join filemap on source.source_file = filemap.file_name
)

select * from extracted
  );
  