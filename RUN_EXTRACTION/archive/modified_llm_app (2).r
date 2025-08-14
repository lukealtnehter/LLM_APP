# Required packages for the app ----
library(shiny)
library(DT)
library(tidyverse)
library(hablar)
library(readxl)
library(shinycssloaders)
library(shinythemes)
library(htmltools)
library(jsonlite)
library(shinyWidgets)

options(shiny.maxRequestSize = 60*1024^2)

# User defined functions used in this app ----
`%!in%` = Negate(`%in%`)

# Source the LLM extract function
source("r functions/LLM extract function.R")

# Helper function to read Excel sheets
read_excel_allsheets <- function(filename, tibble = FALSE) {
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}

# Helper function to get available models
get_models <- function(url) {
  tryCatch({
    response <- httr::GET(url)
    if(httr::status_code(response) == 200) {
      content <- httr::content(response, as = "parsed")
      model_names <- sapply(content$models, function(x) x$name)
      return(model_names)
    } else {
      return("Connection failed")
    }
  }, error = function(e) {
    return("Connection failed")
  })
}

################################################################

# Load user interface ----
ui <- fluidPage(
  theme = shinytheme("cerulean"),
  
  # Custom CSS for better text display
  tags$head(
    tags$style(HTML("
      .long-text {
        max-width: 300px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
      .preview-box {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 0.25rem;
        padding: 15px;
        margin: 10px 0;
        overflow-y: auto;
        font-family: monospace;
        font-size: 12px;
        white-space: pre-wrap;
        word-wrap: break-word;
      }
      .inline label { 
        display: table-cell; 
        text-align: left; 
        vertical-align: middle; 
      } 
      .inline .form-group {
        display: table-row;
      }
      #filerror {
        background-color: rgba(255,255,0,0.40); 
        color: red; 
        font-size: 20px;
      }
    "))
  ),
  
  # Main content
  sidebarLayout(
    sidebarPanel(
      width = 4,
      
      h5(strong("Upload Data")),
      
      fileInput("dataset2", "Choose an Excel XLS or XLSX File",
                multiple = FALSE,
                accept = c(".xls",".xlsx")),
      
        selectInput("selecttab", "Select the Spreadsheet Tab to Analyze", 
                    choices = NULL, multiple = FALSE),
      
        selectInput("varb", "Select Variable to analyze", 
                    choices = NULL, selected = NULL),
      
      tags$hr(),
      
      h5(strong("LLM Settings")),
      
      div(class = "inline",
          textInput("api", "IP address", value = "172.18.227."),
          selectInput("model_name", "Model", choices = NULL, multiple = FALSE),
          numericInput("seed","Seed", value = 123, min = 1, max = 9999, width = "80px")
      ),
      
      tags$hr(),
      
      h5(strong("Prompt and Schema Configuration")),
      
      # Manual upload options
      fileInput("prompt_file", "Upload Prompt File (optional)",
                accept = c(".txt")),
      
      fileInput("schema_file", "Upload Schema File (optional)",
                accept = c(".json")),
      
      tags$hr(),
      ui <- fluidPage(
        actionBttn(
          inputId = "runllm",
          label = "Run LLM",
          style = "gradient",   # "simple", "fill", "bordered", etc.
          color = "royal",      # "primary", "warning", "danger", "success", or "custom"
          size = "lg"
        )
      )    
    ),
    
    mainPanel(
      width = 8,
      
      # Error messages
      textOutput("filerror"),
      
      
      # Main content using tabs
      tabsetPanel(
        id = "main_tabs",
        type = "tabs",
        tabPanel(
          title = "Data Table",
          value = "data_tab",
          br(),
           withSpinner(DT::dataTableOutput("mytable2"))
        ),
        
        tabPanel(
          title = "Prompt Preview",
          value = "prompt_tab",
          textAreaInput("prompt_display", NULL, value = "",autoresize=T),
          tags$script(HTML("$('#prompt_display').attr('readonly', true);"))
        ),
        
        tabPanel(
          title = "Schema Preview", 
          value = "schema_tab",
          textAreaInput("schema_display", NULL, value = "",autoresize=T),
          tags$script(HTML("$('#schema_display').attr('readonly', true);"))
        )
      )
    )
  )
)


################################ Server Logic ################################

server <- function(session, input, output) {
  
  # Reactive values
  values <- reactiveValues(
    prompt_content = NULL,
    schema_content = NULL,
    current_progress = 0
  )
  
  # Auto-load prompt and schema files from TEMP/ directory
  observe({
    autoload_messages <- c()
    
    # Try to load current_prompt.txt
    if (file.exists("TEMP/current_prompt.txt")) {
      values$prompt_content <- readLines("TEMP/current_prompt.txt", warn = FALSE) %>%
        paste(collapse = "\n")
      autoload_messages <- c(autoload_messages, "Auto-loaded prompt from TEMP/current_prompt.txt")
    }
    
    # Try to load current_schema.json
    if (file.exists("TEMP/current_schema.json")) {
      values$schema_content <- readLines("TEMP/current_schema.json", warn = FALSE, encoding = 'UTF-8') %>%
        paste(collapse = "\n")
      autoload_messages <- c(autoload_messages, "Auto-loaded schema from TEMP/current_schema.json")
    }
    
    # Show notification if files were auto-loaded
    if (length(autoload_messages) > 0) {
      showNotification(paste(autoload_messages, collapse = "\n"), 
                       type = "message", duration = 5)
    }
  })
  
  # Handle manual prompt file upload
  observeEvent(input$prompt_file, {
    req(input$prompt_file)
    values$prompt_content <- readLines(input$prompt_file$datapath, warn = FALSE) %>%
      paste(collapse = "\n")
    showNotification("Prompt file uploaded successfully", type = "message", duration = 3)
  })
  
  # Handle manual schema file upload
  observeEvent(input$schema_file, {
    req(input$schema_file)
    values$schema_content <- readLines(input$schema_file$datapath, warn = FALSE, encoding = 'UTF-8') %>%
      paste(collapse = "\n")
    showNotification("Schema file uploaded successfully", type = "message", duration = 3)
  })
  
  # Update tab selection when Excel file is uploaded
  observeEvent(input$dataset2, {
    req(input$dataset2)
    tryCatch({
      sheets <- excel_sheets(input$dataset2$datapath)
      updateSelectInput(session, "selecttab", choices = sheets, selected = sheets[1])
    }, error = function(e) {
      output$filerror <- renderText("Error reading Excel file. Please check the file format.")
    })
  })
  
  # Load Excel data
  data2 <- reactive({
    req(input$dataset2, input$selecttab)
    tryCatch({
      df <- as.data.frame(read_excel_allsheets(input$dataset2$datapath)[input$selecttab][[1]])
      df %>% mutate_if(is.character, as.factor)
    }, error = function(e) {
      output$filerror <- renderText("Error processing Excel data.")
      return(NULL)
    })
  })
  
  # Update variable selection
  observeEvent(data2(), {
    req(data2())
    updateSelectInput(session, "varb", choices = c("None", colnames(data2())), 
                      selected = NULL)
  })
  
  # Update model selection when IP changes
  observeEvent(input$api, {
    if(nchar(input$api) > 0) {
      models <- get_models(paste0("http://", input$api, ":11434/api/tags"))
      updateSelectInput(session, "model_name", choices = models)
    }
  })
  
  observe({
    if(!is.null(values$prompt_content) && nchar(values$prompt_content) > 0) {
      updateTextAreaInput(session, "prompt_display", value = values$prompt_content)
    } else {
      updateTextAreaInput(session, "prompt_display", 
                          value = "No prompt loaded. Upload a file or place current_prompt.txt in /TEMP/ directory.")
    }
  })
  
  observe({
    if(!is.null(values$schema_content) && nchar(values$schema_content) > 0) {
      updateTextAreaInput(session, "schema_display", value = values$schema_content)
    } else {
      updateTextAreaInput(session, "schema_display", 
                          value = "No schema loaded. Upload a file or place current_schema.json in /TEMP/ directory.")
    }
  })
  
  # Process data with LLM
  filtereddata2 <- eventReactive(input$runllm, {
    
    req(data2(), input$varb, values$prompt_content, values$schema_content, input$model_name)
    
    # Validate inputs
    if(is.null(input$varb) || length(input$varb) == 0 || "None" %in% input$varb) {
      showNotification("Please select at least one variable to analyze.", type = "error")
      return(data2())
    }
    
    if(is.null(values$prompt_content) || is.null(values$schema_content)) {
      showNotification("Please ensure both prompt and schema are loaded.", type = "error")
      return(data2())
    }
    
    withProgress(message = "Processing...", value = 0, {
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Processing...", value = 0)
      
      
      result <- llm_extract(
        mydata = input_data,
        prompt_path = input$prompt_file$datapath %||% "TEMP/current_prompt.txt",
        format_path = input$schema_file$datapath %||% "TEMP/current_schema.json",
        llm_ip_address = paste0("http://", input$api, ":11434"),
        llm_model = input$model_name,
        input_text_column = input_col,
        seed_num = input$seed,
        context_window = 4000
      )
    })
    return(result)
  })
  
  # Render data table with improved visualization
  output$mytable2 <- DT::renderDataTable({
    
    req(data2())
    
    data <- if(input$runllm > 0) filtereddata2() else data2()
    
    if(is.null(data)) return(NULL)
    
    # Create column definitions for long text handling
    col_defs <- list()
    for(i in 1:ncol(data)) {
      if(is.character(data[[i]]) || is.factor(data[[i]])) {
        # Check if column contains long text
        max_length <- max(nchar(as.character(data[[i]])), na.rm = TRUE)
        if(max_length > 50) {
          col_defs <- append(col_defs, list(list(
            targets = i - 1,  # DT uses 0-based indexing
            render = JS("function(data, type, row, meta) {
              if (type === 'display' && data && data.length > 50) {
                return '<span title=\"' + data + '\">' + 
                       data.substr(0, 47) + '...</span>';
              }
              return data;
            }")
          )))
        }
      }
    }
    
    DT::datatable(
      data,
      extensions = c('Buttons', 'Responsive'),
      options = list(
        dom = 'Bfrtip',
        buttons = list(extend = 'excel', title = NULL),
        scrollX = TRUE,
        scrollY = "400px",
        pageLength = 25,
        lengthMenu = c(10, 25, 50, 100),
        columnDefs = col_defs,
        initComplete = JS(
          "function(settings, json) {",
          "$(this.api().table().header()).css({'background-color': '#337ab7', 'color': '#fff'});",
          "}"
        )
      ),
      rownames = FALSE,
      class = 'cell-border stripe hover'
    ) %>%
      DT::formatStyle(
        columns = 1:ncol(data),
        fontSize = '12px'
      )
  })
}

# Run the application
shinyApp(ui = ui, server = server)