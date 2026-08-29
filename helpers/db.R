# helpers/db.R
# Centralised database connection, query, and write helpers for Sentilytics

library(DBI)
library(RSQLite)

DB_PATH <- "data/sentilytics.db"

get_db_con <- function() {
  dbConnect(SQLite(), DB_PATH)
}

# --- AUTH ---
authenticate_user <- function(email, password) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  df <- dbGetQuery(con, sprintf(
    "SELECT * FROM users WHERE email = '%s' AND password_hash = '%s' LIMIT 1",
    gsub("'", "''", email), gsub("'", "''", password)
  ))
  if (nrow(df) == 0) return(NULL)
  as.list(df[1, ])
}

# --- STUDENT QUERIES ---
insert_feedback <- function(student_id, anonymous, faculty_id, aspect, rating, text, sub_ratings = NULL, emotion_tag = "neutral", semester = "Semester 1") {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  sid_val <- if (as.integer(anonymous) == 1) "NULL" else as.character(as.integer(student_id))
  fid_val <- if (is.null(faculty_id) || is.na(faculty_id) || faculty_id == "") "NULL" else as.character(as.integer(faculty_id))
  text_clean <- gsub("'", "''", ifelse(is.na(text) || text == "", "", text))
  sub_val <- if (is.null(sub_ratings) || is.na(sub_ratings)) "NULL" else paste0("'", gsub("'", "''", sub_ratings), "'")
  dbExecute(con, sprintf(
    "INSERT INTO feedback_entries (student_id, faculty_id, anonymous, aspect, rating, text, sub_ratings, emotion_tag, semester) VALUES (%s, %s, %d, '%s', %d, '%s', %s, '%s', '%s')",
    sid_val, fid_val, as.integer(anonymous), aspect, as.integer(rating), text_clean, sub_val, gsub("'", "''", emotion_tag), semester
  ))
}

get_student_feedback <- function(student_id) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, sprintf(
    "SELECT f.aspect, f.rating, f.text, f.semester, f.created_at, u.name AS teacher_name, u.department AS teacher_dept 
     FROM feedback_entries f 
     LEFT JOIN users u ON f.faculty_id = u.id 
     WHERE f.student_id = %d 
     ORDER BY f.created_at DESC",
    as.integer(student_id)
  ))
}

get_faculty_list <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT id, name, department FROM users WHERE role = 'faculty' ORDER BY name ASC")
}

# --- FACULTY QUERIES ---
get_faculty_feedback <- function(faculty_id, aspects = c("teaching", "coursecontent")) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  asp_list <- paste(sprintf("'%s'", aspects), collapse = ", ")
  dbGetQuery(con, sprintf(
    "SELECT aspect, rating, text, semester, created_at FROM feedback_entries WHERE faculty_id = %d AND aspect IN (%s) ORDER BY created_at ASC",
    as.integer(faculty_id), asp_list
  ))
}

# --- ADMIN QUERIES ---
get_all_feedback <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT f.*, u.name AS teacher_name, u.department AS teacher_dept 
    FROM feedback_entries f 
    LEFT JOIN users u ON f.faculty_id = u.id 
    ORDER BY f.created_at DESC
  ")
}

get_aspect_summary <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT aspect,
           SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) AS positive,
           SUM(CASE WHEN rating = 0 THEN 1 ELSE 0 END) AS neutral,
           SUM(CASE WHEN rating = -1 THEN 1 ELSE 0 END) AS negative,
           COUNT(*) AS total
    FROM feedback_entries
    GROUP BY aspect
  ")
}

# --- ALERT SYSTEM ---
get_alerts <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM alerts WHERE dismissed = 0 ORDER BY triggered_at DESC")
}

dismiss_alert <- function(alert_id) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbExecute(con, sprintf("UPDATE alerts SET dismissed = 1 WHERE id = %d", as.integer(alert_id)))
}

