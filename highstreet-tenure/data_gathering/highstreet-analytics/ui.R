library(shiny)
library(leaflet)

# Define UI for application that draws a histogram
fluidPage(

    # Application title
    titlePanel("St Albans High Street Analytics"),

    sidebarLayout(
      sidebarPanel = sidebarPanel(
        sliderInput('distance_to_center','Distance to town center (m)', min = 100, max = 1500, value = c(150,500))
      ),
      mainPanel = mainPanel(
        dataTableOutput('propertiesTable'),
        leafletOutput(outputId = 'locationsMap')
      )
    )
    
)
