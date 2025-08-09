#install all packages here

required_packages <- unique(c(
  "shiny",
  "DT",
  "tidyverse",
  "readxl",
  "shinycssloaders",
  "dplyr",
  "shinythemes",
  "htmltools",
  "gtsummary",
  "gt",
  "ollamar",
  "shiny", "jsonlite", "shinyjs", "jsonvalidate",
  "readxl", "writexl", "tidyverse", "ollamar",
  "httr2", "arsenal", "shinyBS"
))

# Function to check and install packages

install_if_missing <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    install.packages(package)
  }
}
# Install all required packages
invisible(lapply(required_packages, install_if_missing))
