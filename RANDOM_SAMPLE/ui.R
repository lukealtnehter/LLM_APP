ui <- fluidPage(
  useShinyjs(),
  titlePanel("Run a Sample or Entire Batch"),
  tags$hr(),
  
  fluidRow(
    column(6,
           tags$h5("Schema & Prompt"),
           fluidRow(
             column(6, fileInput("batch_json", "Upload Schema (.json)")),
             column(6, fileInput("batch_prompt", "Upload Prompt (.txt)"))
           ),
           fluidRow(
             column(6, selectInput("select_schema", "Or Select Existing Schema", choices = NULL, selected = NULL)),
             column(6, selectInput("select_prompt", "Or Select Existing Prompt", choices = NULL, selected = NULL))
           )
    ),
    column(3,
           tags$h5("Batch"),
           fileInput("batch_xlsx", "Upload Batch (.xlsx)"),
           textInput("sample_size", "Sample Size")
    )
  ),
  
  tags$hr(),
  
  fluidRow(
    column(2, textInput("batch_address", "BIOHPC node", value = "172.18.227.")),
    column(3, selectInput("batch_model", "Model", choices = c("Need to specify IP address first"))),
    column(3, selectInput("input_column", "Input Column", choices = c("Need to upload Batch first"))),
    column(2, textInput("batch_context", "Context Window", value = "4000")),
    column(2, uiOutput("batch_word_count"))
  ),
  
  tags$hr(),
  
  fluidRow(
    column(3, actionButton("submit_batch", "Submit", class = "btn btn-success")),
    column(5, textInput("filename_batch", "Enter file name (without extension):", value = "")),
    column(2, downloadButton("download_batch", "Download Run"))
  )
)
