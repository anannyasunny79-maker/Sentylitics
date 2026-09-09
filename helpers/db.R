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
    "SELECT * FROM users WHERE LOWER(email) = LOWER('%s') AND password_hash = '%s' LIMIT 1",
    gsub("'", "''", email), gsub("'", "''", password)
  ))
  if (nrow(df) == 0) return(NULL)
  as.list(df[1, ])
}

register_user <- function(name, email, password, department, semester = "Semester 1", role = "student") {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  
  email_clean <- gsub("'", "''", tolower(trimws(email)))
  # Check if email exists
  exists_df <- dbGetQuery(con, sprintf(
    "SELECT id FROM users WHERE LOWER(email) = '%s' LIMIT 1",
    email_clean
  ))
  if (nrow(exists_df) > 0) {
    return(list(success = FALSE, message = "An account with this email address already exists."))
  }
  
  name_clean  <- gsub("'", "''", trimws(name))
  pass_clean  <- gsub("'", "''", trimws(password))
  dept_clean  <- gsub("'", "''", trimws(department))
  sem_clean   <- gsub("'", "''", trimws(semester))
  role_clean  <- gsub("'", "''", trimws(role))
  
  res <- dbExecute(con, sprintf(
    "INSERT INTO users (name, email, role, department, semester, password_hash) VALUES ('%s', '%s', '%s', '%s', '%s', '%s')",
    name_clean, email_clean, role_clean, dept_clean, sem_clean, pass_clean
  ))
  
  if (res > 0) {
    new_user <- dbGetQuery(con, sprintf(
      "SELECT * FROM users WHERE LOWER(email) = '%s' LIMIT 1",
      email_clean
    ))
    return(list(success = TRUE, user = as.list(new_user[1, ])))
  } else {
    return(list(success = FALSE, message = "Database error: Could not register user."))
  }
}

# --- STUDENT QUERIES ---
insert_feedback <- function(student_id, anonymous, faculty_id, aspect, rating, text, sub_ratings = NULL, emotion_tag = "neutral", semester = "Semester 1", course_id = NULL, department = NULL) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  sid_val <- if (as.integer(anonymous) == 1) "NULL" else as.character(as.integer(student_id))
  fid_val <- if (is.null(faculty_id) || is.na(faculty_id) || faculty_id == "") "NULL" else as.character(as.integer(faculty_id))
  cid_val <- if (is.null(course_id) || is.na(course_id) || course_id == "") "NULL" else as.character(as.integer(course_id))
  dept_val <- if (is.null(department) || is.na(department) || department == "") "NULL" else paste0("'", gsub("'", "''", department), "'")
  text_clean <- gsub("'", "''", ifelse(is.na(text) || text == "", "", text))
  sub_val <- if (is.null(sub_ratings) || is.na(sub_ratings)) "NULL" else paste0("'", gsub("'", "''", sub_ratings), "'")
  dbExecute(con, sprintf(
    "INSERT INTO feedback_entries (student_id, faculty_id, course_id, department, anonymous, aspect, rating, text, sub_ratings, emotion_tag, semester) VALUES (%s, %s, %s, %s, %d, '%s', %d, '%s', %s, '%s', '%s')",
    sid_val, fid_val, cid_val, dept_val, as.integer(anonymous), aspect, as.integer(rating), text_clean, sub_val, gsub("'", "''", emotion_tag), semester
  ))
}

get_student_feedback <- function(student_id) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, sprintf(
    "SELECT f.id, f.aspect, f.rating, f.text, f.sub_ratings, f.emotion_tag, f.semester, f.created_at, 
            u.name AS teacher_name, u.department AS teacher_dept,
            c.course_code, c.course_name
     FROM feedback_entries f 
     LEFT JOIN users u ON f.faculty_id = u.id 
     LEFT JOIN courses c ON f.course_id = c.id
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

get_faculty_feedback_all <- function(faculty_id) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, sprintf(
    "SELECT f.id, f.aspect, f.rating, f.text, f.sub_ratings, f.emotion_tag, f.semester, f.created_at,
            f.course_id, c.course_code, c.course_name
     FROM feedback_entries f
     LEFT JOIN courses c ON f.course_id = c.id
     WHERE f.faculty_id = %d ORDER BY f.created_at ASC",
    as.integer(faculty_id)
  ))
}

# --- ADMIN QUERIES ---
get_all_feedback <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT f.*, 
           u.name AS teacher_name, 
           u.department AS teacher_dept,
           c.course_code, 
           c.course_name,
           s.name AS student_name
    FROM feedback_entries f 
    LEFT JOIN users u ON f.faculty_id = u.id 
    LEFT JOIN courses c ON f.course_id = c.id
    LEFT JOIN users s ON f.student_id = s.id
    ORDER BY f.created_at DESC
  ")
}

