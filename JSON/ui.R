library(shiny)
library(shinyBS)

json_ui <- fluidPage(
  tags$head(tags$style(
    HTML(
      "
      body {
        background-color: #f8f9fa;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

      .main-header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 25px;
        margin-bottom: 25px;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        text-align: center;
      }

      .schema-type-buttons {
        display: flex;
        gap: 15px;
        margin-bottom: 25px;
      }

      .schema-type-btn {
        flex: 1;
        padding: 20px;
        border: 3px solid #e9ecef;
        border-radius: 12px;
        background: white;
        cursor: pointer;
        transition: all 0.3s ease;
        text-align: center;
        font-size: 20px;
        font-weight: 600;
      }

      .schema-type-btn:hover {
        border-color: #667eea;
        background: #f8f9ff;
      }

      .schema-type-btn.active {
        border-color: #667eea;
        background: linear-gradient(45deg, #667eea, #764ba2);
        color: white;
      }

      .main-header h1 {
        margin: 0;
        font-weight: 300;
        font-size: 24px;
      }

      .main-header p {
        margin: 8px 0 0 0;
        opacity: 0.9;
        font-size: 18px;
      }

      .panel {
        background: white;
        border-radius: 12px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
        padding: 25px;
        margin-bottom: 20px;
        border: none;
      }

      .section-header {
        font-size: 20px;
        font-weight: 600;
        margin-bottom: 20px;
        color: #2c3e50;
        border-bottom: 2px solid #e9ecef;
        padding-bottom: 10px;
      }

      .form-group label {
        font-weight: 600;
        color: #495057;
        margin-bottom: 8px;
        font-size: 16px;
      }

      .form-control, .selectize-input {
        border-radius: 8px;
        border: 2px solid #e9ecef;
        padding: 15px 18px;
        font-size: 16px;
        transition: all 0.3s ease;
      }

      .form-control:focus, .selectize-input.focus {
        border-color: #667eea;
        box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.15);
        outline: none;
      }

      .btn {
        border-radius: 8px;
        font-weight: 600;
        padding: 15px 25px;
        transition: all 0.3s ease;
        border: none;
        font-size: 16px;
      }

      .btn-success {
        background: linear-gradient(45deg, #28a745, #20c997);
        color: white;
      }

      .btn-success:hover {
        background: linear-gradient(45deg, #218838, #1ca085);
        transform: translateY(-1px);
        box-shadow: 0 4px 8px rgba(40, 167, 69, 0.3);
      }

      .btn-danger {
        background: linear-gradient(45deg, #dc3545, #fd7e14);
        color: white;
      }

      .btn-danger:hover {
        background: linear-gradient(45deg, #c82333, #e8610e);
        transform: translateY(-1px);
        box-shadow: 0 4px 8px rgba(220, 53, 69, 0.3);
      }

      .btn-primary {
        background: linear-gradient(45deg, #667eea, #764ba2);
        color: white;
      }

      .btn-primary:hover {
        background: linear-gradient(45deg, #5a6fd8, #6a4190);
        transform: translateY(-1px);
        box-shadow: 0 4px 8px rgba(102, 126, 234, 0.3);
      }

      .help-text {
        font-size: 16px;
        color: #6c757d;
        margin-top: 4px;
        font-style: italic;
      }

      .info-icon {
        color: #667eea;
        margin-left: 5px;
      }

      #json_preview {
        background: #2d3748;
        color: #e2e8f0;
        border-radius: 8px;
        border: none;
        font-family: 'Monaco', 'Consolas', monospace;
        font-size: 16px;
        padding: 20px;
        max-height: 400px;
        overflow-y: auto;
      }

      hr {
        border-top: 2px solid #e9ecef;
        margin: 25px 0;
      }

      .checkbox label {
        font-weight: 500;
      }

      .form-group {
        margin-bottom: 20px;
      }

      .download-section {
        background: #f8f9fa;
        padding: 20px;
        border-radius: 8px;
        margin-top: 20px;
      }

              .download-section h4 {
        color: #495057;
        margin-bottom: 15px;
        font-size: 16px;
              }
.checkbox input[type='checkbox'] {
  margin-top: 2px;
}

.checkbox label {
  display: flex;
  align-items: center;
  gap: 5px;
}
    "
    )
  )),
  
  
  # Schema type selection buttons--------
  div(
    class = "schema-type-buttons",
    div(
      class = "schema-type-btn",
      onclick = "Shiny.setInputValue('schema_type', 'object');",
      "Object Schema",
      br(),
      tags$small("Single record extraction")
    ),
    div(
      class = "schema-type-btn",
      onclick = "Shiny.setInputValue('schema_type', 'array');",
      "Array Schema",
      br(),
      tags$small("Multiple records extraction")
    )
  ),
  
  # Hidden input to maintain compatibility------------------------
  tags$input(id = "schema_type", type = "hidden", value = "object"),
  
  fluidRow(column(
    4,
    div(
      class = "panel",
      div(
        class = "section-header",
        "Add Properties",
        bsButton(
          "add_properties_info",
          label = "",
          icon = icon("info-circle", lib = "font-awesome"),
          style = "link",
          class = "info-icon"
        )
      ),
      
      textInput("prop_name", "Property Name", placeholder = "e.g., customer_name"),
      div(class = "help-text", "Use descriptive names (snake_case recommended)"),
      
      selectInput(
        "prop_type",
        "Property Type",
        choices = c(
          "Select a type..." = "",
          "Text" = "string",
          "Number" = "number",
          "Integer" = "integer"
        )
      ),
      
      # conditional panel for string properties------
      
      conditionalPanel(
        condition = "input.prop_type == 'string'",
        selectInput(
          "string_constraint_type",
          "Choose constraint type:",
          choices = list(
            "No constraints" = "none",
            "Predefined format" = "format",
            "Custom pattern (RegEx)" = "pattern",
            "Allowed values only" = "enum"
          )
          
        ),
        
        # enum ----
        conditionalPanel(
          condition = "input['string_constraint_type'] == 'enum'",
          textAreaInput(
            "enum_list",
            label = div(
              "Allowed Values (one per line)",
              bsButton(
                "enumerations_info",
                label = "",
                icon = icon("info-circle", lib = "font-awesome"),
                style = "link",
                size = "extra-small",
                class = "info-icon"
              )
            ),
            placeholder = "Option 1\nOption 2\nOption 3",
            rows = 3
          ),
          div(class = "help-text", "Leave empty to allow any valid value")
        ),
        # string format and regex pattern ----
        conditionalPanel(
          condition = "input['string_constraint_type'] == 'format'",
          selectInput(
            "format_type",
            label = div(
              "String Format",
              bsButton(
                "format_info",
                label = "",
                icon = icon("info-circle", lib = "font-awesome"),
                style = "link",
                size = "extra-small",
                class = "info-icon"
              )
            ),
            choices = c(
              "None" = "",
              "Date & Time (2023-04-01T12:00:00Z)" = "date-time",
              "Date (2023-04-01)" = "date",
              "Time (14:30:00)" = "time",
              "Email (user@example.com)" = "email",
              "Phone Number (123-456-7891)" = "phone",
              "Website (www.example.com)" = "hostname",
              "IPv4 Address (192.168.1.1)" = "ipv4",
              "IPv6 Address (2001:0db8::1)" = "ipv6",
              "URL (https://example.com)" = "uri",
              "UUID (550e8400-e29b-41d4-a716...)" = "uuid",
              "Regular Expression" = "regex",
              "Base64 (U29mdHdhcmU=)" = "byte",
              "Binary (01010101)" = "binary",
              "Password (masked)" = "password"
            )
          )
        ),
        
        conditionalPanel(
          condition = "input['string_constraint_type'] == 'pattern'",
          textInput(
            "string_pat",
            label = div(
              "Custom Pattern (RegEx)",
              bsButton(
                "pattern_info",
                label = "",
                icon = icon("info-circle", lib = "font-awesome"),
                style = "link",
                size = "extra-small",
                class = "info-icon"
              )
            ),
            placeholder = "^[A-Z]{2,3}-\\d{4}$"
          ),
          div(class = "help-text", "Define your own validation pattern")
        )
      ),
      # conditional panel for number/integer properties------
      
      conditionalPanel(
        condition = "input.prop_type == 'number' || input.prop_type == 'integer'",
        selectInput(
          "num_constraint_type",
          "Choose constraint type:",
          choices = list(
            "No constraints" = "none",
            "Min Max" = "minmax",
            "Allowed values only" = "enum"
          )
          
        ),
        conditionalPanel(
          condition = "input['num_constraint_type'] == 'minmax'",
          fluidRow(column(
            6, textInput("min_num", "Minimum", placeholder = "Min value")
          ), column(
            6, textInput("max_num", "Maximum", placeholder = "Max value")
          )),
          div(class = "help-text", "Set numeric constraints (optional)")
        ),
        conditionalPanel(
          condition = "input['num_constraint_type'] == 'enum'",
          textAreaInput(
            "enum_list",
            label = div(
              "Allowed Values (one per line)",
              bsButton(
                "enumerations_info",
                label = "",
                icon = icon("info-circle", lib = "font-awesome"),
                style = "link",
                size = "extra-small",
                class = "info-icon"
              )
            ),
            placeholder = "Option 1\nOption 2\nOption 3",
            rows = 3
          ),
          div(class = "help-text", "Leave empty to allow any valid value")
        )
      )
    ),
    # null check button------
    checkboxInput(
      "ob_req",
      label = div(
        "Required Field",
        bsButton(
          "null_info",
          label = "",
          icon = icon("info-circle", lib = "font-awesome"),
          style = "link",
          size = "extra-small",
          class = "info-icon"
        )
      ),
      value = FALSE
    ),
    
    fluidRow(column(
      6,
      actionButton(
        "add_prop",
        "Add Property",
        class = "btn btn-success",
        width = "100%",
        icon = icon("plus")
      )
    ), column(
      6,
      actionButton(
        "remove_prop",
        "Remove Last",
        class = "btn btn-danger",
        width = "100%",
        icon = icon("minus")
      )
    ))
  ), column(
    8, div(
      class = "panel",
      div(class = "section-header", "Schema Preview"),
      verbatimTextOutput("json_preview"),
      
      div(class = "download-section", h4("Export Schema"), fluidRow(
        column(
          8,
          textInput(
            "filename",
            "Filename (without extension)",
            value = "",
            placeholder = "my-schema"
          )
        ), column(
          4,
          br(),
          downloadButton(
            "download_json",
            "Download JSON",
            class = "btn btn-primary",
            width = "100%",
            icon = icon("download")
          )
        )
      ))
    )
  )),
  
  # Keep relevant popovers
  bsPopover(
    "add_properties_info",
    "Adding Properties",
    content = HTML(
      "Add the properties of the objects you want to extract. All properties should have some level of formatting. Unconstrained properties are more likely to hallucinate and are highly discouraged."
    ),
    "right",
    trigger = "hover",
    options = list(container = "body")
  ),
  
  bsPopover(
    "enumerations_info",
    "Enumerations",
    content = HTML(
      "Enumerations are a list of possible choices. <b>Left</b> and <b>Right</b> would force the LLM to respond only with <b>Left</b> or <b>Right</b>."
    ),
    "right",
    trigger = "hover",
    options = list(container = "body")
  ),
  
  bsPopover(
    "format_info",
    "String Format",
    content = HTML(
      "If applicable, choose a natively supported string format in JSON. All LLM responses for this property will conform to the format."
    ),
    "right",
    trigger = "hover",
    options = list(container = "body")
  ),
  
  bsPopover(
    "pattern_info",
    "Pattern (RegEx)",
    content = HTML(
      "If applicable, create your own custom string formatting using regular expressions. Start your regular expression with ^ and end with $. To allow <b>upper</b>, <b>posterior</b>, <b>upper lateral</b> <b>mid lateral posterior</b> but never <i>lateral upper</i>, input ^(upper|mid|lower)? ?(medial|lateral)? ?(anterior|posterior|midline)?$. All LLM responses for this property will conform to the format."
    ),
    "right",
    trigger = "hover",
    options = list(container = "body")
  ),
  bsPopover(
    "null_info",
    "Required",
    content = HTML(
      "If checked, this require the large language model to provide a value. If unchecked, the property can be null."
    ),
    "right",
    trigger = "hover",
    options = list(container = "body")
  )
)