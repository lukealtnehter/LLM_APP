required_packages <- c(
  "shiny", "jsonlite", "shinyjs", "jsonvalidate",
  "readxl", "writexl", "tidyverse", "ollamar",
  "httr2", "arsenal"
)

# Function to install missing packages
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

# Install and load packages
invisible(lapply(required_packages, function(pkg) {
  install_if_missing(pkg)
  library(pkg, character.only = TRUE)
}))

# source("r functions/LLM extract function.R")

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