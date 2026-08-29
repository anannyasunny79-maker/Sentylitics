lib_path <- file.path(Sys.getenv("USERPROFILE"), "R", "library")
dir.create(lib_path, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib_path, .libPaths()))
cat("Library path:", lib_path, "\n")

pkgs <- c("shiny", "shinyjs", "bslib", "plotly", "DBI", "RSQLite", "DT",
          "caret", "e1071", "randomForest", "tidytext", "tokenizers", "tm",
          "stringr", "textclean", "textstem", "ggplot2", "wordcloud2",
          "readxl", "jsonlite", "kernlab")

missing_pkgs <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)]
cat("Packages to install:", paste(missing_pkgs, collapse = ", "), "\n")

if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs,
                   lib        = lib_path,
                   repos      = "https://cloud.r-project.org",
                   dependencies = TRUE,
                   quiet      = FALSE)
}
cat("Setup complete!\n")
