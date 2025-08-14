library(shiny)
library(DT)

run_ui <- tagList(
  tags$head(
    tags$script(HTML("
      Shiny.addCustomMessageHandler('updateProgress', function(data) {
        $('#progress-bar').css('width', data.percent + '%');
      });
    "))
  ),
  
  fluidPage(
    titlePanel("LLM Tester"),
    
    sidebarLayout(
      sidebarPanel(
        h4("Data Upload"),
        fileInput("dataset", "Upload Excel File", 
                  accept = c(".xls", ".xlsx")),
        
        selectInput("selecttab", "Select Sheet", 
                    choices = c("Upload file first"), 
                    selected = NULL),
        
        selectInput("input_column", "Select Column for Extraction", 
                    choices = c("Select sheet first"), 
                    selected = NULL),
        
        hr(),
        
        h4("Files"),
        fileInput("schema_file", "Upload Schema (.json)", 
                  accept = ".json"),
        
        fileInput("prompt_file", "Upload Prompt (.txt)", 
                  accept = ".txt"),
        
        hr(),
        
        h4("LLM Settings"),
        textInput("ip_address", "IP Address", 
                  value = "172.18.227.92"),
        
        selectInput("model", "Model", 
                    choices = c("Enter IP first"), 
                    selected = NULL),
        
        numericInput("context_window", "Context Window", 
                     value = 4000, min = 1000, max = 32000),
        
        numericInput("seed", "Seed", 
                     value = 123, min = 1, max = 9999),
        
        hr(),
        
        h4("Processing"),
        verbatimTextOutput("token_estimate"),
        
        actionButton("run_extraction", "Run LLM Extraction", 
                     class = "btn-primary"),
        
        br(), br(),
        
        textInput("filename", "Output Filename", 
                  value = "llm_results"),
        
        downloadButton("download_results", "Download Results", 
                       class = "btn-success")
      ),
      
      mainPanel(
        verbatimTextOutput("status"),
        
        conditionalPanel(
          condition = "output.processing == true",
          div(
            h4("Processing..."),
            div(id = "progress-container", 
                style = "width: 100%; background-color: #f0f0f0; border-radius: 4px;",
                div(id = "progress-bar", 
                    style = "width: 0%; height: 20px; background-color: #007bff; border-radius: 4px; transition: width 0.3s;")
            )
          )
        ),
        
        br(),
        
        DT::dataTableOutput("results_table")
      )
    )
  )
)