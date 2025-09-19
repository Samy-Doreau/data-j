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
  all_locations_df<- dbGetQuery(conn, "SELECT property_address, longitude, latitude from analytics_analytics.addresses_geocoded;")
  businesses_tenures_df <- dbGetQuery(conn,"SELECT business_name, tenure_start_date, tenure_end_date from analytics_analytics.business_tenures")
  businesses_timelines_df <- dbGetQuery(conn, "SELECT business_name, event_date, event_type,source_file_name,source_file_url, year_month_key from analytics_analytics.business_timeline;")
  business_addresses_df <- dbGetQuery(conn, "SELECT business_name, business_address from analytics_analytics.business_addresses") %>% 
    inner_join(all_locations_df, by = c('business_address' = 'property_address')) %>% 
    mutate(latitude = as.numeric(latitude),longitude = as.numeric(longitude))
  
  businesses_df <- business_addresses_df %>% 
    select('business_name') %>% 
    distinct() %>% 
    rename('value'='business_name') %>% 
    mutate(label = value)
  
  filtered_locations_df = reactive({

    business_addresses_df%>%
      filter(business_name %in% input$businessNameInput)
      # rowwise() %>% 
      # mutate(dist_to_center = distHaversine(c(longitude, latitude),ST_ABLANS_CENTER_COORDS)) %>% 
      # filter(dist_to_center <= input$distance_to_center[2] && dist_to_center >= input$distance_to_center[1])
      
  })
  
  filtered_business_timelines_df = reactive({
    businesses_timelines_df %>% 
      filter(business_name %in% input$businessNameInput) %>% 
      mutate(
        source_file_link = sprintf(
          '<a href="%s" target="_blank">%s</a>',
          source_file_url,
          htmltools::htmlEscape(source_file_name)
        )
      ) %>% 
      select(-c('source_file_name','source_file_url'))
  })
  
  filtered_business_tenures_df = reactive({
    businesses_tenures_df %>% 
      filter(business_name %in% input$businessNameInput) %>% 
      rename('content' = 'business_name') %>% 
      rename('start' = 'tenure_start_date') %>% 
      rename('end' = 'tenure_end_date') %>% 
      mutate(id = row_number())
  })
  
  
  output$propertiesTable <- renderDataTable(filtered_locations_df())
  output$businessesTimelineDetails <- renderDataTable(filtered_business_timelines_df(),escape = FALSE)
  
  output$locationsMap <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% 
      setView(lng = ST_ABLANS_CENTER_COORDS[1], lat = ST_ABLANS_CENTER_COORDS[2], zoom = 13) %>% 
      addCircleMarkers(data =filtered_locations_df(), radius = 5 , lng = ~ longitude, lat = ~latitude,popup = ~business_name)
  })
  
  updateSelectizeInput(session,'businessNameInput', choices = businesses_df, server = TRUE)
  output$businessTenureTimeline <- renderTimevis(timevis(filtered_business_tenures_df()))
}
