# ==============================================================================
# CAMPUS LISTEN — Enterprise College Feedback & Sentiment Intelligence Portal
# Self-Contained Shiny Application (bslib, dplyr, tibble, plotly)
# Strictly Olive Green (#556B2F, #6B8E23) & Stark White (#FFFFFF) Design
# ==============================================================================

library(shiny)
library(bslib)
library(plotly)
library(dplyr)
library(tibble)
library(DT)

# ------------------------------------------------------------------------------
# 1. INSTITUTIONAL MOCK DATA GENERATION (dplyr & tibble)
# ------------------------------------------------------------------------------

set.seed(42)

DEPARTMENTS <- c(
  "Computer Science & Engineering",
  "Electronics & Communication Engineering",
  "Mechanical Engineering",
  "Civil Engineering",
  "Artificial Intelligence & Data Science"
)

# 4 assigned subjects & specific instructors for each department
FACULTY_ASSIGNMENTS <- tibble(
  dept = rep(DEPARTMENTS, each = 4),
  course_code = c(
    "CS401", "CS402", "CS403", "CS404",
    "EC401", "EC402", "EC403", "EC404",
    "ME401", "ME402", "ME403", "ME404",
    "CE401", "CE402", "CE403", "CE404",
    "AI401", "AI402", "AI403", "AI404"
  ),
  course_name = c(
    "Operating Systems & Architecture", "Design & Analysis of Algorithms", "Database Management Systems", "Formal Automata & Computability",
    "Signals & Linear Systems", "VLSI & Digital Circuit Architecture", "Embedded Systems & Microcontrollers", "Electromagnetic Wave Theory",
    "Fluid Mechanics & Machinery", "Thermal Engineering & Heat Transfer", "Kinematics & Dynamics of Machines", "Advanced Manufacturing Technology",
    "Advanced Structural Analysis", "Geotechnical & Soil Engineering", "Modern Surveying & Geomatics", "Hydrology & Water Resources",
    "Deep Neural Network Architectures", "Statistical Machine Learning", "Distributed Big Data Systems", "Natural Language Processing"
  ),
  faculty_name = c(
    "Dr. Sarah Jenkins", "Prof. David Chen", "Dr. Radhika Sharma", "Prof. Marcus Vance",
    "Dr. Rajesh Kumar", "Prof. Elena Rostova", "Dr. Kevin Patel", "Prof. Anita Desai",
    "Dr. Thomas Miller", "Prof. Arun Verma", "Dr. Vikram Seth", "Prof. Robert Taylor",
    "Dr. Sanjay Gupta", "Prof. Lakshmi Nair", "Dr. John O'Connor", "Prof. Meera Pillai",
    "Dr. Alan Turing", "Prof. Priya Sundaram", "Dr. Michael Jordan", "Prof. Sneha Rao"
  ),
  faculty_title = c(
    "Associate Professor", "Assistant Professor", "Professor & Chair", "Assistant Professor",
    "Professor", "Associate Professor", "Assistant Professor", "Associate Professor",
    "Professor", "Associate Professor", "Assistant Professor", "Associate Professor",
    "Professor & Head", "Associate Professor", "Assistant Professor", "Associate Professor",
    "Professor", "Associate Professor", "Distinguished Professor", "Assistant Professor"
  ),
  credits = rep(c(4, 4, 3, 3), 5)
)

# Department Pre-Deadline Submission Quota & Readiness Data (Two Cycles)
DEPARTMENT_QUOTAS <- tibble(
  dept = rep(DEPARTMENTS, 2),
  cycle = rep(c("Cycle 1", "Cycle 2"), each = 5),
  target_quota = c(500, 480, 500, 450, 420, 500, 480, 500, 450, 420),
  submitted_count = c(
    # Cycle 1 (Completed historical)
    495, 472, 480, 435, 418,
    # Cycle 2 (Active: CS & AI completed, EC near, ME & CE pending)
    500, 442, 145, 170, 412
  )
) %>%
  mutate(
    pct = round((submitted_count / target_quota) * 100, 1),
    status = ifelse(pct >= 90, "READY", "NOT READY YET")
  )

# Department Historical Aspect Ratings (Cycle 1 vs Cycle 2)
ASPECT_RATINGS <- tibble(
  dept = rep(DEPARTMENTS, each = 8),
  cycle = rep(rep(c("Cycle 1", "Cycle 2"), each = 4), 5),
  aspect = rep(c("Teaching Quality", "Laboratory Equipment", "Library & Digital", "Curriculum Delivery"), 10),
  satisfaction_pct = c(
    # Computer Science
    85.2, 81.0, 78.4, 83.1,   91.4, 88.2, 84.6, 89.0,
    # Electronics
    81.0, 79.2, 75.0, 80.5,   85.3, 83.0, 80.1, 84.2,
    # Mechanical
    74.5, 71.0, 70.2, 73.0,   78.1, 74.0, 72.5, 76.0,
    # Civil
    72.0, 68.5, 69.0, 71.2,   75.4, 71.2, 71.0, 74.5,
    # AI & Data Science
    88.0, 85.1, 82.0, 86.4,   94.2, 91.0, 88.5, 92.3
  )
)

# Faculty Performance Aggregated Metrics
FACULTY_PERFORMANCE <- FACULTY_ASSIGNMENTS %>%
  mutate(
    avg_teaching_score = c(
      4.65, 4.38, 4.72, 4.15,
      4.42, 4.51, 4.18, 4.30,
      3.95, 4.12, 3.82, 4.05,
      3.88, 4.02, 3.75, 4.10,
      4.82, 4.65, 4.78, 4.55
    ),
    reviews_count = c(
      492, 485, 498, 480,
      440, 435, 438, 442,
      142, 140, 145, 141,
      168, 165, 170, 169,
      410, 408, 412, 405
    ),
    positive_pct = c(
      91.2, 85.4, 93.0, 81.5,
      86.0, 88.2, 81.0, 84.5,
      72.1, 76.5, 69.4, 75.0,
      70.5, 74.2, 68.0, 76.1,
      95.1, 91.8, 94.2, 89.5
    )
  )

