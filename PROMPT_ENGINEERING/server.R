prompt_server <- function(input, output, session) {
    nested_colnames <- reactiveVal(NULL)
    nested_coltypes <- reactiveVal()
    rv <- reactiveValues(test = NULL)
    
    output$example_file_ui <- renderUI({
      fileInput(("example_file"), "Upload Completed Examples (.rds)")
    })
    
    observeEvent(input$example_file, {
      req(input$example_file)
      
      ext <- tools::file_ext(input$example_file$name)
      if (tolower(ext) != "rds") {
        showModal(modalDialog(
          title = "Invalid file type",
          "Please upload a valid .rds file.",
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        
        # Reset file input
        output$example_file_ui <- renderUI({
          fileInput("example_file", "Upload Example RDS File")
        })
        return()
      }
      
      tryCatch({
        df <- readRDS(input$example_file$datapath)
        
        if (!("data" %in% names(df)) || !is.data.frame(df$data[[1]])) {
          showNotification("Invalid RDS structure: 'data' column with nested data frames is required.", type = "error")
          return()
        }
        
        first_nested <- df$data[[1]]
        nested_colnames(names(first_nested))
        
      }, error = function(e) {
        showModal(modalDialog(
          title = "Error reading file",
          paste("The uploaded file could not be read as a valid .rds file:", e$message),
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        
        # Reset file input
        output$example_file_ui <- renderUI({
          fileInput("example_file", "Upload Example RDS File")
        })
      })
    })
    
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
    
    observeEvent(input$llm_address, {
      models <- get_ollama_models(input$llm_address)
      if (is.null(models)) {
        updateSelectInput(session, "llm_model", choices = c("Connection failed or no models found"))
      } else {
        updateSelectInput(session, "llm_model", choices = models, selected = models[1])
      }
    })

    output$dynamic_prompt_inputs <- renderUI({
      cols <- nested_colnames()
      if (is.null(cols)) return(NULL)
      tagList(
        textAreaInput("general_info", "General Information", rows = 3, width = "100%"),
        lapply(cols, function(colname) {
          textAreaInput(inputId = paste0("col_", colname), label = colname, rows = 2, width = "100%")
        })
      )
    })
    
    collapsed_prompt <- reactive({
      req(nested_colnames())
      prompt_texts <- c()
      if (!is.null(input$general_info) && nzchar(trimws(input$general_info))) {
        prompt_texts <- c(prompt_texts, paste0("General Information: ", input$general_info))
      }
      for (colname in nested_colnames()) {
        val <- input[[paste0("col_", colname)]]
        if (!is.null(val) && nzchar(trimws(val))) {
          prompt_texts <- c(prompt_texts, paste0(colname, ": ", val))
        }
      }
      paste(prompt_texts, collapse = "\n\n")
    })
    
    estimate_tokens <- function(text) {
      words <- strsplit(text, "\\s+")[[1]]
      word_count <- length(words)
      token_estimate <- ceiling(word_count / 0.75)
      list(words = word_count, tokens = token_estimate)
    }
    
    output$word_count_info <- renderUI({
      prompt_text <- collapsed_prompt()
      req(prompt_text)
      prompt_stats <- estimate_tokens(prompt_text)
      longest_example <- ""
      example_stats <- list(words = 0, tokens = 0)
      if (!is.null(input$example_file)) {
        df <- readRDS(input$example_file$datapath)
        if ("examples" %in% names(df)) {
          word_counts <- sapply(df$examples, function(x) length(strsplit(x, "\\s+")[[1]]))
          longest_example <- df$examples[which.max(word_counts)]
          example_stats <- estimate_tokens(longest_example)
        }
      }
      combined_tokens <- prompt_stats$tokens + example_stats$tokens
      tagList(tags$b("Estimated Tokens:"), sprintf(" %d", combined_tokens))
    })
    
    output$download_prompt <- downloadHandler(
      filename = function() {
        fname <- input$filename_prompt
        if (is.null(fname) || fname == "") {
          fname <- "prompt"
        }
        paste0(fname, ".txt")
      },
      content = function(file) {
        writeLines(collapsed_prompt(), file)
      }
    )

    output$avg_time <- renderText({
      if (!is.null(rv$test)) {
        time_col <- paste0(input$llm_model, "_time")
        avg <- mean(rv$test[[time_col]], na.rm = TRUE)
        paste0(round(avg, 2), " seconds")
      } else {
        ""  
      }
    })
    
    output$obs_acc <- renderTable({
      req(rv$summary_table)
      rv$summary_table
    }, rownames = FALSE, striped = FALSE, hover = TRUE)
    
    output$prop_acc <- renderTable({
      req(rv$variable_summary)
      rv$variable_summary
    }, rownames = FALSE, striped = FALSE, hover = TRUE)
    
    output$total_accuracy <- renderPrint({
      req(rv$total_accuracy)
      cat(paste0(rv$total_accuracy, "%\n"))
    })
    
    observeEvent(input$submit_query, {
      req(input$example_file, input$json_file, nested_colnames())
      test <- readRDS(input$example_file$datapath)
      schema_r <- jsonlite::fromJSON(input$json_file$datapath, simplifyVector = FALSE)
      
      prompt_texts <- c()
      if (!is.null(input$general_info) && nzchar(trimws(input$general_info))) {
        prompt_texts <- c(prompt_texts, paste0("General Information: ", input$general_info))
      }
      for (colname in nested_colnames()) {
        val <- input[[paste0("col_", colname)]]
        if (!is.null(val) && nzchar(trimws(val))) {
          prompt_texts <- c(prompt_texts, paste0(colname, ": ", val))
        }
      }
      full_prompt <- paste(prompt_texts, collapse = "\n\n")
      
      input_text_column <- "examples"
      output_column <- input$llm_model
      seed_num <- 1234
      
      empty_nested <- as.data.frame(setNames(rep(list(character()), length(nested_colnames())), nested_colnames()))
      test[[output_column]] <- replicate(nrow(test), empty_nested[0, ], simplify = FALSE)
      test[[paste0(output_column, "_time")]] <- numeric(nrow(test))
      
      messages_list <- list(list(role = "system", content = full_prompt))
      total <- nrow(test)
      
      withProgress(message = "Running model inference...", value = 0, {
        for (i in seq_len(total)) {
          incProgress(1 / total, detail = paste0("Running row ", i, " of ", total))
          start_time <- Sys.time()
          
          result <- tryCatch({
            chat(
              host = paste0("http://", input$llm_address, ":11434"),
              model = input$llm_model,
              message = create_messages(
                messages_list,
                list(content = test[[input_text_column]][i], role = "user")
              ),
              format = schema_r,
              output = "text",
              temperature = 0,
              seed = seed_num,
              num_ctx = as.numeric(input$llm_context)
            )
          }, error = function(e) {
            message("Error in row ", i, ": ", conditionMessage(e))
            return(NULL)
          })
          
          end_time <- Sys.time()
          duration <- as.numeric(difftime(end_time, start_time, units = "s"))
          
          if (!is.null(result)) {
            parsed <- tryCatch(fromJSON(result), error = function(e) NULL)
            if (!is.null(parsed$data)) {
              test[[output_column]][i] <- list(parsed$data)
            }
          }
          
          test[[paste0(output_column, "_time")]][i] <- duration
        }
      })
      
      progress_status("Model run complete. You may now download results.")
      
      llm_fixed <- test %>%
        select(examples, all_of(output_column)) %>%
        unnest(cols = all_of(output_column)) %>%
        group_by(examples) %>%
        nest(!!sym(output_column) := -examples) %>%
        ungroup()
      
      # Merge fixed LLM output back into the original test
      test <- test %>%
        select(-all_of(output_column)) %>%
        left_join(llm_fixed, by = "examples")
      
      # Accuracy analysis
      llm_model <- input$llm_model
      id_column <- input$id_column
      
      llm_run_filtered <- test %>%
        select(examples, all_of(llm_model)) %>%
        unnest(cols = all_of(llm_model))
      
      llm_output <- llm_run_filtered %>%
        select(-examples)
      
      key_filtered <- test %>% 
        select(examples, data) %>% 
        unnest(cols = data)
      
      by_vars <- c("examples")
      
      if (nzchar(id_column)) by_vars <- c(by_vars, id_column)
      
      results <- pmap(
        list(test$data, test[[llm_model]]),
        function(key_filtered, llm_run_filtered) {
          comp <- comparedf(llm_run_filtered, key_filtered, by = id_column, int.as.num = TRUE)
          
          diffs_df <- diffs(comp) %>%
            select(-row.x, -row.y, -var.x) %>%
            rename(
              variable = var.y, 
              llm = values.x,
              key = values.y
            ) %>%
            select(all_of(id_column), everything())
          
          hallucinations_count <- nrow(comp$frame.summary$unique[[1]])
          omissions_count <- nrow(comp$frame.summary$unique[[2]])
          
          list(
            differences = diffs_df,
            hallucinations = hallucinations_count,
            omissions = omissions_count
          )
        }
      )
      
      # Add new columns to complete_df
      test$differences     <- map(results, "differences")
      test$hallucinations  <- map_int(results, "hallucinations")  
      test$omissions       <- map_int(results, "omissions")
      
      comparison <- comparedf(llm_run_filtered, key_filtered, by = by_vars, int.as.num = TRUE)
      
      total_differences <- diffs(comparison, by.var = TRUE) %>%
        select(-var.x, -NAs) %>%
        rename(variable = var.y) %>%
        mutate(accuracy = (round((1 - (n / nrow(llm_run_filtered))) * 100, 2)))
      
      
      hallucinations <- nrow(comparison$frame.summary$unique[[1]])
      omissions <- nrow(comparison$frame.summary$unique[[2]])
      llm_obs <- comparison$frame.summary$nrow[1]
      total_mistakes <- (sum(total_differences$n) + (omissions + hallucinations)*ncol(llm_output))
      total_accuracy <- (round((1 - ((total_mistakes)/ (nrow(llm_output) * ncol(llm_output))))*100, 2))
      
      
      
      rv$summary_table <- data.frame(Metric = c("Queries", "Hallucinations", "Omissions"), Value = c(llm_obs, hallucinations, omissions))
      rv$variable_summary <- total_differences
      rv$total_accuracy <- total_accuracy
      rv$test <- test
      
    })
    
    # -----------Analysis
    example_index <- reactiveVal(1)
    
    observeEvent(input$next_button, {
      req(rv$test)
      current <- example_index()
      if (current < nrow(rv$test)) example_index(current + 1)
    })
    
    observeEvent(input$previous_button, {
      req(rv$test)
      current <- example_index()
      if (current > 1) example_index(current - 1)
    })
    
    current_row <- reactive({
      req(test())
      test()[example_index(), ]
    })
    
    output$example_check <- renderPrint({
      req(rv$test)
      idx <- example_index()
      rv$test$examples[idx]
    })
    
    output$differences_df <- renderTable({
      req(rv$test)
      idx <- example_index()
      diffs <- rv$test$differences[[idx]]
      
      if (is.null(diffs) || nrow(diffs) == 0) {
        return(NULL)
      } else {
        diffs
      }
    }, striped = FALSE, hover = TRUE, bordered = TRUE, rownames = FALSE)
    
    output$omissssion_ex <- renderPrint({
      req(rv$test)
      idx <- example_index()
      omissions <- rv$test$omissions[idx]
      cat("Omissions:", omissions, "\n")
    })
    
    output$hallucinations_ex <- renderPrint({
      req(rv$test)
      idx <- example_index()
      halluc <- rv$test$hallucinations[idx]
      cat("Hallucinations:", halluc, "\n")
    })
    
    output$llm_output <- renderTable({
      req(rv$test, input$llm_model)
      idx <- example_index()
      llm_df <- rv$test[[input$llm_model]][[idx]]
      
      if (is.null(llm_df) || nrow(llm_df) == 0) {
        return(NULL)
      } else {
        return(llm_df)
      }
    }, rownames = FALSE, striped = FALSE, hover = TRUE, bordered = TRUE)
    
    output$key_output <- renderTable({
      req(rv$test)
      idx <- example_index()
      key_df <- rv$test$data[[idx]]
      
      if (is.null(key_df) || nrow(key_df) == 0) {
        return(NULL)
      } else {
        return(key_df)
      }
    }, rownames = FALSE, striped = FALSE, hover = TRUE, bordered = TRUE)
}

