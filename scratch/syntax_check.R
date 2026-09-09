# scratch/syntax_check.R
files <- c("helpers/db.R", "helpers/nlp.R", "helpers/export.R", 
           "modules/student_portal.R", "modules/faculty_portal.R", "modules/admin_portal.R", "app.R")

for (f in files) {
  cat(sprintf("Checking syntax for %s... ", f))
  res <- parse(f)
  cat("OK!\n")
}
cat("All R files parsed successfully!\n")