# College-Wide Aggregated Department Sentiment (Post-Deadline)
COLLEGE_SENTIMENT <- tibble(
  dept = DEPARTMENTS,
  dept_short = c("CSE", "ECE", "MECH", "CIVIL", "AI&DS"),
  total_submissions = c(995, 914, 625, 605, 830),
  c1_positive = c(84.2, 80.5, 70.4, 68.2, 87.5),
  c2_positive = c(91.8, 86.4, 74.2, 72.8, 94.6),
  overall_positive = c(88.0, 83.5, 72.3, 70.5, 91.1),
  overall_neutral  = c(7.8,  10.5, 16.2, 17.5,  6.2),
  overall_negative = c(4.2,   6.0, 11.5, 12.0,  2.7)
)

# ------------------------------------------------------------------------------
# 2. APPLICATION THEME & ENTERPRISE STYLING
# ------------------------------------------------------------------------------

OLIVE_PRIMARY   <- "#556B2F"  # Dark Olive Green
OLIVE_ACCENT    <- "#6B8E23"  # Olive Drab
OLIVE_LIGHT     <- "#F4F6F0"  # Subtle Light Olive Card Background
OLIVE_BORDER    <- "#D8DFCE"  # Muted Olive Border
COLOR_WHITE     <- "#FFFFFF"  # Stark White
TEXT_MAIN       <- "#1F2937"  # Clean Charcoal
TEXT_MUTED      <- "#6B7280"  # Soft Gray

