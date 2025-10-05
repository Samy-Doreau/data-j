ui <- fluidPage(
  titlePanel("St Albans Business Timeline"),
  sidebarLayout(
    sidebarPanel(
      mod_map_ui("map_module")
    ),
    mainPanel(
      mod_timeline_ui("timeline_module"),
      mod_details_ui("details_module")
    )
  )
)

server <- function(input, output, session) {
  conn <- get_connection()
  data <- load_dataframes(conn, queries)

  data$business_addresses_df <- data$business_addresses_df %>%
    inner_join(data$all_locations_df, by = c("business_address" = "property_address")) %>%
    mutate(latitude = as.numeric(latitude),
           longitude = as.numeric(longitude),
           postcode_three_letter = substr(postcode, 1, 4))

  selected_address <- reactiveVal()
  selected_business_name <- reactiveVal()

  mod_map_server("map_module", data, selected_address)
  mod_timeline_server("timeline_module", data, selected_address, selected_business_name)
  mod_details_server("details_module", data, selected_business_name)
}
