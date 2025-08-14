library(shiny)
library(DT)

run_ui <- fluidPage(
  useShinyjs(),
  # Sidebar with inputs for loading a .csv or excel file ----
  sidebarLayout(
    sidebarPanel(
      
      tags$head(
        tags$style(type="text/css", ".inline label{ display: table-cell; text-align: left; vertical-align: middle; } 
                 .inline .form-group{display: table-row;}")
      ),
      
      h5(strong("Upload Data")),
      
      fileInput("dataset2", "Choose an Excel XLS or XLSX File",
                multiple = FALSE,
                accept = c(".xls",".xlsx")),
      
      
      uiOutput("column_selector")),
      
      # #List boxes for Excel tab selection ----
      # selectInput("selecttab", "Select the Spreadsheet Tab to Analyze", c("Need to upload a file"), multiple = FALSE),
      # 
      # selectInput("varb", "Select Variable to analyze", c("Need to upload a file"), multiple = T, selected = NULL),
      # 
      #add line separator
      tags$hr(),
      
      h5(strong("LLM Settings")),
      tags$div(
        class = "inline",
        textInput("api", "IP address", value = "172.18.227."),
        
        selectInput("llm", "Model", c("Need to specify IP address first"), multiple = FALSE),
        
        #number input for random seed title and input in the same line
        numericInput("seed","Seed", value = 123, min = 1, max = 9999,width = "80px"),
        
        #number slider for temperature, default at 0, add explanation text at either end
        sliderInput("temp", tagList("Temperature", br(), 
                                    span("0 = deterministic;  2 = creative", style = "font-weight: normal;")), 
                    min = 0, max = 2, value = 0, step = 0.1)),
      
      
      tags$hr(),
      
      #large text box input
      textAreaInput("question", "Enter a question (user prompt)",width='100%',height = '100%'),
      textAreaInput("system", "Enter Instructions (system prompt)",width='100%',height = '100%', 
                    value = "answer the question with only 'Yes' or 'No', do not include any other character in the response.  If none of these options are mentioned in the report, respond with 'not mentioned' and nothing else. The response should immediately present the answer without any introductory text, symbols or explanation afterwards."),
      
      #add button for run llm
      actionButton("runllm", "Run LLM")
    ),
    
    mainPanel(
      
      # Formatting for too many file uploads error ----
      tags$style(type='text/css', '#filerror {background-color: rgba(255,255,0,0.40); color: red; font-size: 20px;}'), 
      textOutput("filerror"),
      
      h4(strong('Your Uploaded Table')),
      
      
      #TableOutput("mytable")
      withSpinner(dataTableOutput("mytable2"))
      
    )
  )
)
