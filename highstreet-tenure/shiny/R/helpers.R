ST_ALBANS_CENTER_COORDS <- c(-0.34051187167734015, 51.751303604248065)

load_dataframes <- function(conn, queries) {
  list(
    all_locations_df = dbGetQuery(conn, queries$all_locations),
    all_businesses_df = dbGetQuery(conn, queries$all_businesses),
    addresses_with_most_tenants_df = dbGetQuery(conn, queries$addresses_with_most_tenants),
    business_addresses_df = dbGetQuery(conn, queries$business_addresses),
    business_address_tenures_df = dbGetQuery(conn, queries$business_address_tenures),
    business_address_timelines_df = dbGetQuery(conn, queries$business_address_timelines)
  )
}
