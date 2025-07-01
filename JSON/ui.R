ui <-  fluidPage(
    titlePanel("JSON Schema Creator"),
    fluidRow(
      column(4,
        textInput(("title"), "Schema Title"),
        textInput(("description"), "Description"),
        selectInput(("schema_type"), "Schema Type", choices = c("Object" = "object", "Array" = "array")),
        
        tags$hr(),
        h4("Add Properties"),
        textInput(("prop_name"), "Property Name"),
        selectInput(("prop_type"), "Property Type", choices = c("Select a type..." = "", "string", "number", "integer")),
        
        conditionalPanel(
          condition = sprintf("input['%s'] != ''", ("prop_type")),
          textAreaInput(("enum_list"), "Enumerations (one per line)", placeholder = "Enter one value per line")
        ),
        
        conditionalPanel(
          condition = sprintf("input['%s'] == 'string'", ("prop_type")),
          selectInput(("format_type"), "String Format", choices = c(
            "None" = "",
            "date-time (2023-04-01T12:00:00Z)" = "date-time",
            "date (2023-04-01)" = "date",
            "time (14:30:00)" = "time",
            "email (user@example.com)" = "email",
            "phone number (123-456-7891)" = "phone",
            "hostname (www.example.com)" = "hostname",
            "ipv4 (192.168.1.1)" = "ipv4",
            "ipv6 (2001:0db8::1)" = "ipv6",
            "uri (https://example.com)" = "uri",
            "uuid (550e8400-e29b-41d4-a716-446655440000)" = "uuid",
            "regex (^[A-Z]{3}-\\d{4}$)" = "regex",
            "byte (U29mdHdhcmU=)" = "byte",
            "binary (01010101)" = "binary",
            "password (masked input)" = "password"
          )),
          textInput(("string_pat"), "Pattern (regex)")
        ),
        
        conditionalPanel(
          condition = sprintf("input['%s'] == 'number' || input['%s'] == 'integer'", ("prop_type"), ("prop_type")),
          textInput(("min_num"), "Minimum"),
          textInput(("max_num"), "Maximum")
        ),
        
        checkboxInput(("ob_req"), "Null not allowed", value = FALSE),
        
        fluidRow(
          column(4,
            actionButton(("add_prop"), "Add", class = "btn btn-success", width = "100%")
          ),
          column(4,
            actionButton(("remove_prop"), "Remove", class = "btn btn-danger", width = "100%")
          )
        )
      ),
      
      column(6,
        h4("Schema Preview"),
        verbatimTextOutput(("json_preview")),
        tags$br(),
        textInput(("filename"), "Enter file name (without extension):", value = ""),
        downloadButton(("download_json"), "Download JSON")
      )
    )
  )

