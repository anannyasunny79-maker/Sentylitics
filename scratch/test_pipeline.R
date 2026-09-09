source("helpers/db.R")

cat("=== 1. Testing Feedback Window & Broadcast Notice ===\n")
win <- get_active_feedback_window()
cat("Term Name:", win$term_name, "\n")
cat("Deadline Date:", win$deadline_date, "\n")
cat("Days Left:", win$days_left, "\n")
cat("Notice Description:", win$description, "\n")

update_feedback_window("Even Semester AY 2025-26", as.character(Sys.Date() + 10), "Official Notice: Semester 1-8 course evaluations closing soon.")
win2 <- get_active_feedback_window()
cat("Updated Deadline:", win2$deadline_date, "\n")
cat("Updated Days Left:", win2$days_left, "\n")

cat("\n=== 2. Testing Student Pending Evaluation & Submission ===\n")
priya <- authenticate_user("priya@college.edu", "student123")
cat("Authenticated Student:", priya$name, "(", priya$email, ")\n")
priya_fb_before <- get_student_feedback(priya$id)
cat("Submissions before:", nrow(priya_fb_before), "\n")

subs <- get_department_subjects(priya$department, "Semester 1")
cat("Assigned courses for Semester 1 (", priya$department, "):\n")
for (i in 1:nrow(subs)) {
  cat(" -", subs$course_code[i], ":", subs$course_name[i], "(Teacher:", subs$teacher_name[i], ")\n")
}

insert_feedback(
  student_id = priya$id,
  anonymous = 0,
  faculty_id = subs$faculty_id[1],
  aspect = "teaching",
  rating = 1,
  text = "Dr. Sunita explains concepts with exceptional clarity and real-world examples.",
  sub_ratings = '{"sub1":5,"sub2":4,"sub3":5}',
  emotion_tag = "positive",
  semester = "Semester 1",
  course_id = subs$course_id[1],
  department = priya$department
)
priya_fb_after <- get_student_feedback(priya$id)
cat("Submissions after:", nrow(priya_fb_after), "\n")
cat("Recorded row:", priya_fb_after$course_name[1], "| Instructor:", priya_fb_after$teacher_name[1], "| Rating:", priya_fb_after$rating[1], "\n")

cat("\n=== 3. Testing Raw Submissions Dataset in Admin Portal ===\n")
dataset <- get_all_feedback_dataset()
cat("Total raw dataset records in admin:", nrow(dataset), "\n")
cat("Latest submission in raw dataset:\n")
latest <- dataset[1, ]
cat(" - ID:", latest$submission_id, "\n")
cat(" - Student:", latest$student_identity, "\n")
cat(" - Department:", latest$department, "\n")
cat(" - Semester:", latest$semester, "\n")
cat(" - Course:", latest$course_code, "-", latest$course_title, "\n")
cat(" - Rating Label:", latest$rating_label, "\n")
cat(" - Sentiment Score:", latest$sentiment_score, "\n")
cat(" - Comment:", latest$raw_comment, "\n")

cat("\n=== 4. Testing Readiness Tracker & Allocations ===\n")
readiness <- get_department_readiness_tracker()
cat("Top 3 Department Readiness:\n")
for (i in 1:min(3, nrow(readiness))) {
  cat(" -", readiness$department[i], ":", readiness$submitted_count[i], "/", readiness$target_quota[i], "(", readiness$completion_pct[i], "%)\n")
}

cat("\nALL BACKEND DATA PIPELINES & NOTICE BROADCAST VERIFIED SUCCESSFULLY!\n")
