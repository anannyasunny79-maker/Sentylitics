# install_packages.R
# Script to install CRAN dependencies for College Feedback Sentiment Tool

options(repos = c(CRAN = "https://cloud.r-project.org"))

required_packages <- c(
  "shiny", "shinythemes", "shinydashboard", "shinyjs",
  "plotly", "ggplot2", "wordcloud2",
  "caret", "e1071", "kernlab", "randomForest",
  "tidytext", "tokenizers", "tm", "stringr", "textclean", "textstem",
  "DBI", "RPostgres", "readxl", "jsonlite"
)

# Function to check and install missing packages
install_if_missing <- function(packages) {
  missing_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing_packages) > 0) {
    message("Installing missing packages: ", paste(missing_packages, collapse = ", "))
    install.packages(missing_packages, dependencies = TRUE)
  } else {
    message("All packages are already installed!")
  }
}

message("Starting installation of packages...")
install_if_missing(required_packages)
message("Package installation completed!")
