con <- DBI::dbConnect(RSQLite::SQLite(), "data/sentilytics.db")
fac <- DBI::dbGetQuery(con, "SELECT id, name, email, department FROM users WHERE role = 'faculty' ORDER BY department, id")
print(fac)
DBI::dbDisconnect(con)
