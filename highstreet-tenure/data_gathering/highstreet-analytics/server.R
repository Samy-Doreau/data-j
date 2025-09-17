library(shiny)
library(DBI)
library(RPostgres)
library(dplyr)
library(tidygeocoder)
library(geosphere)
library(leaflet)
library(sf)
library(timevis)

db <- "highstreet"
db_host <- "127.0.0.1"
db_port <- "5432"
db_user <- "postgres"
db_password <- "postgres"

ST_ABLANS_CENTER_COORDS = c( -0.34051187167734015,51.751303604248065)

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

# Define server logic
server <- function(input, output, session) {
  
  conn <- get_connection()
  all_locations_df<- dbGetQuery(conn, "SELECT property_address, longitude, latitude from analytics_analytics.addresses_geocoded limit 10;")
  businesses_tenures_df <- dbGetQuery(conn,"SELECT business_name, tenure_start_date, tenure_end_date from analytics_analytics.business_tenures")
  businesses_df <- businesses_tenures_df %>% 
    select('business_name') %>% 
    distinct() %>% 
    rename('value'='business_name') %>% 
    mutate(label = value)
  
  filtered_locations_df = reactive({

    all_locations_df%>% 
      rowwise() %>% 
      mutate(dist_to_center = distHaversine(c(longitude, latitude),ST_ABLANS_CENTER_COORDS)) %>% 
      filter(dist_to_center <= input$distance_to_center[2] && dist_to_center >= input$distance_to_center[1])
    
  }) 
  
  output$propertiesTable <- renderDataTable(filtered_locations_df())
  
  output$locationsMap <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% 
      setView(lng = ST_ABLANS_CENTER_COORDS[1], lat = ST_ABLANS_CENTER_COORDS[2], zoom = 13) %>% 
      addCircleMarkers(data =filtered_locations_df(), radius = 5 , lng = ~ longitude, lat = ~latitude)
  })
  
  updateSelectizeInput(session,'businessNameInput', choices = businesses_df, server = TRUE)
}
