# run_app.R — Startup script for other computers
# Installs missing dependencies automatically and runs the Shiny app

required_packages <- c("shiny", "shinyjs", "bslib", "ggplot2", "plotly", "DT", "e1071", "nnet", "DBI", "RSQLite")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if (length(missing_packages) > 0) {
  message("Installing missing packages: ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages, repos = "https://cloud.r-project.org/")
}

message("Launching Sentilytics...")
shiny::runApp(".", host = "127.0.0.1", port = 7860, launch.browser = TRUE)
