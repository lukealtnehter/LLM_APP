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
library(ollamar)

options(shiny.maxRequestSize = 60*1024^2)

# User defined functions used in this app ----
`%!in%` <- Negate(`%in%`)

# Source the LLM extract function (if it exists)
if(file.exists("r functions/LLM extract function.R")) {
  source("r functions/LLM extract function.R")
}

# Helper function to read all Excel sheets
read_excel_allsheets <- function(filename) {
  sheets <- excel_sheets(filename)
  result <- lapply(sheets, function(x) read_excel(filename, sheet = x))
  names(result) <- sheets
  return(result)
}

run_server <- function(input, output, session) {
  
  # Reactive values
  values <- reactiveValues(
    prompt_content = NULL,
    schema_content = NULL
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
    writeLines(values$prompt_content, "TEMP/current_prompt.txt")
    showNotification("Prompt file uploaded successfully", type = "message", duration = 3)
  })
  
  # Handle manual schema file upload
  observeEvent(input$schema_file, {
    req(input$schema_file)
    values$schema_content <- readLines(input$schema_file$datapath, warn = FALSE, encoding = 'UTF-8') %>%
      paste(collapse = "\n")
    #save file to TEMP directory
    file.copy(input$schema_file$datapath, "TEMP/current_schema.json", overwrite = TRUE)
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
    if(nchar(input$api) >= 10) { # More flexible IP validation
      tryCatch({
        models <- list_models(host = paste0("http://", input$api, ":11434"))$name
        updateSelectInput(session, "model_name", choices = models)
      }, error = function(e) {
        showNotification("Could not connect to Ollama server", type = "warning")
      })
    }
  })
  
  # Update prompt display
  observe({
    if(!is.null(values$prompt_content) && nchar(values$prompt_content) > 0) {
      updateTextAreaInput(session, "prompt_display", value = values$prompt_content)
    } else {
      updateTextAreaInput(session, "prompt_display", 
                          value = "No prompt loaded. Upload a file or place current_prompt.txt in /TEMP/ directory.")
    }
  })
  
  # Update schema display
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
    
    req(data2(), input$varb, input$model_name)
    
    # Validate inputs
    if(is.null(input$varb) || length(input$varb) == 0 || "None" %in% input$varb) {
      showNotification("Please select at least one variable to analyze.", type = "error")
      return(data2())
    }
    
    if(is.null(values$prompt_content) || is.null(values$schema_content)) {
      showNotification("Please ensure both prompt and schema are loaded.", type = "error")
      return(data2())
    }
    
    mydata <- data2()
    n <- nrow(mydata)
    
    withProgress(message = "Processing...", value = 0, {
      
      # LLM parameters
      prompt_txt <- readLines("TEMP/current_prompt.txt", warn = FALSE) %>% paste(collapse = "\n")
      schema_r <- readLines("TEMP/current_schema.json", warn = FALSE, encoding = 'UTF-8') %>%
        paste(collapse = "\n") %>%
        fromJSON(simplifyVector = FALSE)
      llm_ip_address <- paste0("http://", input$api, ":11434")
      llm_model <- input$model_name
      input_text_column <- input$varb
      seed_num <- input$seed
      context_window <- 4000
      
      messages_list <- list(content = prompt_txt, role = "system")
      output_column <- llm_model
      
      # Loop through rows and call LLM
      for (i in 1:n) {
        
        incProgress(1/n, detail = paste("Processing row", i, "of", n))
        
        start_time <- Sys.time()
        
        temp <- tryCatch({
          chat(
            host = llm_ip_address,
            model = llm_model,
            messages = create_messages(
              messages_list,
              list(content = as.character(mydata[[input_text_column]][i]), role = "user")
            ),
            format = schema_r,
            output = "text",
            temperature = 0,
            seed = seed_num,
            num_ctx = context_window
          )
        }, error = function(e) {
          message("Error during LLM call on row ", i, ": ", conditionMessage(e))
          return(NULL)
        })
        
        end_time <- Sys.time()
        duration_sec <- as.numeric(difftime(end_time, start_time, units = "secs"))
        
        if (length(temp) > 0 && !is.null(temp)) {
          #temp <- clean_json_response(temp)
          parsed <- jsonlite::fromJSON(temp)
          mydata[[output_column]][i] <- list(parsed$data %>%
                                               modify_if(is.null, ~NA) %>%
                                               as.data.frame(stringsAsFactors = FALSE))
          mydata[[paste0(llm_model, "_time")]][i] <- duration_sec
        }
      }
      
      # Process and filter the LLM output
      llm_sym <- sym(llm_model)
      mydata1 <- mydata %>%
        filter(map_chr(!!llm_sym, class) == 'data.frame') %>%
        unique() %>%
        unnest(!!llm_sym, keep_empty = TRUE) %>%
        bind_rows(
          mydata %>%
            filter(map_chr(!!llm_sym, class) != 'data.frame') %>%
            select(-all_of(llm_model))
        )
      
    })
    
    return(mydata1)
  })
  
  # Render data table with improved visualization
  output$mytable2 <- DT::renderDataTable({
    
    print_data <- if(input$runllm > 0) {
      filtereddata2()
    } else {
      data2()
    }
    
    if(is.null(print_data)) return(NULL)
    
    # Create column definitions for long text handling
    col_defs <- list()
    for(i in 1:ncol(print_data)) {
      if(is.character(print_data[[i]]) || is.factor(print_data[[i]])) {
        # Check if column contains long text
        max_length <- max(nchar(as.character(print_data[[i]])), na.rm = TRUE)
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
      print_data,
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
        columns = 1:ncol(print_data),
        fontSize = '12px'
      )
  })
}