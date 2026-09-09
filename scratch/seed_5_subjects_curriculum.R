# scratch/seed_5_subjects_curriculum.R
con <- DBI::dbConnect(RSQLite::SQLite(), "data/sentilytics.db")

departments <- c(
  "Computer Science & Engineering",
  "Artificial Intelligence and Data Science",
  "Electronics & Communication Engineering",
  "Electrical & Electronics Engineering",
  "Electronics & Biomedical Engineering",
  "Robotics and Automation",
  "Civil Engineering",
  "Mechanical Engineering"
)

dept_prefixes <- c(
  "Computer Science & Engineering" = "CS",
  "Artificial Intelligence and Data Science" = "AI",
  "Electronics & Communication Engineering" = "EC",
  "Electrical & Electronics Engineering" = "EE",
  "Electronics & Biomedical Engineering" = "BM",
  "Robotics and Automation" = "RO",
  "Civil Engineering" = "CE",
  "Mechanical Engineering" = "ME"
)

# Standard subject templates per semester (5 per semester)
semester_subjects_template <- list(
  "Semester 1" = c(
    "Engineering Mathematics I",
    "Computer Programming Fundamentals",
    "Applied Engineering Physics",
    "Basics of Electrical & Electronics",
    "Professional Communication & Ethics"
  ),
  "Semester 2" = c(
    "Engineering Mathematics II",
    "Data Structures & Algorithms",
    "Digital Logic & State Machines",
    "Object-Oriented Programming",
    "Environmental Science & Sustainability"
  ),
  "Semester 3" = c(
    "Discrete Mathematical Structures",
    "Database Management Systems",
    "Computer Organization & Architecture",
    "Design & Analysis of Algorithms",
    "Universal Human Values & Professional Ethics"
  ),
  "Semester 4" = c(
    "Operating Systems Architecture",
    "Theory of Computation & Automata",
    "Software Engineering Methodologies",
    "Microprocessors & Microcontrollers",
    "Probability, Statistics & Stochastic Processes"
  ),
  "Semester 5" = c(
    "Computer Networks & Protocols",
    "Web Application Technologies",
    "Distributed Cloud Systems",
    "Artificial Intelligence Foundations",
    "Professional Elective I: Cyber Security"
  ),
  "Semester 6" = c(
    "Compiler Design & Translation",
    "Machine Learning & Pattern Analysis",
    "Mobile Application Development",
    "Information Security & Cryptography",
    "Open Elective I: Entrepreneurship"
  ),
  "Semester 7" = c(
    "Big Data Analytics & Data Lakes",
    "Deep Neural Networks & Applications",
    "Internet of Things (IoT) Systems",
    "Cloud Computing & Virtualization",
    "Professional Elective II: Blockchain Technologies"
  ),
  "Semester 8" = c(
    "Distributed Systems Architecture",
    "Natural Language Processing & LLMs",
    "Capstone Project & Thesis Evaluation",
    "DevOps & Continuous Deployment",
    "Management Principles & Quality Standards"
  )
)

# Clear existing courses and assignments to re-seed cleanly
DBI::dbExecute(con, "DELETE FROM teacher_assignments")
DBI::dbExecute(con, "DELETE FROM courses")

# Reset sequence
DBI::dbExecute(con, "DELETE FROM sqlite_sequence WHERE name IN ('courses', 'teacher_assignments')")

# Retrieve faculty users
faculty_df <- DBI::dbGetQuery(con, "SELECT id, name, department FROM users WHERE role = 'faculty' ORDER BY department, id")

# Populate 5 subjects per semester for each department
for (dept in departments) {
  prefix <- dept_prefixes[[dept]]
  dept_fac <- faculty_df[faculty_df$department == dept, ]
  
  for (sem_idx in 1:8) {
    sem_name <- paste("Semester", sem_idx)
    subjects <- semester_subjects_template[[sem_name]]
    
    for (s_idx in 1:5) {
      subj_title <- subjects[s_idx]
      course_code <- sprintf("%s%d0%d", prefix, sem_idx, s_idx)
      credits <- if (s_idx <= 3) 4 else 3
      
      # Insert Course
      DBI::dbExecute(con, sprintf(
        "INSERT INTO courses (course_code, course_name, department, semester, credits) VALUES ('%s', '%s', '%s', '%s', %d)",
        course_code, gsub("'", "''", subj_title), dept, sem_name, credits
      ))
      
      course_id <- DBI::dbGetQuery(con, "SELECT last_insert_rowid() AS id")$id[1]
      
      # Assign Faculty: balance across department faculty
      if (nrow(dept_fac) > 0) {
        fac_row <- ((sem_idx - 1) * 5 + (s_idx - 1)) %% nrow(dept_fac) + 1
        fac_id <- dept_fac$id[fac_row]
        
        DBI::dbExecute(con, sprintf(
          "INSERT INTO teacher_assignments (faculty_id, course_id, academic_year) VALUES (%d, %d, '2025-26')",
          fac_id, course_id
        ))
      }
    }
  }
}

# Ensure 4-subject allocation per faculty is balanced for main faculty
# Check count per department and semester
res <- DBI::dbGetQuery(con, "SELECT department, semester, COUNT(*) as count FROM courses GROUP BY department, semester")
print(head(res, 12))
cat(sprintf("Total courses seeded: %d across 8 departments * 8 semesters = %d\n", sum(res$count), 8*8*5))

DBI::dbDisconnect(con)
