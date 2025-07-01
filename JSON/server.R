server <- function(input, output, session) {
    prop_order <- reactiveVal(character(0))
    schema <- reactiveValues(
      title = NULL,
      description = NULL,
      properties = list()
    )
    
    observe({
      schema$title <- input$title
      schema$description <- input$description
    })
    
    observeEvent(input$add_prop, {
      req(input$prop_name)
      prop_def <- list(type = input$prop_type)
      
      if (input$prop_type != "" && nzchar(input$enum_list)) {
        enum_vals <- strsplit(input$enum_list, "\n")[[1]]
        if (input$prop_type %in% c("number", "integer")) {
          enum_vals <- as.numeric(enum_vals)
        } 
        prop_def$enum <- enum_vals
      }
      
      if (input$prop_type == "string") {
        if (!is.null(input$format_type) && input$format_type != "") {
          prop_def$format <- input$format_type
        }
        if (nzchar(input$string_pat)) {
          prop_def$pattern <- input$string_pat
        }
      }
      
      if (input$prop_type %in% c("number", "integer")) {
        if (nzchar(input$min_num)) prop_def$minimum <- as.numeric(input$min_num)
        if (nzchar(input$max_num)) prop_def$maximum <- as.numeric(input$max_num)
      }
      
      if (!input$ob_req) {
        prop_def <- list(
          anyOf = list(
            prop_def,
            list(type = "null")
          )
        )
      }
      
      schema$properties[[input$prop_name]] <- prop_def
      prop_order(c(prop_order(), input$prop_name))
      
      updateTextInput(session, "prop_name", value = "")
      updateSelectInput(session, "prop_type", selected = "")
      updateTextAreaInput(session, "enum_list", value = "")
      updateTextInput(session, "string_pat", value = "")
      updateSelectInput(session, "format_type", selected = "")
      updateTextInput(session, "min_num", value = "")
      updateTextInput(session, "max_num", value = "")
      updateCheckboxInput(session, "ob_req", value = FALSE)
    })
    
    observeEvent(input$remove_prop, {
      current_order <- prop_order()
      if (length(current_order) > 0) {
        last_prop <- tail(current_order, 1)
        schema$properties[[last_prop]] <- NULL
        prop_order(head(current_order, -1))
      }
    })
    
    render_schema <- reactive({
      req(input$schema_type)
      required_props <- prop_order()
      
      object_schema <- list(
        type = "object",
        properties = schema$properties
      )
      
      # Include 'required' only if there are required properties
      if (length(required_props) > 0) {
        object_schema$required <- required_props
      }
      
      list(
        title = schema$title,
        description = schema$description,
        type = "object",
        properties = list(
          data = if (input$schema_type == "object") {
            object_schema
          } else if (input$schema_type == "array") {
            list(
              type = "array",
              items = object_schema
            )
          }
        ),
        required = list("data")
      )
    })
    
    output$json_preview <- renderPrint({
      toJSON(render_schema(), pretty = TRUE, auto_unbox = TRUE)
    })
    
    output$download_json <- downloadHandler(
      filename = function() {
        paste0(input$filename, ".json")
      },
      content = function(file) {
        write(toJSON(render_schema(), pretty = TRUE, auto_unbox = TRUE), file)
      }
    )
}