check_and_insert_alerts <- function(threshold = 0.30) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  aspects <- c("teaching", "coursecontent", "examination", "labwork", "library_facilities", "extracurricular")
  for (asp in aspects) {
    df <- dbGetQuery(con, sprintf("SELECT rating FROM feedback_entries WHERE aspect = '%s'", asp))
    if (nrow(df) < 5) next
    pos_ratio <- sum(df$rating == 1) / nrow(df)
    if (pos_ratio < threshold) {
      existing <- dbGetQuery(con, sprintf(
        "SELECT id FROM alerts WHERE entity_name = '%s' AND dismissed = 0 LIMIT 1", asp))
      if (nrow(existing) == 0) {
        dbExecute(con, sprintf(
          "INSERT INTO alerts (entity_type, entity_name, avg_neg_score, threshold) VALUES ('aspect', '%s', %.4f, %.4f)",
          asp, pos_ratio, threshold))
      }
    }
  }
}

# --- MULTI-SEMESTER & IMPROVEMENT TREND HELPERS ---
get_semester_department_trends <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT 
      f.semester,
      u.department AS teacher_dept,
      COUNT(*) AS total_responses,
      SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS positive_count,
      SUM(CASE WHEN f.rating = 0 THEN 1 ELSE 0 END) AS neutral_count,
      SUM(CASE WHEN f.rating = -1 THEN 1 ELSE 0 END) AS negative_count,
      ROUND(AVG(CASE WHEN f.rating = 1 THEN 5.0 WHEN f.rating = 0 THEN 3.0 ELSE 1.0 END), 2) AS avg_rating,
      ROUND(CAST(SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS REAL) / COUNT(*) * 100.0, 1) AS pos_pct
    FROM feedback_entries f
    JOIN users u ON f.faculty_id = u.id
    WHERE u.department IS NOT NULL AND u.department != ''
    GROUP BY f.semester, u.department
    ORDER BY f.semester ASC, u.department ASC
  ")
}

get_teacher_improvement_metrics <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT 
      u.id AS teacher_id,
      u.name AS teacher_name,
      u.department AS teacher_dept,
      f.semester,
      COUNT(*) AS total_responses,
      SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS pos_count,
      SUM(CASE WHEN f.rating = -1 THEN 1 ELSE 0 END) AS neg_count,
      ROUND(AVG(CASE WHEN f.rating = 1 THEN 5.0 WHEN f.rating = 0 THEN 3.0 ELSE 1.0 END), 2) AS avg_rating,
      ROUND(CAST(SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS REAL) / COUNT(*) * 100.0, 1) AS pos_pct
    FROM feedback_entries f
    JOIN users u ON f.faculty_id = u.id
    WHERE u.role = 'faculty'
    GROUP BY u.id, u.name, u.department, f.semester
    ORDER BY u.name ASC, f.semester ASC
  ")
}

get_subject_satisfaction_trends <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT 
      f.aspect,
      f.semester,
      COUNT(*) AS total_responses,
      SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS pos_count,
      SUM(CASE WHEN f.rating = -1 THEN 1 ELSE 0 END) AS neg_count,
      ROUND(AVG(CASE WHEN f.rating = 1 THEN 5.0 WHEN f.rating = 0 THEN 3.0 ELSE 1.0 END), 2) AS avg_rating,
      ROUND(CAST(SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS REAL) / COUNT(*) * 100.0, 1) AS pos_pct
    FROM feedback_entries f
    GROUP BY f.aspect, f.semester
    ORDER BY f.aspect ASC, f.semester ASC
  ")
}

get_timely_response_timeline <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT 
      f.semester,
      DATE(f.created_at) AS response_date,
      COUNT(*) AS response_count,
      SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS positive_count,
      SUM(CASE WHEN f.rating = 0 THEN 1 ELSE 0 END) AS neutral_count,
      SUM(CASE WHEN f.rating = -1 THEN 1 ELSE 0 END) AS negative_count
    FROM feedback_entries f
    GROUP BY f.semester, DATE(f.created_at)
    ORDER BY f.created_at ASC
  ")
}


