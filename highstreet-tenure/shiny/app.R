library(shiny)
library(DBI)
library(RPostgres)
library(dplyr)
library(leaflet)
library(timevis)
library(htmltools)
library(leaflet.extras)
library(RColorBrewer)

# Load shared code
source("R/db_connection.R")
source("R/queries.R")
source("R/helpers.R")

# Load modules
source("R/mod_postcode_selector.R")
source("R/mod_map.R")
source("R/mod_timeline.R")
source("R/mod_details.R")
source("R/ui_main.R")

# Assemble app
shinyApp(ui = ui, server = server)
