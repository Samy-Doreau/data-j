library(shiny)
library(DBI)
library(RPostgres)
library(dplyr)
library(tidygeocoder)
library(geosphere)
library(leaflet)
library(sf)
library(timevis)
library(RColorBrewer)

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
  addresses_with_most_tenants_df <- dbGetQuery(
    conn,
    "SELECT 
	    agg.business_address, agg.postcode, agg.postcode_three_letter, agg.tenant_count ,addr.latitude, addr.longitude
      from analytics_analytics.addresses_with_most_tenants agg
      inner join analytics_analytics.addresses_geocoded addr on addr.property_address = agg.business_address"
  )
  
  businesses_tenures_df <- dbGetQuery(
    conn,
    "SELECT 
    bt.business_name, bt.tenure_start_date, bt.tenure_end_date,
    ba.postcode
    from analytics_analytics.business_tenures bt
    inner join analytics_analytics.business_addresses ba
    on bt.business_name = ba.business_name; "
  ) %>% mutate(postcode_three_letter = substr(postcode, 1,4))
  businesses_timelines_df <- dbGetQuery(
    conn, 
    "SELECT 
      bt.business_name, bt.event_date, bt.event_type,source_file_name,bt.source_file_url, bt.year_month_key,
      ba.postcode
    from analytics_analytics.business_timeline bt
    inner join analytics_analytics.business_addresses ba
    on bt.business_name = ba.business_name;"
  ) %>% 
    mutate(postcode_three_letter = substr(postcode, 1,4))
  
  
  
  business_addresses_df <- dbGetQuery(conn, "SELECT business_name, business_address, postcode from analytics_analytics.business_addresses") %>% 
    inner_join(all_locations_df, by = c('business_address' = 'property_address')) %>% 
    mutate(latitude = as.numeric(latitude),longitude = as.numeric(longitude)) %>% 
    mutate(postcode_three_letter = substr(postcode, 1,4))
  
  businesses_df <- business_addresses_df %>% 
    select('business_name') %>% 
    distinct() %>% 
    rename('value'='business_name') %>% 
    mutate(label = value)
  
  postcodes_df <-  business_addresses_df %>% 
    select('postcode_three_letter') %>% 
    distinct()%>% 
    rename('value'='postcode_three_letter') %>% 
    mutate(label = value)
  
  
  
  
  filtered_locations_df = reactive({

    addresses_with_most_tenants_df%>%
      # filter(business_name %in% input$businessNameInput)
      filter(postcode_three_letter %in% input$postcodeInput)
      # rowwise() %>% 
      # mutate(dist_to_center = distHaversine(c(longitude, latitude),ST_ABLANS_CENTER_COORDS)) %>% 
      # filter(dist_to_center <= input$distance_to_center[2] && dist_to_center >= input$distance_to_center[1])
      
  })
  
  pal <- colorNumeric(palette = c("green", "red"), domain = addresses_with_most_tenants_df$tenant_count)
  
  filtered_business_timelines_df = reactive({
    businesses_timelines_df %>% 
      # filter(business_name %in% input$businessNameInput) %>% 
      filter(postcode_three_letter %in% input$postcodeInput) %>% 
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
      # filter(business_name %in% input$businessNameInput) %>% 
      filter(postcode_three_letter %in% input$postcodeInput) %>% 
      rename('content' = 'business_name') %>% 
      rename('start' = 'tenure_start_date') %>% 
      rename('end' = 'tenure_end_date') %>% 
      mutate(id = row_number()) %>% 
      filter(start != '', !is.na(start),end != '', !is.na(end))
  })
  
  
  # output$propertiesTable <- renderDataTable(filtered_locations_df())
  output$businessesTimelineDetails <- renderDataTable(filtered_business_timelines_df(),escape = FALSE)
  
  output$locationsMap <- renderLeaflet({
    df <- filtered_locations_df() %>%
      mutate(
        popup_text = paste0(
          "<b>Address:</b> ", business_address,
          "<br><b>Tenants:</b> ", tenant_count
        )
      )
    
    # pick a nice sequential palette (e.g. "YlOrRd")
    pal <- colorNumeric(
      palette = brewer.pal(9, "YlOrRd"),
      domain = df$tenant_count
    )
    
    leaflet(df) %>%
      addTiles() %>%
      fitBounds(~min(longitude), ~min(latitude),
                ~max(longitude), ~max(latitude)) %>%
      setView(lng = ST_ABLANS_CENTER_COORDS[1],
              lat = ST_ABLANS_CENTER_COORDS[2], zoom = 13) %>%
      addCircles(
        lng = ~longitude,
        lat = ~latitude,
        popup = ~popup_text,
        color = ~pal(tenant_count),
        fillOpacity = 0.8,
        radius = 5   # scale radius by tenant count
      ) %>%
      addLegend(
        pal = pal,
        values = ~tenant_count,
        title = "Tenant count",
        opacity = 1
      )
  })
  
  
  updateSelectizeInput(session,'businessNameInput', choices = businesses_df, server = TRUE)
  updateSelectInput(session, 'postcodeInput', choices = postcodes_df)
  # output$businessTenureTimeline <- renderTimevis(timevis(filtered_business_tenures_df()))
}
