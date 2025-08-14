# server.R - Server Logic
library(shiny)
library(DT)
library(tidyverse)
library(readxl)
library(writexl)
library(ollamar)
library(jsonlite)

options(shiny.maxRequestSize = 60*1024^2)

# Source the LLM extract function
source("r functions/LLM extract function.R")

# Helper functions
`%!in%` <- Negate(`%in%`)

read_excel_allsheets <- function(filename, tibble = FALSE) {
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}

get_ollama_models <- function(ip) {
  tryCatch({
    Sys.setenv(OLLAMA_HOST = paste0(ip, ":11434"))
    models <- list_models()
    return(models$name)
  }, error = function(e) {
    return(NULL)
  })
}

estimate_tokens <- function(text) {
  if(is.null(text) || is.na(text) || text == "") return(0)
  words <- strsplit(text, "\\s+")[[1]]
  word_count <- length(words)
  ceiling(word_count / 0.75)  # Rough token estimate
}

run_server <- function(input, output, session) {
  
  # Reactive values
  values <- reactiveValues(
    data = NULL,
    schema_path = NULL,
    prompt_path = NULL,
    results = NULL,
    processing = FALSE
  )
  
  # Check for default files on startup
  observe({
    if (file.exists("TEMP/current_schema.json")) {
      values$schema_path <- "TEMP/current_schema.json"
      showNotification("Default schema loaded: TEMP/current_schema.json", type = "message")
    }
    
    if (file.exists("TEMP/current_prompt.txt")) {
      values$prompt_path <- "TEMP/current_prompt.txt"
      showNotification("Default prompt loaded: TEMP/current_prompt.txt", type = "message")
    }
  })
  
  # Handle dataset upload
  observeEvent(input$dataset, {
    req(input$dataset)
    
    tryCatch({
      sheets <- excel_sheets(input$dataset$datapath)
      updateSelectInput(session, "selecttab", 
                        choices = sheets, 
                        selected = sheets[1])
    }, error = function(e) {
      showNotification(paste("Error reading Excel file:", e$message), type = "error")
    })
  })
  
  # Handle sheet selection
  observeEvent(input$selecttab, {
    req(input$dataset, input$selecttab)
    
    tryCatch({
      data <- read_excel(input$dataset$datapath, sheet = input$selecttab)
      data <- as.data.frame(data)
      
      # Store data first
      values$data <- data
      
      showNotification(paste("Loaded sheet:", input$selecttab, "with", nrow(data), "rows,", ncol(data), "columns"), type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error reading sheet:", e$message), type = "error")
      values$data <- NULL
    })
  })
  
  # Separate observer to update column choices when data changes
  observeEvent(values$data, {
    if (!is.null(values$data)) {
      col_names <- names(values$data)
      cat("Updating columns:", paste(col_names, collapse = ", "), "\n")
      
      # Clear first, then update
      updateSelectInput(session, "input_column", 
                        choices = character(0))
      
      Sys.sleep(0.1)  # Small delay
      
      updateSelectInput(session, "input_column", 
                        choices = col_names, 
                        selected = col_names[1])
      
      showNotification(paste("Columns available:", paste(col_names[1:min(3, length(col_names))], collapse = ", ")), type = "message")
    } else {
      updateSelectInput(session, "input_column", 
                        choices = c("No data loaded"), 
                        selected = NULL)
      cat("Sent update to input_column with choices:", paste(col_names, collapse = ", "), "\n")
      cat("Current input_column value:", input$input_column, "\n")
    }
  })
  
  # Handle schema upload
  observeEvent(input$schema_file, {
    req(input$schema_file)
    values$schema_path <- input$schema_file$datapath
    showNotification("Schema file uploaded", type = "message")
  })
  
  # Handle prompt upload
  observeEvent(input$prompt_file, {
    req(input$prompt_file)
    values$prompt_path <- input$prompt_file$datapath
    showNotification("Prompt file uploaded", type = "message")
  })
  
  # Update models when IP changes
  observeEvent(input$ip_address, {
    models <- get_ollama_models(input$ip_address)
    if (is.null(models)) {
      updateSelectInput(session, "model", choices = c("Connection failed"))
    } else {
      updateSelectInput(session, "model", choices = models, selected = models[1])
    }
  })
  
  # Token estimation
  output$token_estimate <- renderText({
    req(values$prompt_path, values$data, input$input_column)
    
    # Read prompt
    prompt_text <- tryCatch({
      paste(readLines(values$prompt_path, warn = FALSE), collapse = "\n")
    }, error = function(e) "")
    
    # Get sample text
    sample_text <- ""
    if (!is.null(values$data) && input$input_column %in% names(values$data)) {
      sample_data <- values$data[[input$input_column]]
      if (length(sample_data) > 0) {
        sample_text <- as.character(sample_data[1])
      }
    }
    
    prompt_tokens <- estimate_tokens(prompt_text)
    sample_tokens <- estimate_tokens(sample_text)
    total_tokens <- prompt_tokens + sample_tokens
    
    paste0("Estimated tokens per request: ", total_tokens,
           "\nPrompt: ", prompt_tokens, " | Sample: ", sample_tokens)
  })
  
  # Processing status
  output$processing <- reactive({
    values$processing
  })
  outputOptions(output, "processing", suspendWhenHidden = FALSE)
  
  # Main extraction process
  observeEvent(input$run_extraction, {
    # Validation
    if (is.null(values$data)) {
      showNotification("Please upload and select data first", type = "error")
      return()
    }
    
    if (is.null(values$schema_path) || !file.exists(values$schema_path)) {
      showNotification("Schema file not found. Please upload or check TEMP/current_schema.json", type = "error")
      return()
    }
    
    if (is.null(values$prompt_path) || !file.exists(values$prompt_path)) {
      showNotification("Prompt file not found. Please upload or check TEMP/current_prompt.txt", type = "error")
      return()
    }
    
    if (is.null(input$model) || input$model == "Connection failed") {
      showNotification("Please select a valid model", type = "error")
      return()
    }
    
    # Start processing
    values$processing <- TRUE
    
    tryCatch({
      # Set Ollama host
      Sys.setenv(OLLAMA_HOST = paste0(input$ip_address, ":11434"))
      
      withProgress(message = "Running LLM extraction...", value = 0, {
        
        # Custom progress tracking
        total_rows <- nrow(values$data)
        processed_rows <- 0
        
        # Override cat function to track progress
        original_cat <- cat
        cat <- function(...) {
          text <- paste(..., sep = "")
          if (grepl("Processing \\d+", text)) {
            processed_rows <<- processed_rows + 1
            progress_value <- processed_rows / total_rows
            incProgress(1/total_rows, 
                        detail = paste("Row", processed_rows, "of", total_rows))
            
            # Update progress bar via JavaScript
            session$sendCustomMessage("updateProgress", 
                                      list(percent = progress_value * 100))
          }
          original_cat(...)
        }
        
        # Run LLM extraction
        result <- llm_extract(
          mydata = values$data,
          prompt_path = values$prompt_path,
          format_path = values$schema_path,
          llm_ip_address = paste0("http://", input$ip_address, ":11434"),
          llm_model = input$model,
          input_text_column = input$input_column,
          seed_num = input$seed,
          context_window = input$context_window
        )
        
        # Restore original cat
        cat <- original_cat
        
        values$results <- result
        values$processing <- FALSE
        
        showNotification("Processing complete!", type = "message")
      })
      
    }, error = function(e) {
      values$processing <- FALSE
      showNotification(paste("Error during processing:", e$message), type = "error")
    })
  })
  
  # Status output
  output$status <- renderText({
    if (values$processing) {
      "Processing in progress..."
    } else if (!is.null(values$results)) {
      paste("Processing complete.", nrow(values$results), "rows processed.")
    } else {
      "Ready to process. Please configure settings and run extraction."
    }
  })
  
  # Results table
  output$results_table <- DT::renderDataTable({
    req(values$results)
    
    DT::datatable(
      values$results,
      options = list(
        scrollX = TRUE,
        pageLength = 50,
        dom = 'Bfrtip',
        buttons = list('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons'
    )
  })
  
  # Download handler
  output$download_results <- downloadHandler(
    filename = function() {
      paste0(input$filename, ".xlsx")
    },
    content = function(file) {
      req(values$results)
      write_xlsx(values$results, file)
    }
  )
}
