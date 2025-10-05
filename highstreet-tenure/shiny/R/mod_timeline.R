mod_timeline_ui <- function(id) {
  ns <- NS(id)
  tagList(
    timevisOutput(ns("timeline"))
  )
}

mod_timeline_server <- function(id, data, selected_address, selected_business_name) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    filtered_df <- reactiveVal()

    observeEvent(selected_address(), {
      addr <- selected_address()
      if (!is.null(addr)) {
        df <- data$business_address_tenures_df %>%
          filter(business_address == addr) %>%
          rename(content = business_name, start = tenure_start_date, end = tenure_end_date) %>%
          mutate(id = row_number()) %>%
          filter(start != "", !is.na(start))
        filtered_df(df)
      } else filtered_df(NULL)
    })

    observeEvent(input$timeline_selected, {
      sel_id <- input$timeline_selected
      if (!is.null(sel_id) && nrow(filtered_df()) > 0) {
        df <- filtered_df()
        selected_row <- df %>% filter(id == sel_id)
        if (nrow(selected_row) > 0)
          selected_business_name(selected_row$content[1])
      }
    })

    output$timeline <- renderTimevis({
      df <- filtered_df()
      if (is.null(df) || nrow(df) == 0)
        df <- data.frame(id = character(), content = character(), start = character())
      timevis(df)
    })
  })
}