get_all_feedback_dataset <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT f.id AS submission_id,
           f.created_at AS timestamp,
           CASE WHEN f.anonymous = 1 THEN 'Anonymous [Verified Student]' ELSE COALESCE(s.name, 'Student #' || f.student_id) END AS student_identity,
           COALESCE(f.department, s.department, u.department, 'Engineering') AS department,
           f.semester,
           COALESCE(c.course_code, 'GEN100') AS course_code,
           COALESCE(c.course_name, 'General Academic') AS course_title,
           COALESCE(u.name, 'Department Faculty') AS faculty_instructor,
           f.aspect AS dimension,
           f.rating,
           CASE WHEN f.rating = 1 THEN 'Positive (4-5)' WHEN f.rating = 0 THEN 'Neutral (3)' ELSE 'Negative (1-2)' END AS rating_label,
           CASE WHEN f.rating = 1 THEN 0.85 WHEN f.rating = 0 THEN 0.05 ELSE -0.75 END AS sentiment_score,
           COALESCE(f.emotion_tag, 'neutral') AS emotion,
           f.sub_ratings,
           f.text AS raw_comment
    FROM feedback_entries f
    LEFT JOIN users s ON f.student_id = s.id
    LEFT JOIN users u ON f.faculty_id = u.id
    LEFT JOIN courses c ON f.course_id = c.id
    ORDER BY f.id DESC
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
      COALESCE(f.department, u.department, 'Engineering') AS teacher_dept,
      COUNT(*) AS total_responses,
      SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS positive_count,
      SUM(CASE WHEN f.rating = 0 THEN 1 ELSE 0 END) AS neutral_count,
      SUM(CASE WHEN f.rating = -1 THEN 1 ELSE 0 END) AS negative_count,
      ROUND(AVG(CASE WHEN f.rating = 1 THEN 5.0 WHEN f.rating = 0 THEN 3.0 ELSE 1.0 END), 2) AS avg_rating,
      ROUND(CAST(SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS REAL) / COUNT(*) * 100.0, 1) AS pos_pct
    FROM feedback_entries f
    LEFT JOIN users u ON f.faculty_id = u.id
    GROUP BY f.semester, COALESCE(f.department, u.department, 'Engineering')
    ORDER BY f.semester ASC, teacher_dept ASC
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

# --- NOTICE & DEADLINE MANAGEMENT ---
get_active_feedback_window <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  res <- dbGetQuery(con, "SELECT * FROM feedback_windows WHERE is_active = 1 ORDER BY id DESC LIMIT 1")
  if (nrow(res) == 0) {
    return(list(
      id = 1,
      term_name = "Even Semester AY 2025-26",
      start_date = as.character(Sys.Date() - 14),
      deadline_date = as.character(Sys.Date() + 7),
      days_left = 7,
      description = "Official Institutional Notice: End-of-semester course and teaching evaluations are active. All students are required to submit feedback for their assigned subjects before the portal deadline.",
      is_active = 1
    ))
  }
  dl <- tryCatch(as.Date(res$deadline_date[1]), error = function(e) Sys.Date() + 7)
  days_left <- as.integer(dl - Sys.Date())
  list(
    id = res$id[1],
    term_name = res$term_name[1],
    start_date = res$start_date[1],
    deadline_date = res$deadline_date[1],
    days_left = max(0, days_left),
    description = if (is.na(res$description[1]) || res$description[1] == "") "Official Institutional Notice: End-of-semester course evaluations are active. All students are requested to complete their submissions before the deadline." else res$description[1],
    is_active = res$is_active[1]
  )
}

update_feedback_window <- function(term_name, deadline_date, description = "") {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  term_clean <- gsub("'", "''", trimws(term_name))
  dl_clean   <- gsub("'", "''", trimws(deadline_date))
  desc_clean <- gsub("'", "''", trimws(description))
  
  res <- dbGetQuery(con, "SELECT id FROM feedback_windows ORDER BY id DESC LIMIT 1")
  if (nrow(res) > 0) {
    dbExecute(con, sprintf(
      "UPDATE feedback_windows SET term_name = '%s', deadline_date = '%s', description = '%s', is_active = 1 WHERE id = %d",
      term_clean, dl_clean, desc_clean, res$id[1]
    ))
  } else {
    dbExecute(con, sprintf(
      "INSERT INTO feedback_windows (term_name, start_date, deadline_date, description, is_active) VALUES ('%s', '%s', '%s', '%s', 1)",
      term_clean, as.character(Sys.Date()), dl_clean, desc_clean
    ))
  }
  return(TRUE)
}

