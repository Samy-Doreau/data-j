mod_details_ui <- function(id) {
  ns <- NS(id)
  dataTableOutput(ns("details"))
}

mod_details_server <- function(id, data, selected_business_name) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observeEvent(selected_business_name(), {
      name <- selected_business_name()
      if (!is.null(name)) {
        output$details <- renderDataTable({
          data$business_address_timelines_df %>%
            filter(business_name == name) %>%
            mutate(
              source_file_link = sprintf(
                '<a href="%s" target="_blank">%s</a>',
                source_file_url,
                htmltools::htmlEscape(source_file_name)
              )
            ) %>%
            select(-source_file_name, -source_file_url)
        }, escape = FALSE)
      }
    })
  })
}
