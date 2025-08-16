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
          column(6, fileInput(("empty_examples"), label = list("Upload Examples (.xlsx)",
            bsButton("example_1_info", label = "",
              icon = icon("info", lib = "font-awesome"),
              style = "default", size = "extra-small")
            )
            ))),
        bsPopover("example_1_info", "More Information", 
          content = HTML(paste("Input at least <b>20</b> representative examples as the xlsx file.",
            "Place examples in the first column of an excel file without columns names (data in <b>A1:An</b> with <b>n</b> examples)."
          )),
          "right", trigger = "click",
          options = list(container = "body")
        ),
        h4("Example Text"),
        verbatimTextOutput(("example_text")),
        fluidRow(
          column(6, actionButton(("previous_button"), label = NULL, icon = icon("arrow-left"), style = "width: 100%;")),
          column(6, actionButton(("next_button"), label = NULL, icon = icon("arrow-right"), style = "width: 100%;"))
        ),
        textOutput(("example_counter")),
        tags$hr(),
        textInput(("filename_xlsx"), "Enter file name (without exteion):", value = ""),
        downloadButton(("download_xlsx"), "Download .xslx")
      ),
      
      # Right column
      column(
        width = 4,
        uiOutput(("dynamic_form")),
        actionButton(("add_row"), "Add Row", class = "btn btn-success"),
        actionButton(("remove_row"), "Remove Last Row", class = "btn btn-danger"),
        h4(list("Preview", 
          bsButton("preview_info", label = "",
            icon = icon("info", lib = "font-awesome"),
            style = "default", size = "extra-small")
          )),
        bsPopover("preview_info", "More Information", 
          content = HTML(paste("Input and validation logic for the given example.",
            "To ensure that the accuracy calculations in the next step is valid, all responses must conform to the schema."
          )),
          "right", trigger = "click",
          options = list(container = "body")
        ),
        verbatimTextOutput(("data_output"))
      )
    )
  )

