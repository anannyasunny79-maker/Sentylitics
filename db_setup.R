# db_setup.R — Sentilytics Database Initializer
# Creates schema and demo users for all 8 specific college departments

library(DBI)
library(RSQLite)

DB_PATH <- "data/sentilytics.db"

if (file.exists(DB_PATH)) file.remove(DB_PATH)

con <- dbConnect(SQLite(), DB_PATH)
message("Database connected. Creating schema...")

# 1. Users Table
dbExecute(con, "
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL CHECK(role IN ('student','faculty','admin')),
    department TEXT,
    password_hash TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
  )
")

# 2. Feedback Entries Table
dbExecute(con, "
  CREATE TABLE feedback_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER,
    faculty_id INTEGER,
    anonymous INTEGER NOT NULL DEFAULT 0,
    aspect TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK(rating IN (-1, 0, 1)),
    text TEXT,
    sub_ratings TEXT,
    emotion_tag TEXT NOT NULL DEFAULT 'neutral',
    semester TEXT NOT NULL DEFAULT 'Semester 1',
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY(student_id) REFERENCES users(id),
    FOREIGN KEY(faculty_id) REFERENCES users(id)
  )
")

# 3. Alerts Table
dbExecute(con, "
  CREATE TABLE alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    entity_name TEXT NOT NULL,
    avg_neg_score REAL NOT NULL,
    threshold REAL NOT NULL DEFAULT 0.30,
    triggered_at TEXT DEFAULT (datetime('now')),
    dismissed INTEGER DEFAULT 0
  )
")

message("Schema created. Seeding demo users across all 8 college departments...")

users_df <- data.frame(
  name = c(
    "Alex Kumar", "Priya Nair", "Rajan Menon",
    "Dr. Sunita Iyer", "Prof. Maya Pillai",
    "Dr. Rajesh Varma", "Prof. Alex Varghese",
    "Prof. Arun Das", "Dr. Lakshmi Nair",
    "Dr. Suresh Kumar", "Prof. Reshma K",
    "Prof. Vikas Rao", "Dr. George Joseph",
    "Dr. Anjali Bose", "Prof. Deepak Sharma",
    "Dr. Sarah Jenkins", "Prof. Neha Kapoor",
    "Prof. Sandeep Mehta", "Dr. Rahul Menon",
    "Admin Principal"
  ),
  email = c(
    "alex@college.edu", "priya@college.edu", "rajan@college.edu",
    "sunita@college.edu", "maya@college.edu",
    "rajesh@college.edu", "alex.v@college.edu",
    "arun@college.edu", "lakshmi@college.edu",
    "suresh@college.edu", "reshma@college.edu",
    "vikas@college.edu", "george@college.edu",
    "anjali@college.edu", "deepak@college.edu",
    "sarah@college.edu", "neha@college.edu",
    "sandeep@college.edu", "rahul@college.edu",
    "admin@college.edu"
  ),
  role = c(
    "student", "student", "student",
    "faculty", "faculty",
    "faculty", "faculty",
    "faculty", "faculty",
    "faculty", "faculty",
    "faculty", "faculty",
    "faculty", "faculty",
    "faculty", "faculty",
    "faculty", "faculty",
    "admin"
  ),
  department = c(
    "Computer Science & Engineering", "Computer Science & Engineering", "Electronics & Communication Engineering",
    "Electronics & Biomedical Engineering", "Electronics & Biomedical Engineering",
    "Computer Science & Engineering", "Computer Science & Engineering",
    "Electrical & Electronics Engineering", "Electrical & Electronics Engineering",
    "Electronics & Communication Engineering", "Electronics & Communication Engineering",
    "Mechanical Engineering", "Mechanical Engineering",
    "Civil Engineering", "Civil Engineering",
    "Artificial Intelligence and Data Science", "Artificial Intelligence and Data Science",
    "Robotics and Automation", "Robotics and Automation",
    "Administration"
  ),
  password_hash = c(
    "student123", "student123", "student123",
    "faculty123", "faculty123",
    "faculty123", "faculty123",
    "faculty123", "faculty123",
    "faculty123", "faculty123",
    "faculty123", "faculty123",
    "faculty123", "faculty123",
    "faculty123", "faculty123",
    "faculty123", "faculty123",
    "admin123"
  ),
  stringsAsFactors = FALSE
)

dbWriteTable(con, "users", users_df, append = TRUE, row.names = FALSE)
message(sprintf("Seeded %d users.", nrow(users_df)))

dbDisconnect(con)
message("db_setup.R completed!")
