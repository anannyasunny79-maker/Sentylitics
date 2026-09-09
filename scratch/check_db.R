con <- DBI::dbConnect(RSQLite::SQLite(), "data/sentilytics.db")
print(DBI::dbGetQuery(con, "SELECT id, name, email, role, department FROM users WHERE role = 'faculty'"))
print(DBI::dbGetQuery(con, "SELECT * FROM courses LIMIT 10"))
DBI::dbDisconnect(con)
