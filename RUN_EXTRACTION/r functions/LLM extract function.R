library(tidyverse)
library(ollamar)
library(jsonlite)
library(httr2)







llm_extract <- function(
    mydata,
    prompt_txt,
    schema_json,
    llm_ip_address = "http://172.18.227.92:11434",
    llm_model = "phi4",
    input_text_column = "final_diag",
    seed_num = 7,
    context_window = 4000,
    for_webapp=F) {
  # prompt_txt <- readLines(prompt_path, warn = FALSE) %>% paste(collapse = "\n")
  # schema_json <- readLines(format_path, warn = FALSE, encoding = 'UTF-8') %>%
  #   paste(collapse = "\n") %>%
  #   fromJSON(simplifyVector = FALSE)
  
  messages_list <- list(content = prompt_txt, role = "system")
  output_column <- llm_model
  
  if(!for_webapp) {
    pb <- txtProgressBar(min = 0, max = nrow(mydata), style = 3)
  }
  
  # Loop through rows and call LLM
  for (i in 1:nrow(mydata)) {
    
    if (for_webapp) {
      progress$inc(1 / n, detail = paste("Step", i, "of", n))
    } else {
      setTxtProgressBar(pb, i)
    }
    
    
    start_time <- Sys.time()
    
    temp <- tryCatch({
      chat(
        host = llm_ip_address,
        model = llm_model,
        message = create_messages(
          messages_list,
          list(content = mydata[[input_text_column]][i], role = "user")
        ),
        format = schema_json,
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
      parsed <- jsonlite::fromJSON(temp)
      mydata[[output_column]][i] <- list(parsed$data%>%
                                           modify_if(is.null, ~NA) %>%
                                           as.data.frame(stringsAsFactors = FALSE))
      mydata[[paste0(llm_model, "_time")]][i] <- duration_sec
    }
  }
  
  if(!for_webapp) close(pb)
  
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
  
  return(mydata1)
}
# 
# download_github_file <- function(file_name, local_path = "prompt.txt", token = git_hub_token) {
#   # Construct GitHub API URL
#   api_url <- paste0("https://api.github.com/repos/lukealtnether/LLM_APP/contents/", utils::URLencode(file_name, reserved = TRUE))
#   
#   # Get download URL from GitHub API
#   download_url <- request(api_url) %>%
#     req_auth_bearer_token(token) %>%
#     req_perform() %>%
#     resp_body_json() %>%
#     (\(x) x$download_url)()
#   
#   # Download the file using the download URL
#   request(download_url) %>%
#     req_perform(path = local_path)
# }
# 

# Helper function to read Excel sheets
read_excel_allsheets <- function(filename, tibble = FALSE) {
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}

clean_json_response <- function(response) {
  if(is.null(response) || length(response) == 0) return(NULL)
  
  # Remove markdown code blocks - leading and trailing ```
  cleaned <- gsub("^```json\\s*", "", response, perl = TRUE)
  cleaned <- gsub("^```\\s*", "", cleaned, perl = TRUE)
  cleaned <- gsub("\\s*```\\s*$", "", cleaned, perl = TRUE)
  
  # Remove any leading/trailing whitespace
  cleaned <- trimws(cleaned)
  
  # Remove trailing garbage after JSON - find the last } or ] and cut there
  if(grepl("\\}", cleaned)) {
    # Find the last closing brace
    last_brace <- max(gregexpr("\\}", cleaned)[[1]])
    if(last_brace > 0) {
      cleaned <- substr(cleaned, 1, last_brace)
    }
  } else if(grepl("\\]", cleaned)) {
    # Find the last closing bracket for arrays
    last_bracket <- max(gregexpr("\\]", cleaned)[[1]])
    if(last_bracket > 0) {
      cleaned <- substr(cleaned, 1, last_bracket)
    }
  }
  
  return(trimws(cleaned))
}