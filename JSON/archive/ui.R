json_ui <- fluidPage(
  titlePanel("JSON Schema Creator"),
  fluidRow(
    column(4,
      textInput("title", "Schema Title"),
      textInput("description", "Description"),
      selectInput("schema_type", label = list(
        "Schema Type",
        bsButton("schema_type_info", label = "",
          icon = icon("info", lib = "font-awesome"),
          style = "default", size = "extra-small")),
        choices = c("Object" = "object", "Array" = "array")
      ),
      bsPopover("schema_type_info", "More Information", 
        content = HTML("<b>Object</b> schemas extract a single row (object) of information from each unstructured text. <b>Array</b> schemas should be used when multiple rows (objects) could be extracted from a single unstructured text."
          ),
        "right", trigger = "hover",
        options = list(container = "body")
        ),
      tags$hr(),
      h4(list(
        "Add Properties",
        bsButton("add_properties_info", label = "",
          icon = icon("info", lib = "font-awesome"),
          style = "default", size = "extra-small"))
        ),
      bsPopover("add_properties_info", "More Information", 
        content = HTML("Add the properties of the objects you want to extract. All properties should have some level of formatting. Unconstrained properties are more likely to hallucinate and are highly discouraged."),
        "right", trigger = "hover",
        options = list(container = "body")
      ),
      textInput("prop_name", "Property Name"),
      selectInput("prop_type", "Property Type",
        choices = c("Select a type..." = "", "string", "number", "integer")),
      conditionalPanel(
        condition = "input['prop_type'] != ''",
        textAreaInput("enum_list", label = list(
          "Enumerations (one per line)",
          bsButton("enumerations_info", label = "",
            icon = icon("info", lib = "font-awesome"),
            style = "default", size = "extra-small")),
          placeholder = "Enter one value per line")
      ),
      bsPopover("enumerations_info", "More Information", content = HTML(
        "Enumerations are a list of possibe choices. <b>Left</b> and <b>Right</b> would force the LLM to resond only with <b>Left</b> or <b>Right</b>."),
        "right", trigger = "hover",
        options = list(container = "body")
      ),
      conditionalPanel(
        condition = "input['prop_type'] == 'string'",
        selectInput("format_type", label = list("String Format",
          bsButton("format_info", label = "",
            icon = icon("info", lib = "font-awesome"),
            style = "default", size = "extra-small")),
          choices = c(
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
          "password (masked input)" = "password")
        ),
        bsPopover("format_info", "More Information", content = HTML("If applicable, choose a natively supported string format in JSON. All LLM responses for this property will conform to the format."),
          "right", trigger = "hover",
          options = list(container = "body")
        ),
        textInput("string_pat", label = list("Pattern (regex)",
          bsButton("pattern_info", label = "",
            icon = icon("info", lib = "font-awesome"),
            style = "default", size = "extra-small")
          )
      ),
        bsPopover("pattern_info", "More Information", content = HTML("If applicable, create your own custom string formatting using regular expressions. Start your regular expression with ^ and end with $. To allow <b>upper</b>, <b>posterior</b>, <b>upper lateral</b> <b>mid lateral posterior</b> but never <i>lateral upper</i>, input ^(upper|mid|lower)? ?(medial|lateral)? ?(anterior|posterior|midline)?$. All LLM responses for this property will conform to the format."),
          "right", trigger = "hover",
          options = list(container = "body")
        )),
      conditionalPanel(
        condition = "input['prop_type'] == 'number' || input['prop_type'] == 'integer'",
        textInput("min_num", "Minimum"),
        textInput("max_num", "Maximum")
      ),
      checkboxInput("ob_req", "Null not allowed", value = FALSE),
      fluidRow(
        column(4,
          actionButton("add_prop", "Add", class = "btn btn-success", width = "100%")
        ),
        column(4,
          actionButton("remove_prop", "Remove", class = "btn btn-danger", width = "100%")
        )
      )
    ),
    column(6,
      h4("Schema Preview"),
      verbatimTextOutput("json_preview"),
      tags$br(),
      textInput("filename", "Enter file name (without extension):", value = ""),
      downloadButton("download_json", "Download JSON")
    )
  )
)
