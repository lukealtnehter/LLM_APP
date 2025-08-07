examples_ui <-  
  fluidPage(
    useShinyjs(),
    titlePanel("Example Data Entry"),
    
    tags$style(HTML("
      #example_text {
        white-space: pre-wrap;
        word-wrap: break-word;
        max-height: 400px;
        overflow-y: auto;
        border: 1px solid #ddd;
        padding: 8px;
        background-color: #f9f9f9;
        border-radius: 4px;
      }
    ")),
    
    fluidRow(
      # Left column
      column(
        width = 8,
        fluidRow(
          column(6, fileInput(("schema_file"), "Upload JSON Schema (.json/.txt)")),
          column(6, fileInput(("empty_examples"), "Upload Examples (.xlsx)"))
        ),
        h4("Example Text"),
        verbatimTextOutput(("example_text")),
        fluidRow(
          column(6, actionButton(("previous_button"), label = NULL, icon = icon("arrow-left"), style = "width: 100%;")),
          column(6, actionButton(("next_button"), label = NULL, icon = icon("arrow-right"), style = "width: 100%;"))
        ),
        textOutput(("example_counter")),
        tags$hr(),
        textInput(("filename_rds"), "Enter file name (without exteion):", value = ""),
        downloadButton(("download_rds"), "Download RDS for next step"),
        tags$hr(),
        textInput(("filename_xlsx"), "Enter file name (without exteion):", value = ""),
        downloadButton(("download_xlsx"), "Download XLSX for preview")
      ),
      
      # Right column
      column(
        width = 4,
        uiOutput(("dynamic_form")),
        actionButton(("add_row"), "Add Row", class = "btn btn-success"),
        actionButton(("remove_row"), "Remove Last Row", class = "btn btn-danger"),
        h4("Preview"),
        verbatimTextOutput(("data_output"))
      )
    )
  )

