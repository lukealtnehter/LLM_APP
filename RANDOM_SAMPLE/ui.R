ui <-  fluidPage(
  useShinyjs(),
  titlePanel("Run a sample or entire batch"),
  
  tags$hr(),
  
  fluidRow(
    column(3, fileInput(("batch_json"), "Upload JSON Schema (.json)")),
    column(3, fileInput("batch_prompt", "Upload Prompt (.txt)")),
    column(3, fileInput(("batch_xlsx"), "Upload Batch (.xlsx)")),
    column(1, textInput("sample_size", "Sample Size"))
  ),
  tags$hr(),
  fluidRow(
    column(2, textInput(("batch_address"), "BIOHPC node", value = "172.18.227.")),
    column(3, selectInput(("batch_model"), "Model", choices = c("Need to specify IP address first"))),
    column(2, textInput(("batch_context"), "Context window", value = "4000")),
    column(2, uiOutput(("batch_word_count")))
  ),
  actionButton(("submit_batch"), "Submit", class = "btn btn-success"),
  tags$hr(),
  textInput(("filename_batch"), "Enter file name (without exteion):", value = ""),
  downloadButton(("download_batch"), "Download Run"),
)