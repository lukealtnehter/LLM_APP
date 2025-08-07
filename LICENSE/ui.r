license_ui <- fluidPage(
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
      
      /* Make images responsive */
      img {
        max-width: 100%;
        height: auto;
        display: block;
        margin: 0 auto;
      }
      
      /* Style figures */
      figure {
        text-align: center;
        margin: 20px 0;
      }
      
      figcaption {
        font-style: italic;
        color: #666;
        margin-top: 8px;
      }
    ")),
  
  includeMarkdown("license.md")
)