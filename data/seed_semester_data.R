# data/seed_semester_data.R
# Generates ~1,050 realistic feedback entries per semester across 8 semesters (Sem 1 to Sem 8)
# Total records: ~8,400 feedback entries covering all 8 college departments and 6 aspects

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
})

set.seed(123)

DB_PATH <- "data/sentilytics.db"
con     <- dbConnect(SQLite(), DB_PATH)
dbExecute(con, "PRAGMA journal_mode=WAL")

faculty_df <- dbGetQuery(con, "SELECT id, name, department FROM users WHERE role = 'faculty'")
student_df <- dbGetQuery(con, "SELECT id FROM users WHERE role = 'student'")

if (nrow(faculty_df) == 0 || nrow(student_df) == 0) {
  dbDisconnect(con)
  stop("Users not found. Run db_setup.R first.")
}

aspects <- c("teaching", "coursecontent", "examination", "labwork",
             "library_facilities", "extracurricular")

# 8 Semesters across 4 Academic Years
semesters <- list(
  list(name = "Semester 1", start = "2022-08-01", end = "2022-12-15"),
  list(name = "Semester 2", start = "2023-01-10", end = "2023-05-25"),
  list(name = "Semester 3", start = "2023-08-01", end = "2023-12-15"),
  list(name = "Semester 4", start = "2024-01-10", end = "2024-05-25"),
  list(name = "Semester 5", start = "2024-08-01", end = "2024-12-15"),
  list(name = "Semester 6", start = "2025-01-10", end = "2025-05-25"),
  list(name = "Semester 7", start = "2025-08-01", end = "2025-12-15"),
  list(name = "Semester 8", start = "2026-01-10", end = "2026-05-25")
)

TARGET_PER_SEMESTER <- 1050

dept_profiles <- list(
  "Computer Science & Engineering"       = list(pos = 0.72, neg = 0.12),
  "Artificial Intelligence and Data Science" = list(pos = 0.70, neg = 0.14),
  "Electronics & Communication Engineering" = list(pos = 0.64, neg = 0.18),
  "Electronics & Biomedical Engineering" = list(pos = 0.62, neg = 0.20),
  "Electrical & Electronics Engineering"  = list(pos = 0.58, neg = 0.24),
  "Robotics and Automation"              = list(pos = 0.65, neg = 0.16),
  "Mechanical Engineering"                = list(pos = 0.54, neg = 0.28),
  "Civil Engineering"                     = list(pos = 0.56, neg = 0.26)
)

aspect_neg_mod <- c(
  teaching           =  0.00,
  coursecontent      =  0.02,
  examination        =  0.10,
  labwork            =  0.08,
  library_facilities =  0.06,
  extracurricular    = -0.05
)

pos_texts <- list(
  teaching = c(
    "Professor explains concepts very clearly and makes lectures engaging.",
    "Excellent teaching methodology. Complex topics made simple and practical.",
    "Faculty is approachable and always available for doubt-clearing sessions.",
    "Teaching quality is outstanding. Love the interactive style.",
    "The instructor gives real-world examples that make topics click instantly.",
    "Classes are well-paced and the professor ensures everyone understands."
  ),
  coursecontent = c(
    "Syllabus is well-designed and industry-relevant. Very satisfied.",
    "Course content is comprehensive and up to date with current trends.",
    "Great course material. Topics covered are very useful for placements.",
    "Curriculum balances theory and practical application perfectly.",
    "Course notes are detailed, structured, and easy to follow."
  ),
  examination = c(
    "The exam pattern is fair and reflects what was taught in class.",
    "Internal assessments are well-structured. No surprises in exams.",
    "Exam schedule is well-planned with adequate preparation time.",
    "Question papers test actual understanding rather than rote learning.",
    "Grading is transparent and results are communicated promptly."
  ),
  labwork = c(
    "Lab sessions are very helpful. Equipment is in good working condition.",
    "Practical experiments reinforce classroom learning effectively.",
    "Lab instructors are supportive and sessions are well-organized.",
    "The lab facilities have been upgraded recently and it really shows.",
    "Hands-on lab practice is the best part of this course.",
    "Lab equipment is modern and we get sufficient time for each experiment."
  ),
  library_facilities = c(
    "Library has a great collection of reference books for our course.",
    "Digital library access is very convenient for research work.",
    "Library staff is helpful and the study environment is excellent.",
    "Good availability of journals and online resources for projects.",
    "Library timings are student-friendly and the Wi-Fi is fast."
  ),
  extracurricular = c(
    "College events and tech fests are very well organized.",
    "Sports facilities are excellent. Inter-college competitions are exciting.",
    "Club activities are diverse and very engaging for students.",
    "Cultural events are a great stress-buster. Well organized.",
    "Hackathons and workshops provided are extremely valuable for skills."
  )
)