custom_css <- "
  /* Universal font and layout resets */
  body {
    background-color: #FAFCF8 !important;
    color: #1F2937 !important;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif !important;
    -webkit-font-smoothing: antialiased;
  }

  /* Enterprise Navbar Styling */
  .navbar {
    background-color: #FFFFFF !important;
    border-bottom: 1px solid #E5E9E0 !important;
    padding: 0.8rem 1.8rem !important;
    box-shadow: 0 1px 3px rgba(85, 107, 47, 0.05) !important;
  }
  .navbar-brand {
    font-size: 1.15rem !important;
    font-weight: 700 !important;
    color: #2F3E1B !important;
    display: flex !important;
    align-items: center !important;
    gap: 10px !important;
  }
  .navbar .nav-link {
    color: #4B5563 !important;
    font-weight: 600 !important;
    font-size: 0.90rem !important;
    padding: 0.5rem 1.1rem !important;
    border-radius: 6px !important;
    margin: 0 3px !important;
    transition: all 0.15s ease-in-out !important;
  }
  .navbar .nav-link:hover {
    color: #556B2F !important;
    background-color: #F4F6F0 !important;
  }
  .navbar .nav-link.active {
    color: #FFFFFF !important;
    background-color: #556B2F !important;
  }

  /* Enterprise Cards */
  .card {
    background-color: #FFFFFF !important;
    border: 1px solid #E5E9E0 !important;
    border-radius: 8px !important;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03) !important;
  }
  .card-header {
    background-color: #FFFFFF !important;
    border-bottom: 1px solid #E5E9E0 !important;
    font-weight: 700 !important;
    font-size: 0.96rem !important;
    color: #2F3E1B !important;
    padding: 14px 18px !important;
  }
  .card-body {
    padding: 20px !important;
  }

  /* Secondary Tab Underline Styling */
  .navset-card-underline .nav-tabs {
    border-bottom: 2px solid #E5E9E0 !important;
    margin-bottom: 1rem !important;
  }
  .navset-card-underline .nav-link {
    color: #6B7280 !important;
    font-weight: 600 !important;
    border: none !important;
    border-bottom: 2px solid transparent !important;
    padding: 0.75rem 1.25rem !important;
    background: transparent !important;
  }
  .navset-card-underline .nav-link:hover {
    color: #556B2F !important;
  }
  .navset-card-underline .nav-link.active {
    color: #556B2F !important;
    border-bottom: 2px solid #556B2F !important;
    background: transparent !important;
  }

  /* Form Inputs & Sliders */
  .form-control, .form-select {
    border: 1px solid #D8DFCE !important;
    border-radius: 6px !important;
    font-size: 0.90rem !important;
    color: #1F2937 !important;
  }
  .form-control:focus, .form-select:focus {
    border-color: #556B2F !important;
    box-shadow: 0 0 0 3px rgba(85, 107, 47, 0.12) !important;
  }
  .irs--shiny .irs-bar {
    background: #556B2F !important;
    border-top: 1px solid #556B2F !important;
    border-bottom: 1px solid #556B2F !important;
  }
  .irs--shiny .irs-handle {
    border: 2px solid #556B2F !important;
  }
  .irs--shiny .irs-from, .irs--shiny .irs-to, .irs--shiny .irs-single {
    background: #556B2F !important;
  }

  /* Buttons */
  .btn-olive {
    background-color: #556B2F !important;
    border-color: #556B2F !important;
    color: #FFFFFF !important;
    font-weight: 600 !important;
    padding: 0.55rem 1.4rem !important;
    border-radius: 6px !important;
    letter-spacing: 0.01em !important;
  }
  .btn-olive:hover {
    background-color: #435424 !important;
    border-color: #435424 !important;
    color: #FFFFFF !important;
  }
  .btn-outline-olive {
    background-color: transparent !important;
    border: 1px solid #556B2F !important;
    color: #556B2F !important;
    font-weight: 600 !important;
    border-radius: 6px !important;
  }
  .btn-outline-olive:hover {
    background-color: #F4F6F0 !important;
    color: #3E4F22 !important;
  }

  /* Conditional Success Banner (Olive Green) */
  .olive-success-banner {
    background-color: #F4F6F0;
    border: 1px solid #6B8E23;
    border-left: 6px solid #556B2F;
    border-radius: 8px;
    padding: 24px 28px;
    color: #2F3E1B;
    box-shadow: 0 1px 3px rgba(0,0,0,0.03);
  }
  .olive-success-title {
    font-size: 1.15rem;
    font-weight: 700;
    color: #2F3E1B;
    margin-bottom: 6px;
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .olive-success-body {
    font-size: 0.95rem;
    color: #4B5563;
    line-height: 1.5;
  }

  /* Progress Bars */
  .progress-custom {
    height: 10px;
    border-radius: 999px;
    background-color: #E5E9E0;
    overflow: hidden;
  }
  .progress-bar-ready {
    background-color: #556B2F !important;
  }
  .progress-bar-pending {
    background-color: #B45309 !important;
  }

  /* Clean DataTables Styling */
  table.dataTable {
    border-collapse: separate !important;
    border-spacing: 0 !important;
    width: 100% !important;
    font-size: 0.88rem !important;
  }
  table.dataTable thead th {
    background-color: #F8FAF6 !important;
    color: #2F3E1B !important;
    font-weight: 700 !important;
    border-bottom: 1px solid #E5E9E0 !important;
    padding: 10px 14px !important;
  }
  table.dataTable tbody td {
    padding: 10px 14px !important;
    border-bottom: 1px solid #F1F4ED !important;
    color: #374151 !important;
  }
"

# ------------------------------------------------------------------------------
# 3. USER INTERFACE (bslib::page_navbar)
# ------------------------------------------------------------------------------

ui <- page_navbar(
  id = "main_nav",
  title = tags$span(
    style = "font-weight: 700; letter-spacing: -0.02em; display: inline-flex; align-items: center; gap: 8px; color: #2F3E1B;",
    tags$svg(
      xmlns = "http://www.w3.org/2000/svg", viewBox = "0 0 24 24",
      style = "width:22px;height:22px;fill:none;stroke:#556B2F;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round;",
      tags$path(d = "M22 10v6M2 10l10-5 10 5-10 5z"),
      tags$path(d = "M6 12v5c3 3 9 3 12 0v-5")
    ),
    "Campus Listen"
  ),
  theme = bs_theme(
    version = 5,
    bg = COLOR_WHITE,
    fg = TEXT_MAIN,
    primary = OLIVE_PRIMARY,
    secondary = OLIVE_ACCENT,
    base_font = font_google("Inter")
  ),
  header = tags$head(
    tags$style(HTML(custom_css))
  ),

  # ============================================================================
  # PORTAL 1: STUDENT PORTAL (SUBMISSION VIEW)
  # ============================================================================
  nav_panel(
    title = "Student Portal",
    div(
      style = "max-width: 980px; margin: 0 auto; padding: 24px 16px;",

      # Academic Context Selector Card
      card(
        card_header("Academic Submission Context"),
        card_body(
          layout_columns(
            col_widths = c(4, 4, 4),
            selectInput(
              "student_dept",
              "Academic Department",
              choices = DEPARTMENTS,
              selected = "Computer Science & Engineering"
            ),
            selectInput(
              "student_sem",
              "Semester",
              choices = c("Semester 4", "Semester 6", "Semester 8"),
              selected = "Semester 4"
            ),
            selectInput(
              "student_cycle",
              "Submission Cycle",
              choices = c("Cycle 1", "Cycle 2"),
              selected = "Cycle 2"
            )
          ),
          div(
            style = "display: flex; justify-content: space-between; align-items: center; margin-top: 10px; padding-top: 10px; border-top: 1px solid #F1F4ED;",
            tags$span(
              style = "font-size: 0.82rem; color: #6B7280;",
              tags$strong("Student ID: "), "STU-2024-0418 (Enrolled)"
            ),
            tags$span(
              style = "font-size: 0.82rem; color: #556B2F; font-weight: 600;",
              tags$svg(
                xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24",
                style="width:14px;height:14px;fill:none;stroke:#556B2F;stroke-width:2;display:inline-block;vertical-align:middle;margin-right:4px;",
                tags$circle(cx="12", cy="12", r="10"),
                tags$polyline(points="12 6 12 12 16 14")
              ),
              "Active Window: AY 2025–26 Even Semester"
            )
          )
        )
      ),

      div(style = "height: 18px;"),

      # Conditional Submission View Container
      uiOutput("student_portal_content")
    )
  ),

  # ============================================================================
  # PORTAL 2: HoD (HEAD OF DEPARTMENT) PORTAL
  # ============================================================================
  nav_panel(
    title = "HoD Portal",
    div(
      style = "max-width: 1200px; margin: 0 auto; padding: 24px 16px;",

      # Department Filter Bar
      card(
        card_body(
          style = "padding: 16px 20px;",
          layout_columns(
            col_widths = c(8, 4),
            div(
              style = "display: flex; align-items: center; gap: 14px;",
              tags$div(
                style = "width: 42px; height: 42px; border-radius: 8px; background: #F4F6F0; display: flex; align-items: center; justify-content: center; color: #556B2F; flex-shrink: 0;",
                tags$svg(
                  xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24",
                  style="width:22px;height:22px;fill:none;stroke:#556B2F;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;",
                  tags$path(d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"),
                  tags$path(d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z")
                )
              ),
              div(
                div(style = "font-weight: 700; font-size: 1.1rem; color: #2F3E1B;", textOutput("hod_header_dept", inline = TRUE)),
                div(style = "font-size: 0.82rem; color: #6B7280;", "Departmental Oversight, Faculty Benchmarks & Aspect Diagnostics")
              )
            ),
            selectInput(
              "hod_dept_select",
              "Change Department Context",
              choices = DEPARTMENTS,
              selected = "Computer Science & Engineering"
            )
          )
        )
      ),

      div(style = "height: 18px;"),

      # HoD Key Performance Indicators Row
      layout_columns(
        col_widths = c(3, 3, 3, 3),
        card(
          card_body(
            div(style = "font-size: 0.80rem; font-weight: 700; color: #6B7280; text-transform: uppercase; letter-spacing: 0.05em;", "Total Submissions"),
            div(style = "font-size: 1.7rem; font-weight: 700; color: #2F3E1B; margin: 4px 0;", textOutput("hod_kpi_total")),
            div(style = "font-size: 0.78rem; color: #556B2F; font-weight: 600;", "Across Cycle 1 & Cycle 2")
          )
        ),
        card(
          card_body(
            div(style = "font-size: 0.80rem; font-weight: 700; color: #6B7280; text-transform: uppercase; letter-spacing: 0.05em;", "Faculty Avg Score"),
            div(style = "font-size: 1.7rem; font-weight: 700; color: #556B2F; margin: 4px 0;", textOutput("hod_kpi_avg_score")),
            div(style = "font-size: 0.78rem; color: #6B7280;", "Scale: 1.0 - 5.0 (Target: 4.0)")
          )
        ),
        card(
          card_body(
            div(style = "font-size: 0.80rem; font-weight: 700; color: #6B7280; text-transform: uppercase; letter-spacing: 0.05em;", "Positive Sentiment"),
            div(style = "font-size: 1.7rem; font-weight: 700; color: #2F3E1B; margin: 4px 0;", textOutput("hod_kpi_pos_pct")),
            div(style = "font-size: 0.78rem; color: #556B2F; font-weight: 600;", "+4.6% vs College Average")
          )
        ),
        card(
          card_body(
            div(style = "font-size: 0.80rem; font-weight: 700; color: #6B7280; text-transform: uppercase; letter-spacing: 0.05em;", "Aspect Satisfaction"),
            div(style = "font-size: 1.7rem; font-weight: 700; color: #556B2F; margin: 4px 0;", textOutput("hod_kpi_aspect_rate")),
            div(style = "font-size: 0.78rem; color: #6B7280;", "Labs, Library & Teaching Combined")
          )
        )
      ),

      div(style = "height: 18px;"),

      # Visualizations: Faculty Comparison Bar Chart + Aspect Satisfaction Line Graph
      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("Performance of Assigned Subject Teachers (4 Department Courses)"),
          card_body(
            plotlyOutput("hod_faculty_chart", height = "340px")
          )
        ),
        card(
          card_header("Aspect Satisfaction Trajectory (Teaching, Labs, Library)"),
          card_body(
            plotlyOutput("hod_aspect_chart", height = "340px")
          )
        )
      ),

      div(style = "height: 18px;"),

      # Department Course Table
      card(
        card_header("Assigned Subject Instructors & Course Evaluation Ledger"),
        card_body(
          DTOutput("hod_faculty_table")
        )
      )
    )
  ),

  # ============================================================================
  # PORTAL 3: ADMIN / PRINCIPAL PORTAL (EXECUTIVE ANALYTICS)
  # ============================================================================
  nav_panel(
    title = "Admin / Principal Portal",
    div(
      style = "max-width: 1200px; margin: 0 auto; padding: 24px 16px;",

      # Executive Header Card
      card(
        card_body(
          style = "padding: 16px 20px;",
          div(
            style = "display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;",
            div(
              div(style = "font-weight: 700; font-size: 1.15rem; color: #2F3E1B;", "Principal Executive Governance"),
              div(style = "font-size: 0.82rem; color: #6B7280;", "Institutional oversight: Pre-deadline departmental readiness & aggregated post-deadline analytics.")
            ),
            div(
              tags$span(class = "badge", style = "background: #F4F6F0; color: #556B2F; border: 1px solid #D8DFCE; font-weight: 600; padding: 6px 12px; font-size: 0.82rem;",
                "AY 2025–26 Institutional Dashboard"
              )
            )
          )
        )
      ),

      div(style = "height: 18px;"),

      # Strictly Arranged Secondary Tabs (navset_card_underline)
      navset_card_underline(
        id = "principal_subtabs",

        # ----------------------------------------------------------------------
        # TAB A: READINESS MONITOR (PRE-DEADLINE)
        # ----------------------------------------------------------------------
        nav_panel(
          title = "Tab A — Readiness Monitor (Pre-Deadline)",
          div(
            style = "padding: 8px 0;",
            div(
              style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;",
              div(
                tags$h6(style = "font-weight: 700; color: #2F3E1B; margin: 0;", "Department Submission Quota & Completion Status"),
                tags$p(style = "font-size: 0.82rem; color: #6B7280; margin: 0;", "Monitoring which departments have met their submission threshold prior to dataset compilation.")
              ),
              div(
                style = "width: 180px;",
                selectInput("admin_cycle_filter", NULL, choices = c("Cycle 2 (Current Active)", "Cycle 1 (Archived)"), selected = "Cycle 2 (Current Active)")
              )
            ),

            # Readiness Status Metrics
            layout_columns(
              col_widths = c(3, 3, 3, 3),
              card(
                card_body(
                  div(style = "font-size: 0.78rem; font-weight: 700; color: #6B7280; text-transform: uppercase;", "Total Expected Quota"),
                  div(style = "font-size: 1.6rem; font-weight: 700; color: #2F3E1B;", "2,350"),
                  div(style = "font-size: 0.76rem; color: #6B7280;", "Across 5 Academic Departments")
                )
              ),
              card(
                card_body(
                  div(style = "font-size: 0.78rem; font-weight: 700; color: #6B7280; text-transform: uppercase;", "Received Submissions"),
                  div(style = "font-size: 1.6rem; font-weight: 700; color: #556B2F;", textOutput("admin_received_count")),
                  div(style = "font-size: 0.76rem; color: #556B2F; font-weight: 600;", textOutput("admin_completion_rate"))
                )
              ),
              card(
                card_body(
                  div(style = "font-size: 0.78rem; font-weight: 700; color: #6B7280; text-transform: uppercase;", "Departments Ready"),
                  div(style = "font-size: 1.6rem; font-weight: 700; color: #556B2F;", textOutput("admin_ready_depts")),
                  div(style = "font-size: 0.76rem; color: #556B2F;", "Threshold >= 90% achieved")
                )
              ),
              card(
                card_body(
                  div(style = "font-size: 0.78rem; font-weight: 700; color: #6B7280; text-transform: uppercase;", "Action Required"),
                  div(style = "font-size: 1.6rem; font-weight: 700; color: #B45309;", textOutput("admin_pending_depts")),
                  div(style = "font-size: 0.76rem; color: #B45309; font-weight: 600;", "Pending Quota Fulfillment")
                )
              )
            ),

            div(style = "height: 16px;"),

            # Department Readiness Table with Progress Bars
            card(
              card_header("Department Submission Readiness Ledger (Pre-Deadline Monitor)"),
              card_body(
                uiOutput("admin_readiness_cards")
              )
            )
          )
        ),

        # ----------------------------------------------------------------------
        # TAB B: AGGREGATED ANALYTICS (POST-DEADLINE)
        # ----------------------------------------------------------------------
        nav_panel(
          title = "Tab B — Aggregated Analytics (Post-Deadline)",
          div(
            style = "padding: 8px 0;",
            div(
              style = "margin-bottom: 16px;",
              tags$h6(style = "font-weight: 700; color: #2F3E1B; margin: 0;", "Consolidated Institutional Dataset Analytics"),
              tags$p(style = "font-size: 0.82rem; color: #6B7280; margin: 0;", "Synthesized college-wide sentiment distributions and cross-cycle trajectory.")
            ),

            # Top 3 KPIs mandated by user: Total Submissions, Overall Positive %, Overall Negative %
            layout_columns(
              col_widths = c(4, 4, 4),
              card(
                card_body(
                  div(style = "font-size: 0.80rem; font-weight: 700; color: #6B7280; text-transform: uppercase; letter-spacing: 0.05em;", "Total College Submissions"),
                  div(style = "font-size: 2rem; font-weight: 800; color: #2F3E1B; margin: 4px 0;", "3,969"),
                  div(style = "font-size: 0.78rem; color: #6B7280;", "Consolidated across all 5 departments & 2 cycles")
                )
              ),
              card(
                card_body(
                  div(style = "font-size: 0.80rem; font-weight: 700; color: #6B7280; text-transform: uppercase; letter-spacing: 0.05em;", "Overall Positive %"),
                  div(style = "font-size: 2rem; font-weight: 800; color: #556B2F; margin: 4px 0;", "81.1%"),
                  div(style = "font-size: 0.78rem; color: #556B2F; font-weight: 600;", "Constructive & Commendatory Feedback")
                )
              ),
              card(
                card_body(
                  div(style = "font-size: 0.80rem; font-weight: 700; color: #6B7280; text-transform: uppercase; letter-spacing: 0.05em;", "Overall Negative %"),
                  div(style = "font-size: 2rem; font-weight: 800; color: #9A3412; margin: 4px 0;", "7.3%"),
                  div(style = "font-size: 0.78rem; color: #6B7280;", "Neutral sentiment accounts for 11.6%")
                )
              )
            ),

            div(style = "height: 18px;"),

            # Visualizations: Grouped Bar Chart + Simple Sentiment Shift Trend Line
            layout_columns(
              col_widths = c(7, 5),
              card(
                card_header("Department Sentiment Distribution (Grouped Bar Chart)"),
                card_body(
                  plotlyOutput("admin_grouped_bar_chart", height = "360px")
                )
              ),
              card(
                card_header("Sentiment Shift Trajectory (Cycle 1 vs Cycle 2)"),
                card_body(
                  plotlyOutput("admin_trend_line_chart", height = "360px")
                )
              )
            ),

            div(style = "height: 18px;"),

            # Aggregated Institutional Ledger
            card(
              card_header("Consolidated Departmental Benchmark Summary"),
              card_body(
                DTOutput("admin_summary_table")
              )
            )
          )
        )
      )
    )
  ),

  # Navbar Right Spacer & Academic Session Label
  nav_spacer(),
  nav_item(
    tags$span(
      style = "font-size: 0.80rem; color: #6B7280; font-weight: 600; padding: 0.5rem 0.8rem; display: flex; align-items: center; gap: 6px;",
      tags$span(style = "width: 8px; height: 8px; border-radius: 50%; background: #556B2F; display: inline-block;"),
      "Academic Session 2025–2026"
    )
  )
)

# ------------------------------------------------------------------------------
# 4. SERVER LOGIC
# ------------------------------------------------------------------------------

server <- function(input, output, session) {

  # Reactive State for Student Submissions (tracks submitted status per Dept + Sem + Cycle)
  # Pre-seed one key so user can immediately observe the "Already Submitted" state if selected!
  submitted_state <- reactiveValues(
    submitted_keys = c(
      "Computer Science & Engineering_Semester 4_Cycle 1"
    )
  )

  # Check if current student context is already submitted
  current_student_key <- reactive({
    paste(input$student_dept, input$student_sem, input$student_cycle, sep = "_")
  })

  is_already_submitted <- reactive({
    current_student_key() %in% submitted_state$submitted_keys
  })

  # Handle Student Submission Button
  observeEvent(input$btn_submit_feedback, {
    k <- current_student_key()
    if (!(k %in% submitted_state$submitted_keys)) {
      submitted_state$submitted_keys <- c(submitted_state$submitted_keys, k)
    }
    showNotification(
      "Feedback recorded successfully into institutional repository.",
      type = "message",
      duration = 4
    )
  })

  # Allow Testing / Reset of Submission
  observeEvent(input$btn_reset_submission, {
    k <- current_student_key()
    submitted_state$submitted_keys <- setdiff(submitted_state$submitted_keys, k)
    showNotification("Cycle submission state reset for testing.", type = "warning", duration = 3)
  })

  # ============================================================================
  # 4.1 STUDENT PORTAL RENDERER (Conditional Form vs Success Banner)
  # ============================================================================
  output$student_portal_content <- renderUI({
    dept <- input$student_dept
    sem  <- input$student_sem
    cyc  <- input$student_cycle

    # 1. IF ALREADY SUBMITTED: Display strict Olive Green Success Banner & hide form
    if (is_already_submitted()) {
      div(
        class = "olive-success-banner",
        div(
          class = "olive-success-title",
          tags$svg(
            xmlns = "http://www.w3.org/2000/svg", viewBox = "0 0 24 24",
            style = "width: 24px; height: 24px; fill: none; stroke: #556B2F; stroke-width: 2.5; stroke-linecap: round; stroke-linejoin: round;",
            tags$path(d = "M22 11.08V12a10 10 0 1 1-5.93-9.14"),
            tags$polyline(points = "22 4 12 14.01 9 11.01")
          ),
          "Feedback Submitted Successfully"
        ),
        div(
          class = "olive-success-body",
          tags$p(
            style = "font-size: 0.98rem; font-weight: 500; margin: 8px 0 16px 0; color: #2F3E1B;",
            "You have successfully submitted your feedback for this cycle. No further action is required."
          ),
          div(
            style = "background: #FFFFFF; border: 1px solid #D8DFCE; border-radius: 6px; padding: 14px 18px; max-width: 600px; margin-bottom: 16px;",
            tags$div(style = "font-size: 0.78rem; font-weight: 700; color: #6B7280; text-transform: uppercase; margin-bottom: 6px;", "Institutional Submission Receipt"),
            tags$div(style = "font-size: 0.85rem; color: #374151;", tags$strong("Department: "), dept),
            tags$div(style = "font-size: 0.85rem; color: #374151;", tags$strong("Academic Period: "), paste(sem, "|", cyc)),
            tags$div(style = "font-size: 0.85rem; color: #374151;", tags$strong("Courses Evaluated: "), "4 Assigned Department Subjects"),
            tags$div(style = "font-size: 0.85rem; color: #556B2F; font-weight: 600; margin-top: 4px;", "Status: Verified & Stored Anonymously")
          ),
          div(
            actionButton(
              "btn_reset_submission",
              "Simulate Another Submission / Edit Response",
              class = "btn btn-outline-olive btn-sm",
              style = "font-size: 0.80rem;"
            )
          )
        )
      )
    } else {
      # 2. IF NOT SUBMITTED: Display the clean form showing EXACTLY 4 subjects and assigned teachers
      courses_for_dept <- FACULTY_ASSIGNMENTS %>% filter(dept == !!dept)

      tagList(
        card(
          card_header(
            div(
              style = "display:flex; justify-content:space-between; align-items:center;",
              tags$span(paste("Assigned Subject Feedback (4 Courses) —", cyc)),
              tags$span(style = "font-size:0.80rem; font-weight:normal; color:#6B7280;", "All 4 evaluations required")
            )
          ),
          card_body(
            p(style = "font-size: 0.88rem; color: #4B5563; margin-bottom: 20px;",
              "Please rate your assigned subject instructors across pedagogical clarity, lab guidance, and course engagement."
            ),

            # Dynamically render the 4 courses
            lapply(seq_len(nrow(courses_for_dept)), function(i) {
              crs <- courses_for_dept[i, ]
              div(
                style = paste0(
                  "padding: 16px; border-radius: 6px; background: #FFFFFF; border: 1px solid #E5E9E0; margin-bottom: 16px;",
                  if (i == nrow(courses_for_dept)) "" else " border-left: 4px solid #556B2F;"
                ),
                layout_columns(
                  col_widths = c(6, 6),
                  div(
                    div(style = "font-weight: 700; font-size: 0.95rem; color: #2F3E1B;", paste(crs$course_code, "—", crs$course_name)),
                    div(
                      style = "font-size: 0.84rem; color: #556B2F; font-weight: 600; margin-top: 2px;",
                      tags$svg(
                        xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24",
                        style="width:14px;height:14px;fill:none;stroke:#556B2F;stroke-width:2;display:inline-block;vertical-align:middle;margin-right:4px;",
                        tags$path(d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"),
                        tags$circle(cx="12", cy="7", r="4")
                      ),
                      paste("Assigned Faculty:", crs$faculty_name, paste0("(", crs$faculty_title, ")"))
                    )
                  ),
                  sliderInput(
                    inputId = paste0("rate_fac_", i),
                    label = "Teaching & Conceptual Clarity (1–5)",
                    min = 1, max = 5, value = 4, step = 1, width = "100%"
                  )
                ),
                div(style = "margin-top: 8px;"),
                textAreaInput(
                  inputId = paste0("comm_fac_", i),
                  label = NULL,
                  placeholder = paste("Constructive comments for", crs$faculty_name, "(optional)"),
                  rows = 2,
                  width = "100%"
                )
              )
            }),

            # Departmental Facilities & Aspect Ratings
            div(
              style = "background: #FAFCF8; border: 1px solid #E5E9E0; border-radius: 6px; padding: 16px; margin-top: 20px;",
              div(style = "font-weight: 700; font-size: 0.90rem; color: #2F3E1B; margin-bottom: 12px;", "Department Facilities & Academic Support"),
              layout_columns(
                col_widths = c(6, 6),
                sliderInput("rate_labs", "Laboratory Equipment & Assistance (1–5)", min = 1, max = 5, value = 4, step = 1),
                sliderInput("rate_library", "Library & Digital Learning Resources (1–5)", min = 1, max = 5, value = 4, step = 1)
              )
            ),

            div(style = "margin-top: 24px; text-align: right;"),
            actionButton(
              "btn_submit_feedback",
              "Submit Feedback",
              class = "btn-olive",
              icon = icon("paper-plane", verify_fa = FALSE)
            )
          )
        )
      )
    }
  })

  # ============================================================================
  # 4.2 HoD PORTAL OUTPUTS
  # ============================================================================
  selected_hod_dept <- reactive({
    input$hod_dept_select
  })

  output$hod_header_dept <- renderText({
    paste("Department of", selected_hod_dept())
  })

  hod_dept_data <- reactive({
    FACULTY_PERFORMANCE %>% filter(dept == selected_hod_dept())
  })

  output$hod_kpi_total <- renderText({
    tot <- sum(hod_dept_data()$reviews_count)
    format(tot, big.mark = ",")
  })

  output$hod_kpi_avg_score <- renderText({
    avg <- mean(hod_dept_data()$avg_teaching_score)
    sprintf("%.2f / 5.0", avg)
  })

  output$hod_kpi_pos_pct <- renderText({
    pos <- mean(hod_dept_data()$positive_pct)
    sprintf("%.1f%%", pos)
  })

  output$hod_kpi_aspect_rate <- renderText({
    asp <- ASPECT_RATINGS %>% filter(dept == selected_hod_dept(), cycle == "Cycle 2")
    sprintf("%.1f%%", mean(asp$satisfaction_pct))
  })

  # Chart 1: Bar chart comparing performance of the 4 assigned teachers
  output$hod_faculty_chart <- renderPlotly({
    df <- hod_dept_data()

    plot_ly(
      data = df,
      x = ~faculty_name,
      y = ~avg_teaching_score,
      type = "bar",
      marker = list(
        color = OLIVE_PRIMARY,
        line = list(color = "#3E4F22", width = 1)
      ),
      customdata = ~reviews_count,
      hovertemplate = "<b>%{x}</b><br>Teaching Score: %{y:.2f} / 5.0<br>Evaluations: %{customdata}<extra></extra>"
    ) %>%
      layout(
        yaxis = list(
          title = "Average Teaching Score",
          range = c(0, 5.0),
          gridcolor = "#F1F4ED",
          zeroline = FALSE
        ),
        xaxis = list(
          title = "",
          tickangle = -15,
          tickfont = list(size = 11)
        ),
        shapes = list(
          list(
            type = "line",
            x0 = -0.5, x1 = 3.5,
            y0 = 4.0, y1 = 4.0,
            line = list(color = "#9CA3AF", width = 1.5, dash = "dash")
          )
        ),
        annotations = list(
          list(
            x = 3.4, y = 4.15,
            text = "Target: 4.0",
            showarrow = FALSE,
            font = list(size = 10, color = "#6B7280")
          )
        ),
        margin = list(t = 20, b = 60, l = 50, r = 20),
        paper_bgcolor = COLOR_WHITE,
        plot_bgcolor = COLOR_WHITE
      ) %>%
      config(displayModeBar = FALSE)
  })

  # Chart 2: Line graph showing aspect satisfaction (Teaching, Labs, Library)
  output$hod_aspect_chart <- renderPlotly({
    df_aspects <- ASPECT_RATINGS %>% filter(dept == selected_hod_dept())
    c1 <- df_aspects %>% filter(cycle == "Cycle 1")
    c2 <- df_aspects %>% filter(cycle == "Cycle 2")

    plot_ly() %>%
      add_trace(
        data = c1,
        x = ~aspect,
        y = ~satisfaction_pct,
        name = "Cycle 1 (Mid-Term)",
        type = "scatter",
        mode = "lines+markers",
        line = list(color = "#8F9779", width = 2, dash = "dot"),
        marker = list(color = "#8F9779", size = 7),
        hovertemplate = "<b>%{x}</b> (Cycle 1)<br>Satisfaction: %{y:.1f}%<extra></extra>"
      ) %>%
      add_trace(
        data = c2,
        x = ~aspect,
        y = ~satisfaction_pct,
        name = "Cycle 2 (End-Term)",
        type = "scatter",
        mode = "lines+markers",
        line = list(color = OLIVE_PRIMARY, width = 3),
        marker = list(color = OLIVE_PRIMARY, size = 9),
        hovertemplate = "<b>%{x}</b> (Cycle 2)<br>Satisfaction: %{y:.1f}%<extra></extra>"
      ) %>%
      layout(
        yaxis = list(
          title = "Satisfaction Rate (%)",
          range = c(60, 100),
          gridcolor = "#F1F4ED",
          zeroline = FALSE
        ),
        xaxis = list(
          title = "",
          tickangle = -12,
          tickfont = list(size = 11)
        ),
        legend = list(
          orientation = "h",
          x = 0.1, y = 1.15,
          font = list(size = 11)
        ),
        margin = list(t = 20, b = 60, l = 50, r = 20),
        paper_bgcolor = COLOR_WHITE,
        plot_bgcolor = COLOR_WHITE
      ) %>%
      config(displayModeBar = FALSE)
  })

  # HoD Data Table
  output$hod_faculty_table <- renderDT({
    df <- hod_dept_data() %>%
      select(
        `Course Code` = course_code,
        `Course Name` = course_name,
        `Assigned Faculty` = faculty_name,
        `Designation` = faculty_title,
        `Evaluations` = reviews_count,
        `Teaching Score` = avg_teaching_score,
        `Positive %` = positive_pct
      )

    datatable(
      df,
      options = list(
        pageLength = 4,
        dom = "t",
        ordering = FALSE
      ),
      rownames = FALSE
    ) %>%
      formatRound(columns = c("Teaching Score"), digits = 2) %>%
      formatString(columns = c("Positive %"), suffix = "%")
  })

  # ============================================================================
  # 4.3 ADMIN / PRINCIPAL PORTAL OUTPUTS
  # ============================================================================

  # Quota calculations for Tab A
  current_admin_cycle <- reactive({
    if (grepl("Cycle 1", input$admin_cycle_filter)) "Cycle 1" else "Cycle 2"
  })

  admin_quota_data <- reactive({
    DEPARTMENT_QUOTAS %>% filter(cycle == current_admin_cycle())
  })

  output$admin_received_count <- renderText({
    tot <- sum(admin_quota_data()$submitted_count)
    format(tot, big.mark = ",")
  })

  output$admin_completion_rate <- renderText({
    tot_sub <- sum(admin_quota_data()$submitted_count)
    tot_tar <- sum(admin_quota_data()$target_quota)
    sprintf("%.1f%% of overall quota", (tot_sub / tot_tar) * 100)
  })

  output$admin_ready_depts <- renderText({
    ready_count <- sum(admin_quota_data()$status == "READY")
    paste(ready_count, "of 5")
  })

  output$admin_pending_depts <- renderText({
    pending_count <- sum(admin_quota_data()$status == "NOT READY YET")
    paste(pending_count, "Pending")
  })

  # Pre-Deadline Department Progress Bars & Readiness Cards
  output$admin_readiness_cards <- renderUI({
    df <- admin_quota_data()

    tagList(
      lapply(seq_len(nrow(df)), function(i) {
        row <- df[i, ]
        is_ready <- row$status == "READY"
        bar_class <- if (is_ready) "progress-bar-ready" else "progress-bar-pending"
        badge_style <- if (is_ready) {
          "background: #F4F6F0; color: #556B2F; border: 1px solid #D8DFCE; font-weight: 700; padding: 4px 10px; border-radius: 4px; font-size: 0.78rem;"
        } else {
          "background: #FEF3C7; color: #92400E; border: 1px solid #FCD34D; font-weight: 700; padding: 4px 10px; border-radius: 4px; font-size: 0.78rem;"
        }

        div(
          style = "padding: 14px 0; border-bottom: 1px solid #F1F4ED;",
          div(
            style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;",
            div(
              tags$span(style = "font-weight: 700; font-size: 0.92rem; color: #2F3E1B;", row$dept),
              tags$span(style = "font-size: 0.80rem; color: #6B7280; margin-left: 8px;",
                paste0("(", row$submitted_count, " / ", row$target_quota, " Submissions)")
              )
            ),
            div(
              tags$span(style = badge_style, row$status)
            )
          ),
          div(
            class = "progress-custom",
            div(
              class = paste("progress-bar", bar_class),
              style = paste0("width: ", min(row$pct, 100), "%; height: 10px; border-radius: 999px;")
            )
          ),
          div(
            style = "display: flex; justify-content: space-between; font-size: 0.76rem; color: #6B7280; margin-top: 4px;",
            tags$span(paste0("Completion: ", row$pct, "%")),
            tags$span(if (is_ready) "Submission threshold achieved" else "Submissions below required 90% threshold")
          )
        )
      })
    )
  })

  # Tab B - Chart 1: Clean Grouped Bar Chart comparing all departments (no object Object)
  output$admin_grouped_bar_chart <- renderPlotly({
    plot_ly(
      data = COLLEGE_SENTIMENT,
      x = ~dept_short,
      y = ~overall_positive,
      name = "Positive",
      type = "bar",
      marker = list(color = OLIVE_PRIMARY),
      hovertemplate = "<b>%{x}</b><br>Positive: %{y:.1f}%<extra></extra>"
    ) %>%
      add_trace(
        y = ~overall_neutral,
        name = "Neutral",
        marker = list(color = "#A3B18A"),
        hovertemplate = "<b>%{x}</b><br>Neutral: %{y:.1f}%<extra></extra>"
      ) %>%
      add_trace(
        y = ~overall_negative,
        name = "Negative",
        marker = list(color = "#C05621"),
        hovertemplate = "<b>%{x}</b><br>Negative: %{y:.1f}%<extra></extra>"
      ) %>%
      layout(
        barmode = "group",
        yaxis = list(
          title = "Sentiment Breakdown (%)",
          range = c(0, 100),
          gridcolor = "#F1F4ED",
          zeroline = FALSE
        ),
        xaxis = list(
          title = "Engineering Department",
          tickfont = list(size = 11)
        ),
        legend = list(
          orientation = "h",
          x = 0.2, y = 1.15,
          font = list(size = 11)
        ),
        margin = list(t = 20, b = 40, l = 50, r = 20),
        paper_bgcolor = COLOR_WHITE,
        plot_bgcolor = COLOR_WHITE
      ) %>%
      config(displayModeBar = FALSE)
  })

  # Tab B - Chart 2: Simple Trend Line showing sentiment shifts between Cycle 1 and Cycle 2
  output$admin_trend_line_chart <- renderPlotly({
    cycles <- c("Cycle 1", "Cycle 2")

    p <- plot_ly()

    # Distinctive olive/sage/slate line colors
    dept_colors <- c(
      "CSE"   = "#36461D",
      "ECE"   = "#556B2F",
      "MECH"  = "#8F9779",
      "CIVIL" = "#B45309",
      "AI&DS" = "#2F3E1B"
    )

    for (i in seq_len(nrow(COLLEGE_SENTIMENT))) {
      dept_name <- COLLEGE_SENTIMENT$dept_short[i]
      c1_val    <- COLLEGE_SENTIMENT$c1_positive[i]
      c2_val    <- COLLEGE_SENTIMENT$c2_positive[i]

      p <- p %>% add_trace(
        x = cycles,
        y = c(c1_val, c2_val),
        name = dept_name,
        type = "scatter",
        mode = "lines+markers",
        line = list(color = dept_colors[dept_name], width = 2.5),
        marker = list(color = dept_colors[dept_name], size = 8),
        hovertemplate = paste0("<b>", dept_name, "</b><br>%{x}: %{y:.1f}% Positive<extra></extra>")
      )
    }

    p %>%
      layout(
        yaxis = list(
          title = "Positive Sentiment (%)",
          range = c(60, 100),
          gridcolor = "#F1F4ED",
          zeroline = FALSE
        ),
        xaxis = list(
          title = "",
          tickfont = list(size = 11)
        ),
        legend = list(
          orientation = "h",
          x = 0.05, y = 1.15,
          font = list(size = 10)
        ),
        margin = list(t = 20, b = 40, l = 50, r = 20),
        paper_bgcolor = COLOR_WHITE,
        plot_bgcolor = COLOR_WHITE
      ) %>%
      config(displayModeBar = FALSE)
  })

  # Consolidated Departmental Benchmark Table
  output$admin_summary_table <- renderDT({
    df <- COLLEGE_SENTIMENT %>%
      mutate(
        net_shift = round(c2_positive - c1_positive, 1)
      ) %>%
      select(
        `Department` = dept,
        `Total Submissions` = total_submissions,
        `Cycle 1 Positive %` = c1_positive,
        `Cycle 2 Positive %` = c2_positive,
        `Shift (Δ)` = net_shift,
        `Overall Positive %` = overall_positive,
        `Overall Negative %` = overall_negative
      )

    datatable(
      df,
      options = list(
        dom = "t",
        pageLength = 5,
        ordering = FALSE
      ),
      rownames = FALSE
    ) %>%
      formatString(columns = c("Cycle 1 Positive %", "Cycle 2 Positive %", "Overall Positive %", "Overall Negative %"), suffix = "%") %>%
      formatRound(columns = c("Shift (Δ)"), digits = 1)
  })
}

# ------------------------------------------------------------------------------
# 5. APPLICATION LAUNCH
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
