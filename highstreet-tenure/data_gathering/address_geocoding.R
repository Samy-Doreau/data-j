library(DBI)
library(RPostgres)
library(dplyr)
library(tidygeocoder)

db <- "highstreet"
db_host <- "127.0.0.1"
db_port <- "5432"
db_user <- "postgres"
db_password <- "postgres"

Sys.setenv(
  MAPBOX_API_KEY='pk.eyJ1IjoiM2NkIiwiYSI6ImNtZmZrOW9pMzBrZWIya3NiaGNvcXR3ajUifQ.eHEVZr2xjsq4s1nQW9jpPw'
)

# Define helper function to connect
get_connection <- function() {
  conn <- dbConnect(
    RPostgres::Postgres(),
    dbname = db,
    host = db_host,
    port = db_port,
    user = db_user,
    password = db_password
  )
  
  return(conn)
}

conn <- get_connection()
addresses_input <- dbGetQuery(conn, "SELECT DISTINCT property_address from analytics_analytics.properties;")
# addresses_input <- addresses_input %>%
#   geocode(
#     property_address,
#     method = 'mapbox',
#     lat = latitude, long = longitude
#   )


dbExecute(conn, "CREATE TABLE IF NOT EXISTS analytics_analytics.addresses_geocoded (property_address VARCHAR, latitude double precision, longitude double precision) ")
dbWriteTable(
  conn,
  DBI::Id(schema = "analytics_analytics", table = "addresses_geocoded"),
  addresses_input |> select(property_address, latitude, longitude), 
  append=TRUE
)



## Upload to postgres from local
geocoded_df <- read.csv('~/Downloads/addresses_geocoded_bkp.csv',header= FALSE, col.names = c('property_address', 'latitude','longitude'))
dbExecute(conn, "CREATE TABLE IF NOT EXISTS analytics_analytics.addresses_geocoded (property_address VARCHAR, latitude double precision, longitude double precision) ")
dbWriteTable(
  conn,
  DBI::Id(schema = "analytics_analytics", table = "addresses_geocoded"),
  geocoded_df |> select(property_address, latitude, longitude), 
  append=TRUE
)




