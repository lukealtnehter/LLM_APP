required_packages <- c(
  "shiny", "jsonlite", "shinyjs", "jsonvalidate",
  "readxl", "writexl", "tidyverse", "ollamar",
  "httr2", "arsenal", "shinyBS","shinyWidgets", "shinycssloaders","shinythemes"
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

#HOMEPAGE app
source("HOMEPAGE/ui.R")
source("HOMEPAGE/server.R") 

# JSON app
source("JSON/ui.R")      
source("JSON/server.R")  

# EXAMPLES app
source("EXAMPLES/ui.R")      
source("EXAMPLES/server.R")  

# PROMPT ENGINEERING app
source("PROMPT_ENGINEERING/ui.R")
source("PROMPT_ENGINEERING/server.R")

# RANDOM SAMPLE app
source("RANDOM_SAMPLE/ui.R")
source("RANDOM_SAMPLE/server.R")

# RUN EXTRACTION app
source("RUN_EXTRACTION/ui.R")
source("RUN_EXTRACTION/server.R")

# LICENSE page
source("LICENSE/ui.R")
source("LICENSE/server.R")


ui <- navbarPage("",
                 # Add custom CSS for scrollable content
                 tags$head(
                   tags$style(HTML("
      /* Make the body and html full height */
      html, body {
        height: 100%;
        margin: 0;
        padding: 0;
      }
      
      /* Fix the navbar at top */
      .navbar {
        position: fixed;
        top: 0;
        width: 100%;
        z-index: 1000;
        margin-bottom: 0;
      }
      
      /* Add top padding to account for fixed navbar */
      .tab-content {
        padding-top: 70px; /* Adjust based on your navbar height */
        height: calc(100vh - 70px);
        overflow-y: auto;
      }
      
      /* Ensure tab panes fill the container */
      .tab-pane {
        height: 100%;
        padding: 15px;
      }
      
      /* Make images responsive within tabs */
      .tab-pane img {
        max-width: 100%;
        height: auto;
        display: block;
        margin: 0 auto;
      }
      
      .tab-pane figure {
        text-align: center;
        margin: 20px 0;
      }
      
      .tab-pane figcaption {
        font-style: italic;
        color: #666;
        margin-top: 8px;
      }
    "))
                 ),
  tabPanel("HOME", homepage_ui),
  tabPanel("Create Schema", json_ui),
  tabPanel("Enter Example", examples_ui),
  tabPanel("Engineer Prompt", prompt_ui),
  tabPanel("Create Database", random_ui ),
  tabPanel("Create Database ver2", run_ui),
  tabPanel("License",license_ui)
)

server <- function(input, output, session) {
  homepage_server(input, output, session)
  json_server(input, output, session)
  examples_server(input, output, session)
  prompt_server(input, output, session)
  random_server(input, output, session)
  run_server(input, output, session)
  license_server(input, output, session)
}

shinyApp(ui, server)