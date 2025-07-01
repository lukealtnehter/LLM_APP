ui <-  fluidPage(
    useShinyjs(),
    titlePanel("Prompt Engineering"),
    
    tags$style(HTML("
      #example_check {
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
    
    tags$hr(),
    
    fluidRow(
      column(
        width = 8,
        fluidRow(
          column(6, fileInput(("json_file"), "Upload JSON Schema (.json)")),
          column(6, uiOutput("example_file_ui"))
        ),
        tags$hr(),
        textInput(("id_column"), "ID Column", value = ""),
        fluidRow(
          column(3, textInput(("llm_address"), "BIOHPC node", value = "")),
          column(3, selectInput(("llm_model"), "Model", choices = c("Need to specify IP address first"))),
          column(3, textInput(("llm_context"), "Context window", value = "4000")),
          column(3, uiOutput(("word_count_info")))
        )
      ),
      
      column(
        width = 4,
        column(width = 6,
          h4("Average time"),
          verbatimTextOutput(("avg_time")),
          h4("Observations"),
          tableOutput(("obs_acc"))),
        column(width = 6,
          h4("Variable Accuracy"),
          tableOutput(("prop_acc")),
          h4("Total Accuracy"),
          verbatimTextOutput(("total_accuracy"))
          )
        
      )
    ),
    
    tags$hr(),
    
    fluidRow(
      column(
        width = 4,
        h4("Prompt"),
        uiOutput(("dynamic_prompt_inputs")),
        actionButton(("submit_query"), "Submit", class = "btn btn-success")
      ),
      column(
        width = 5,
        h4("Example"),
        verbatimTextOutput(("example_check")),
        fluidRow(
          column(6, actionButton(("previous_button"), label = NULL, icon = icon("arrow-left"), style = "width: 100%;")),
          column(6, actionButton(("next_button"), label = NULL, icon = icon("arrow-right"), style = "width: 100%;"))
        )
      ),
      column(
        width = 3,
        h4("Differences"),
        tableOutput(("differences_df")),
        verbatimTextOutput(("omissssion_ex")),
        verbatimTextOutput(("hallucinations_ex")),
        h4("LLM Output"),
        tableOutput(("llm_output")),
        h4("Key"),
        tableOutput(("key_output"))
      )
    ),
    
    tags$hr(),
    
    textInput(("filename_prompt"), "Enter file name (without exteion):", value = ""),
    downloadButton(("download_prompt"), "Download prompt"),
  )

