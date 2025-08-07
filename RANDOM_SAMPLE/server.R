random_server <- function(input, output, session) {
  nested_colnames <- reactiveVal(NULL)
  progress_status <- reactiveVal("Waiting for submission...")
  rv <- reactiveValues(output_data = NULL)
  batch_data <- reactiveVal()
  batch_index <- reactiveVal(1)
  collapsed_batch_prompt <- reactiveVal()
  sampled_n <- reactiveVal()
  full_batch_data <- reactiveVal()
  
  
  get_ollama_models <- function(ip) {
    url <- paste0("http://", ip, ":11434/api/tags")
    res <- try(httr::GET(url), silent = TRUE)
    
    if (inherits(res, "try-error") || httr::status_code(res) != 200) {
      return(NULL)
    }
    
    parsed <- jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
    model_names <- parsed$models$name
    return(model_names)
  }
  
  observeEvent(input$batch_address, {
    models <- get_ollama_models(input$batch_address)
    if (is.null(models)) {
      updateSelectInput(session, "batch_model", choices = c("Connection failed or no models found"))
    } else {
      updateSelectInput(session, "batch_model", choices = models, selected = models[1])
    }
  })
  

  list_files <- list.files("example prompt and schema files",recursive = T)
  updateSelectInput(session, "select_schema", 
                    choices = c("Please select" = "", list_files[grepl("(?i)schema", list_files)]),
                    selected = "")
  updateSelectInput(session, "select_prompt", 
                    choices = c("Please select" = "", list_files[grepl("(?i)prompt", list_files)]),
                    selected = "")
  
  
  observeEvent(input$select_schema, {
    # Check if a schema file is selected, then send the value to input$batch_json
    if (input$select_schema != "") {
      schema_path <- file.path("example prompt and schema files", input$select_schema)
      lines <- readLines(schema_path, warn = FALSE)
      batch_prompt_text <- paste(lines, collapse = "\n")
      collapsed_batch_prompt(batch_prompt_text)
    } 
  })
    
  
  
  
  observeEvent(input$batch_xlsx, {
    req(input$batch_xlsx)
    
    # Check file extension
    ext <- tools::file_ext(input$batch_xlsx$name)
    if (tolower(ext) != "xlsx") {
      showModal(modalDialog(
        title = "Invalid file type",
        "Please upload a valid .xlsx file.",
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
      return()
    }
    
    # Try reading the file
    tryCatch({
      #df <- readxl::read_excel(input$batch_xlsx$datapath, col_names = FALSE)
      df <- readxl::read_excel(input$batch_xlsx$datapath)
      
      if (ncol(df) >= 1) {
        full_batch_data(df)
        
        updateSelectInput(session, "input_column", choices = names(df), selected = names(df)[1])
        
        #batch_index(1)
      } else {
        showNotification("The uploaded Excel file is empty or has no columns.", type = "error")
      }
    }, error = function(e) {
      showModal(modalDialog(
        title = "Error reading Excel file",
        paste("An error occurred while reading the file:", e$message),
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
    })
  })
  
  observeEvent(input$sample_size, {
    # Allow empty input to reset sample size
    if (is.null(input$sample_size) || input$sample_size == "") {
      sampled_n(NULL)
      return()
    }
    sample_size <- suppressWarnings(as.integer(input$sample_size))
    n <- nrow(full_batch_data())  # Use full batch for validation
    
    if (!is.na(sample_size) && sample_size > 0 && sample_size < n) {
      sampled_n(sample_size)
    } else {
      sampled_n(NULL)
      showNotification("Sample size must be a positive integer less than the number of available examples.", type = "error")
    }
  })
  
  
  observe({
    req(full_batch_data())
    data <- full_batch_data()
    n <- nrow(data)
    sample_n <- sampled_n()
    if (!is.null(sample_n) && sample_n > 0 && sample_n < n) {
      # set.seed(1)  
      #batch_data(sample(data, sample_n))
      batch_data(data[sample(n, sample_n),])
    } else {
      batch_data(data)
    }
  })
  

  estimate_batch_tokens <- function(text) {
    words <- strsplit(text, "\\s+")[[1]]
    word_count <- length(words)
    token_estimate <- ceiling(word_count / 0.75)
    list(words = word_count, tokens = token_estimate)
  }
  
  observeEvent(input$batch_prompt, {
    req(input$batch_prompt)
    
    file_name <- input$batch_prompt$name
    file_type <- input$batch_prompt$type
    
    # Check for .txt extension or MIME type
    is_txt <- grepl("\\.txt$", file_name, ignore.case = TRUE) ||
      file_type %in% c("text/plain", "application/octet-stream")
    
    if (!is_txt) {
      showModal(modalDialog(
        title = "Invalid file type",
        "Please upload a valid .txt file.",
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
      return()
    }
    
    tryCatch({
      lines <- readLines(input$batch_prompt$datapath, warn = FALSE)
      batch_prompt_text <- paste(lines, collapse = "\n")
      collapsed_batch_prompt(batch_prompt_text)
    }, error = function(e) {
      showModal(modalDialog(
        title = "Error reading text file",
        paste("An error occurred while reading the prompt file:", e$message),
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
    })
  })
  
  output$batch_word_count <- renderUI({
    prompt_text <- collapsed_batch_prompt()
    req(prompt_text)
    prompt_stats <- estimate_batch_tokens(prompt_text)
    longest_example <- ""
    example_stats <- list(words = 0, tokens = 0)
    examples <- batch_data()[[input$input_column]]
    if (!is.null(examples) && length(examples) > 0) {
      word_counts <- sapply(examples, function(x) length(strsplit(x, "\\s+")[[1]]))
      longest_example <- examples[which.max(word_counts)]
      example_stats <- estimate_batch_tokens(longest_example)
    }
    combined_tokens <- prompt_stats$tokens + example_stats$tokens
    tagList(
      tags$b("Estimated Tokens:"), 
      sprintf(" %d", combined_tokens)
    )
  })
  
  observeEvent(input$submit_batch, {
    req(input$batch_json, collapsed_batch_prompt(), batch_data(), input$batch_model,input$input_column)
    
    batch_schema <- fromJSON(input$batch_json$datapath, simplifyVector = FALSE)
    full_prompt <- collapsed_batch_prompt()
    input_text_column <- input$input_column
    output_column <- input$batch_model
    seed_num <- 1234
    
    # Create a working dataframe
    #input_data <- tibble(!!input_text_column := batch_data())
    input_data <- batch_data()
    # test[[paste0(output_column, "_time")]] <- numeric(nrow(test))
    # 
    messages_list <- list(list(role = "system", content = full_prompt))
    
    withProgress(message = "Running model inference...", value = 0, {
      for (i in seq_len(nrow(input_data))) {
        incProgress(1 / nrow(input_data), detail = paste0("Running row ", i, " of ", nrow(input_data)))
        
        start_time <- Sys.time()
        result <- tryCatch({
          chat(
            host = paste0("http://", input$batch_address, ":11434"),
            model = input$batch_model,
            message = create_messages(
              messages_list,
              list(content = input_data[[input_text_column]][i], role = "user")
            ),
            format = batch_schema,
            output = "text",
            temperature = 0,
            seed = seed_num,
            num_ctx = as.numeric(input$batch_context)
          )
        }, error = function(e) {
          message("Error in row ", i, ": ", conditionMessage(e))
          return(NULL)
        })
        
        end_time <- Sys.time()
        duration_sec <- as.numeric(difftime(end_time, start_time, units = "secs"))
        
        if (length(result) > 0 && !is.null(result)) {
          parsed <- fromJSON(result)
          input_data[[output_column]][i] <- list(parsed$data)
          input_data[[paste0(output_column, "_time")]][i] <- duration_sec
        }
        
        # duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        # if (!is.null(result)) {
        #   parsed <- tryCatch(fromJSON(result), error = function(e) NULL)
        #   if (!is.null(parsed$data)) {
        #     test[[output_column]][i] <- list(as_tibble(parsed$data))
        #   }
        # }
        # 
        # test[[paste0(output_column, "_time")]][i] <- duration
      }
    })
    
    # Process and filter the LLM output
    llm_sym <- sym(output_column)
    output_data <- input_data %>%
      filter(map_chr(!!llm_sym, class) == 'data.frame') %>%
      unique() %>%
      unnest(!!llm_sym, keep_empty = TRUE) %>%
      bind_rows(
        input_data %>%
          filter(map_chr(!!llm_sym, class) != 'data.frame') %>%
          select(-all_of(input$batch_model))
      )
    
    
    
    rv$output_data <- output_data
    progress_status("Model run complete. You may now download results.")
  })
  
  output$download_batch <- downloadHandler(
    filename = function() paste0(input$filename_batch,".xlsx"),
    content = function(file) {
      req(rv$output_data)
      
      # output_column <- input$batch_model
      # 
      # # Unnest the nested model output
      # unnested_df <- rv$test %>%
      #   unnest(cols = all_of(output_column))
      unnested_df <- rv$output_data
      # Write to Excel
      writexl::write_xlsx(unnested_df, path = file)
    }
  )
}