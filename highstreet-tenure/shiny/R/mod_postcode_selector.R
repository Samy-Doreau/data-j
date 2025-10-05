mod_postcode_selector_ui <- function(id) {
  ns <- NS(id)
  tagList(
    selectizeInput(ns("postcodeInput"), "Postcode prefix", choices = NULL, selected = NULL, multiple = TRUE)
  )
}

mod_postcode_selector_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    postcodes_vec <- data$business_addresses_df %>%
      filter(!is.na(postcode_three_letter), postcode_three_letter != "") %>%
      distinct(postcode_three_letter) %>%
      arrange(postcode_three_letter) %>%
      pull(postcode_three_letter)

    updateSelectizeInput(session, "postcodeInput", choices = postcodes_vec)

    reactive({ input$postcodeInput })
  })
}


