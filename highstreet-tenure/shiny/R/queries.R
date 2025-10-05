queries <- list(
  all_locations = "SELECT property_address, longitude, latitude FROM analytics_analytics.addresses_geocoded;",
  all_businesses = "SELECT business_name, business_category FROM analytics_analytics.businesses;",
  addresses_with_most_tenants = "
    SELECT agg.business_address, agg.postcode, agg.postcode_three_letter, agg.tenant_count,
           addr.latitude, addr.longitude
    FROM analytics_analytics.addresses_with_most_tenants agg
    INNER JOIN analytics_analytics.addresses_geocoded addr
      ON addr.property_address = agg.business_address;",
  business_addresses = "
    SELECT business_name, business_address, postcode
    FROM analytics_analytics.business_addresses;",
  business_address_tenures = "
    SELECT business_name, business_address, tenure_start_date, tenure_end_date, tenure_duration_years
    FROM analytics_analytics.business_address_tenures;",
  business_address_timelines = "
    SELECT business_name, business_address, event_date, event_type, source_file_name, source_file_url
    FROM analytics_analytics.business_address_timeline;"
)