get_department_subjects <- function(department, semester) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dept_clean <- gsub("'", "''", department)
  sem_clean  <- gsub("'", "''", semester)
  dbGetQuery(con, sprintf("
    SELECT c.id AS course_id, c.course_code, c.course_name, c.credits, c.department, c.semester,
           u.id AS faculty_id, u.name AS teacher_name, u.email AS teacher_email
    FROM courses c
    LEFT JOIN teacher_assignments ta ON c.id = ta.course_id
    LEFT JOIN users u ON ta.faculty_id = u.id
    WHERE c.department = '%s' AND c.semester = '%s'
    ORDER BY c.course_code ASC
  ", dept_clean, sem_clean))
}

get_teacher_assigned_subjects <- function(faculty_id) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, sprintf("
    SELECT c.id AS course_id, c.course_code, c.course_name, c.department, c.semester, c.credits,
           COUNT(f.id) AS total_feedback,
           ROUND(AVG(CASE WHEN f.rating = 1 THEN 5.0 WHEN f.rating = 0 THEN 3.0 ELSE 1.0 END), 2) AS avg_rating,
           ROUND(CAST(SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS REAL) / NULLIF(COUNT(f.id), 0) * 100.0, 1) AS pos_pct
    FROM teacher_assignments ta
    JOIN courses c ON ta.course_id = c.id
    LEFT JOIN feedback_entries f ON f.course_id = c.id
    WHERE ta.faculty_id = %d
    GROUP BY c.id, c.course_code, c.course_name, c.department, c.semester, c.credits
    ORDER BY c.semester ASC
  ", as.integer(faculty_id)))
}

get_department_readiness_tracker <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  
  targets <- data.frame(
    department = c(
      "Computer Science & Engineering",
      "Artificial Intelligence and Data Science",
      "Electronics & Communication Engineering",
      "Electrical & Electronics Engineering",
      "Robotics and Automation",
      "Electronics & Biomedical Engineering",
      "Civil Engineering",
      "Mechanical Engineering"
    ),
    target_quota = c(600, 520, 500, 480, 420, 400, 450, 500),
    stringsAsFactors = FALSE
  )
  
  actuals <- dbGetQuery(con, "
    SELECT department, COUNT(*) AS submitted_count
    FROM feedback_entries
    WHERE department IS NOT NULL AND department != ''
    GROUP BY department
  ")
  
  merged <- merge(targets, actuals, by = "department", all.x = TRUE)
  merged$submitted_count[is.na(merged$submitted_count)] <- 0
  merged$pending_count <- pmax(0, merged$target_quota - merged$submitted_count)
  merged$completion_pct <- round(merged$submitted_count / merged$target_quota * 100, 1)
  
  merged$status <- ifelse(merged$completion_pct >= 95, "Ready",
                   ifelse(merged$completion_pct >= 50, "In Progress", "Not Ready Yet"))
  
  merged[order(merged$completion_pct, decreasing = TRUE), ]
}

get_all_feedback_with_courses <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT f.*, 
           u.name AS teacher_name, 
           u.department AS teacher_dept,
           c.course_code, 
           c.course_name
    FROM feedback_entries f 
    LEFT JOIN users u ON f.faculty_id = u.id 
    LEFT JOIN courses c ON f.course_id = c.id
    ORDER BY f.created_at DESC
  ")
}

get_department_feedback <- function(dept) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dept_clean <- gsub("'", "''", dept)
  dbGetQuery(con, sprintf("
    SELECT f.id, f.aspect, f.rating, f.text, f.semester, f.created_at,
           u.id AS teacher_id, u.name AS teacher_name,
           c.course_code, c.course_name
    FROM feedback_entries f
    LEFT JOIN users u ON f.faculty_id = u.id
    LEFT JOIN courses c ON f.course_id = c.id
    WHERE f.department = '%s' OR u.department = '%s' OR c.department = '%s'
    ORDER BY f.created_at ASC
  ", dept_clean, dept_clean, dept_clean))
}

get_all_faculty_subject_allocations <- function() {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT u.id AS faculty_id, u.name AS faculty_name, u.department,
           c.id AS course_id, c.course_code, c.course_name, c.semester, c.credits,
           COUNT(f.id) AS total_feedback,
           ROUND(AVG(CASE WHEN f.rating = 1 THEN 5.0 WHEN f.rating = 0 THEN 3.0 ELSE 1.0 END), 2) AS avg_rating,
           ROUND(CAST(SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS REAL) / NULLIF(COUNT(f.id), 0) * 100.0, 1) AS pos_pct
    FROM users u
    JOIN teacher_assignments ta ON u.id = ta.faculty_id
    JOIN courses c ON ta.course_id = c.id
    LEFT JOIN feedback_entries f ON f.course_id = c.id
    WHERE u.role = 'faculty'
    GROUP BY u.id, u.name, u.department, c.id, c.course_code, c.course_name, c.semester, c.credits
    ORDER BY u.department ASC, u.name ASC, c.semester ASC
  ")
}
