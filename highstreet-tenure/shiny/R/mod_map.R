mod_map_ui <- function(id) {
  ns <- NS(id)
  tagList(
    selectInput(ns("postcodeInput"), "Postcode prefix", choices = NULL, multiple = TRUE),
    leafletOutput(ns("locationsMap"), height = "600px")
  )
}

mod_map_server <- function(id, data, selected_address) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    postcodes_df <- data$business_addresses_df %>%
      distinct(postcode_three_letter) %>%
      rename(value = postcode_three_letter) %>%
      mutate(label = value)

    updateSelectInput(session, "postcodeInput", choices = postcodes_df)

    filtered_locations_df <- reactive({
      df <- data$addresses_with_most_tenants_df
      if (!is.null(input$postcodeInput) && length(input$postcodeInput) > 0)
        df <- df %>% filter(postcode_three_letter %in% input$postcodeInput)
      df
    })

    observeEvent(input$locationsMap_marker_click, {
      click <- input$locationsMap_marker_click
      if (!is.null(click)) selected_address(click$id)
    })

    output$locationsMap <- renderLeaflet({
      df <- filtered_locations_df() %>%
        mutate(popup_text = paste0(
          "<b>Address:</b> ", business_address,
          "<br><b>Tenants:</b> ", tenant_count
        ))
      df$tenant_count <- as.numeric(df$tenant_count)
      bins <- c(0, 2, 5, 10, 12)
      pal <- colorBin("YlOrRd", domain = df$tenant_count, bins = bins, na.color = "grey")

      leaflet(df) %>%
        addTiles() %>%
        fitBounds(~min(longitude), ~min(latitude), ~max(longitude), ~max(latitude)) %>%
        setView(lng = ST_ALBANS_CENTER_COORDS[1],
                lat = ST_ALBANS_CENTER_COORDS[2], zoom = 13) %>%
        addCircleMarkers(
          lng = ~longitude,
          lat = ~latitude,
          popup = ~popup_text,
          fillColor = ~pal(tenant_count),
          color = "black",
          weight = 1,
          fillOpacity = 0.8,
          radius = ~tenant_count * 3,
          layerId = ~business_address,
          clusterOptions = markerClusterOptions(
            spiderfyOnMaxZoom = TRUE, showCoverageOnHover = FALSE, zoomToBoundsOnClick = TRUE
          )
        ) %>%
        addLegend(pal = pal, values = df$tenant_count, title = "Tenant count", opacity = 1)
    })
  })
}