neg_texts <- list(
  teaching = c(
    "Lectures are hard to follow. Professor rushes through topics too fast.",
    "Teaching pace is too fast and doubts are rarely addressed properly.",
    "Faculty is often unavailable outside class hours for consultations.",
    "Explanation of concepts is unclear. We rely heavily on self-study.",
    "Teaching style is outdated. More interactive methods are needed.",
    "The professor reads directly from slides without any explanation."
  ),
  coursecontent = c(
    "Syllabus is outdated and not aligned with current industry requirements.",
    "Too much theoretical content with insufficient practical coverage.",
    "Course material is not updated. Many topics feel irrelevant.",
    "Too much content crammed into the semester with no time to absorb.",
    "Reference books for the course are not easily available anywhere."
  ),
  examination = c(
    "Exam schedule clashes with other assessments. Very stressful situation.",
    "Question papers are ambiguous and not aligned with what was taught.",
    "Grading is inconsistent and results take far too long to be published.",
    "Internal exam marks are not fairly distributed among students.",
    "Re-examination process is complicated and not student-friendly at all.",
    "Exam hall conditions are poor — inadequate seating and no ventilation.",
    "The exam timetable was released too late, leaving little preparation time.",
    "Some exam questions were out of syllabus which was very unfair to students."
  ),
  labwork = c(
    "Lab equipment is outdated and breaks down frequently during sessions.",
    "Lab sessions are often cancelled or cut short without prior notice.",
    "The lab is overcrowded — too many students sharing one setup.",
    "Lab manuals are not updated; some experiments are no longer relevant.",
    "Safety equipment in the lab is completely insufficient for student use.",
    "Lab computers are extremely slow and the software versions are outdated.",
    "We never get enough time to complete experiments properly in one session.",
    "Lab assistants are unhelpful and do not guide students effectively."
  ),
  library_facilities = c(
    "Library does not have sufficient copies of required textbooks.",
    "Library timings are too restrictive. It closes before we finish studying.",
    "Library seating capacity is completely inadequate during exam season.",
    "Internet connectivity in the library is very poor and unreliable.",
    "E-resources and journal subscriptions are extremely limited here."
  ),
  extracurricular = c(
    "Very few sports facilities are available for day-to-day student use.",
    "College events are poorly organized and often clash with exam period.",
    "Student clubs lack proper funding and administrative support.",
    "Inter-college participation opportunities are very limited for students.",
    "The sports ground is in poor condition and needs urgent maintenance."
  )
)

neu_texts <- list(
  teaching           = c("Teaching is average. Nothing exceptional but not bad.", "Faculty is okay. Could improve interactive sessions."),
  coursecontent      = c("Course content is fine. Average quality overall.", "Material is adequate but needs more real-world examples."),
  examination        = c("Exams are fair but quite tough for the time given.", "Exam experience was okay. Room for improvement."),
  labwork            = c("Lab is functional but needs some upgrades urgently.", "Lab sessions are okay but more time per experiment would help."),
  library_facilities = c("Library is decent. Some improvements are needed.", "Okay library. Most books are available but seating is limited."),
  extracurricular    = c("Events are average. Decent organization overall.", "Extracurricular activities are okay. More variety would help.")
)

all_records <- vector("list", TARGET_PER_SEMESTER * length(semesters) + 500)
idx <- 0L

