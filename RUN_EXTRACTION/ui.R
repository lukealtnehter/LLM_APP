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


# Load user interface ----
run_ui <- fluidPage(
  theme = shinytheme("cerulean"),
  
  # Custom CSS for better text display
  tags$head(
    tags$style(HTML("
      .long-text {
        max-width: 300px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
      .preview-box {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 0.25rem;
        padding: 15px;
        margin: 10px 0;
        overflow-y: auto;
        font-family: monospace;
        font-size: 12px;
        white-space: pre-wrap;
        word-wrap: break-word;
      }
      .inline label { 
        display: table-cell; 
        text-align: left; 
        vertical-align: middle; 
      } 
      .inline .form-group {
        display: table-row;
      }
      #filerror {
        background-color: rgba(255,255,0,0.40); 
        color: red; 
        font-size: 20px;
      }
    "))
  ),
  
  # Main content
  sidebarLayout(
    sidebarPanel(
      width = 4,
      
      h5(strong("Upload Data")),
      
      fileInput("dataset2", "Choose an Excel XLS or XLSX File",
                multiple = FALSE,
                accept = c(".xls",".xlsx")),
      
      selectInput("selecttab", "Select the Spreadsheet Tab to Analyze", 
                  choices = NULL, multiple = FALSE),
      
      selectInput("varb", "Select Variable to analyze", 
                  choices = NULL, selected = NULL),
      
      tags$hr(),
      
      h5(strong("LLM Settings")),
      
      div(class = "inline",
          textInput("api", "IP address", value = "172.18.227."),
          selectInput("model_name", "Model", choices = NULL, multiple = FALSE),
          numericInput("seed","Seed", value = 123, min = 1, max = 9999, width = "80px")
      ),
      
      tags$hr(),
      
      h5(strong("Prompt and Schema Configuration")),
      
      # Manual upload options
      fileInput("prompt_file", "Upload Prompt File (optional)",
                accept = c(".txt")),
      
      fileInput("schema_file", "Upload Schema File (optional)",
                accept = c(".json")),
      
      tags$hr(),
      ui <- fluidPage(
        actionBttn(
          inputId = "runllm",
          label = "Run LLM",
          style = "gradient",   # "simple", "fill", "bordered", etc.
          color = "royal",      # "primary", "warning", "danger", "success", or "custom"
          size = "lg"
        )
      )    
    ),
    
    mainPanel(
      width = 8,
      
      # Error messages
      textOutput("filerror"),
      
      
      # Main content using tabs
      tabsetPanel(
        id = "main_tabs",
        type = "tabs",
        tabPanel(
          title = "Data Table",
          value = "data_tab",
          br(),
          withSpinner(DT::dataTableOutput("mytable2"))
        ),
        
        tabPanel(
          title = "Prompt Preview",
          value = "prompt_tab",
          textAreaInput("prompt_display", NULL, value = "",autoresize=T),
          tags$script(HTML("$('#prompt_display').attr('readonly', true);"))
        ),
        
        tabPanel(
          title = "Schema Preview", 
          value = "schema_tab",
          textAreaInput("schema_display", NULL, value = "",autoresize=T),
          tags$script(HTML("$('#schema_display').attr('readonly', true);"))
        )
      )
    )
  )
)
