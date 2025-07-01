library(shiny)
library(jsonlite)
library(shinyjs)
library(jsonvalidate)
library(readxl)
library(writexl)
library(tidyverse)
library(ollamar)
library(httr2)
library(arsenal)

# JSON app
source("JSON/ui.R")      
json_ui <- ui
source("JSON/server.R")  
json_server <- server

# EXAMPLES app
source("EXAMPLES/ui.R")      
examples_ui <- ui
source("EXAMPLES/server.R")  
examples_server <- server

# PROMPT ENGINEERING app
source("PROMPT_ENGINEERING/ui.R")
prompt_ui <- ui
source("PROMPT_ENGINEERING/server.R")
prompt_server <- server

# RANDOM SAMPLE app
source("RANDOM_SAMPLE/ui.R")
random_ui <- ui
source("RANDOM_SAMPLE/server.R")
random_server <- server


ui <- navbarPage("",
  tabPanel("JSON ENTRY", json_ui),
  tabPanel("EXAMPLE ENTRY", examples_ui),
  tabPanel("PROMPT ENGINEERING", prompt_ui),
  tabPanel("RANDOM SAMPLE OR FULL RUN", random_ui )
)

server <- function(input, output, session) {
  json_server(input, output, session)
  examples_server(input, output, session)
  prompt_server(input, output, session)
  random_server(input, output, session)
}

shinyApp(ui, server)