for (sem in semesters) {
  sem_name   <- sem$name
  start_date <- as.POSIXct(sem$start, tz = "UTC")
  end_date   <- as.POSIXct(sem$end,   tz = "UTC")
  date_range <- as.numeric(difftime(end_date, start_date, units = "secs"))

  n_fac   <- nrow(faculty_df)
  per_fac <- ceiling(TARGET_PER_SEMESTER / n_fac)

  for (fi in seq_len(n_fac)) {
    fac       <- faculty_df[fi, ]
    dept_name <- if (!is.na(fac$department) && fac$department != "") fac$department else "General"
    profile   <- if (dept_name %in% names(dept_profiles)) dept_profiles[[dept_name]] else list(pos = 0.60, neg = 0.20)

    for (j in seq_len(per_fac)) {
      asp <- sample(aspects, 1)

      neg_prob <- min(0.95, max(0.02, profile$neg + aspect_neg_mod[[asp]]))
      pos_prob <- max(0.02, profile$pos - aspect_neg_mod[[asp]] * 0.5)
      neu_prob <- max(0.02, 1 - pos_prob - neg_prob)
      probs    <- c(pos_prob, neu_prob, neg_prob)
      probs    <- probs / sum(probs)

      sentiment <- sample(c(1L, 0L, -1L), 1, prob = probs)
      text_pool <- if (sentiment == 1L) pos_texts[[asp]] else if (sentiment == -1L) neg_texts[[asp]] else neu_texts[[asp]]
      txt       <- sample(text_pool, 1)

      ts     <- start_date + runif(1, 0, date_range)
      ts_str <- format(ts, "%Y-%m-%d %H:%M:%S")

      stu_id <- sample(student_df$id, 1)

      sub_r  <- round(runif(3, max(1, sentiment + 3), min(5, sentiment + 4.5)), 1)
      sub_json <- sprintf('{"clarity":%.1f,"engagement":%.1f,"usefulness":%.1f}', sub_r[1], sub_r[2], sub_r[3])

      emotion <- if (sentiment == 1L) {
        sample(c("joy", "neutral"), 1, prob = c(0.6, 0.4))
      } else if (sentiment == -1L) {
        sample(c("anger", "fear", "neutral"), 1, prob = c(0.4, 0.3, 0.3))
      } else "neutral"

      idx <- idx + 1L
      all_records[[idx]] <- list(
        student_id  = stu_id,
        faculty_id  = fac$id,
        anonymous   = sample(c(0L, 1L), 1, prob = c(0.35, 0.65)),
        aspect      = asp,
        rating      = sentiment,
        text        = txt,
        sub_ratings = sub_json,
        emotion_tag = emotion,
        semester    = sem_name,
        created_at  = ts_str
      )
    }
  }
}

all_records <- all_records[seq_len(idx)]
cat(sprintf("Generated %d records. Inserting into sentilytics.db...\n", length(all_records)))

dbBegin(con)
tryCatch({
  for (rec in all_records) {
    txt_clean <- gsub("'", "''", rec$text)
    dbExecute(con, sprintf(
      "INSERT INTO feedback_entries
         (student_id, faculty_id, anonymous, aspect, rating, text,
          sub_ratings, emotion_tag, semester, created_at)
       VALUES (%d, %d, %d, '%s', %d, '%s', '%s', '%s', '%s', '%s')",
      as.integer(rec$student_id),
      as.integer(rec$faculty_id),
      as.integer(rec$anonymous),
      rec$aspect,
      as.integer(rec$rating),
      txt_clean,
      rec$sub_ratings,
      rec$emotion_tag,
      rec$semester,
      rec$created_at
    ))
  }
  dbCommit(con)
  cat(sprintf("SUCCESS: Seeded %d records across 8 semesters!\n", length(all_records)))

  summary_q <- dbGetQuery(con,
    "SELECT semester,
            COUNT(*) AS total,
            SUM(CASE WHEN rating=1  THEN 1 ELSE 0 END) AS positive,
            SUM(CASE WHEN rating=0  THEN 1 ELSE 0 END) AS neutral,
            SUM(CASE WHEN rating=-1 THEN 1 ELSE 0 END) AS negative
     FROM feedback_entries
     GROUP BY semester
     ORDER BY semester")
  cat("\n=== 8 Semesters Summary ===\n")
  print(summary_q)

}, error = function(e) {
  dbRollback(con)
  cat("ERROR:", conditionMessage(e), "\n")
})

dbDisconnect(con)
