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
library(stringdist)
library(glue)
library(leaflet.extras)

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


queries <- list(
  all_locations = "SELECT property_address, longitude, latitude from analytics_analytics.addresses_geocoded;",
  all_businesses = "SELECT business_name, business_category from analytics_analytics;",
  addresses_with_most_tenants =  "SELECT 
	    agg.business_address, agg.postcode, agg.postcode_three_letter, agg.tenant_count ,addr.latitude, addr.longitude
      from analytics_analytics.addresses_with_most_tenants agg
      inner join analytics_analytics.addresses_geocoded addr on addr.property_address = agg.business_address",
  business_addresses = "SELECT business_name, business_address, postcode from analytics_analytics.business_addresses",
  business_address_tenures = "SELECT 
  business_name,business_address,tenure_start_date,tenure_end_date,tenure_duration_years 
  FROM analytics_analytics.business_address_tenures",
  business_address_timelines = "SELECT business_name, business_address,event_date, event_type, source_file_name, source_file_url 
  from analytics_analytics.business_address_timeline"
)



# Define server logic
server <- function(input, output, session) {
  
  conn <- get_connection()
  all_locations_df<- dbGetQuery(conn, queries$all_locations)
  all_businesses_df <- dbGetQuery(conn, queries$all_businesses)
  addresses_with_most_tenants_df <- dbGetQuery(conn,queries$addresses_with_most_tenants)
  business_address_tenures_df <- dbGetQuery(conn, queries$business_address_tenures)
  business_address_timelines_df <- dbGetQuery(conn, queries$business_address_timelines)
 
  business_addresses_df <- dbGetQuery(conn, queries$business_addresses) %>% 
    inner_join(all_locations_df, by = c('business_address' = 'property_address')) %>% 
    mutate(latitude = as.numeric(latitude),longitude = as.numeric(longitude)) %>% 
    mutate(postcode_three_letter = substr(postcode, 1,4))
  
  
  filtered_business_addresses_tenures_df <- reactiveVal()
  
  
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
  
  filtered_locations_df <- reactive({
    df <- addresses_with_most_tenants_df
    
    if (!is.null(input$postcodeInput) && length(input$postcodeInput) > 0) {
      df <- df %>% filter(postcode_three_letter %in% input$postcodeInput)
    }
    
    df
  
  })
  
  observeEvent(input$locationsMap_marker_click, {
    click <- input$locationsMap_marker_click
    if (!is.null(click)) {
      addr <- click$id   # because you set layerId = ~business_address
      df <- business_address_tenures_df %>%
        filter(business_address == addr) %>%
        rename(content = business_name, start = tenure_start_date, end = tenure_end_date) %>%
        mutate(id = row_number()) %>%
        filter(start != '', !is.na(start))
      filtered_business_addresses_tenures_df(df)
    } else {
      filtered_business_addresses_tenures_df(NULL)
    }
  })
  
  
  observeEvent(input$businessAddressTenureTimeline_selected, {
    sel_id <- input$businessAddressTenureTimeline_selected
    
    if (length(sel_id) > 0) {
  
      selected_df <- filtered_business_addresses_tenures_df() %>%
        filter(id == sel_id)
      
      
      if (nrow(selected_df) > 0) {
        selected_business_name <- selected_df[["content"]][1]
        output$tenureDetails <- renderDataTable({
          business_address_timelines_df %>% 
            filter(business_name == selected_business_name) %>% 
            mutate(
                    source_file_link = sprintf(
                      '<a href="%s" target="_blank">%s</a>',
                      source_file_url,
                      htmltools::htmlEscape(source_file_name)
                    )
                  ) %>%
            select(-c('source_file_name','source_file_url'))
        }, escape = FALSE)
      } else {
        output$tenureDetails <- renderTable({ data.frame() })
      }
    }
  })
  
  
  
  output$locationsMap <- renderLeaflet({
    df <- filtered_locations_df() %>%
      mutate(
        popup_text = paste0(
          "<b>Address:</b> ", business_address,
          "<br><b>Tenants:</b> ", tenant_count
        )
      )
    df$tenant_count <- as.numeric(df$tenant_count)
    

    bins <- c(0,2,5,10, 12)
    pal <- colorBin("YlOrRd", domain = df$tenant_count, bins = bins, na.color = "grey")
    
    
    
    leaflet(df) %>%
      addTiles() %>%
      fitBounds(~min(longitude), ~min(latitude),
                ~max(longitude), ~max(latitude)) %>%
      setView(lng = ST_ABLANS_CENTER_COORDS[1],
              lat = ST_ABLANS_CENTER_COORDS[2], zoom = 13) %>%
      addCircleMarkers(
        lng = ~longitude,
        lat = ~latitude,
        popup = ~popup_text,
        fillColor = ~pal(tenant_count),
        color = "black",
        weight = 1,
        fillOpacity = 0.8,
        radius = ~tenant_count * 3,   # scale radius by tenant count
        layerId = ~business_address,
        clusterOptions = markerClusterOptions(spiderfyOnMaxZoom = TRUE, showCoverageOnHover = FALSE, zoomToBoundsOnClick = TRUE)
      ) %>%
      addLegend(
        pal = pal,
        values = df$tenant_count,
        title = "Tenant count",
        opacity = 1
      )
     
  })
  
  
  updateSelectizeInput(session,'businessNameInput', choices = businesses_df, server = TRUE)
  updateSelectInput(session, 'postcodeInput', choices = postcodes_df)
  output$businessAddressTenureTimeline <- renderTimevis({
    df <- filtered_business_addresses_tenures_df()
    if (is.null(df) || nrow(df) == 0) {
      df <- data.frame(id = character(), content = character(), start = character())
    }
    timevis(df)
  })
}
