# modules/student_portal.R — Student Course Evaluation & Feedback Portal
# Institutional Design System: Vertical Left Sidebar Navigation + 5 Assigned Subjects Multi-Subject Evaluation Flow

library(shiny)
library(plotly)
library(DT)

# ── Aspect Labels & SVG Icons ──────────────────────────────────────────────────
STUDENT_ASPECT_ICONS <- list(
  teaching = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M22 10v6M2 10l10-5 10 5-10 5z'/><path d='M6 12.5V16a6 3 0 0 0 12 0v-3.5'/></svg>",
  coursecontent = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M4 19.5A2.5 2.5 0 0 1 6.5 17H20'/><path d='M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z'/></svg>",
  examination = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z'/><polyline points='14 2 14 8 20 8'/></svg>",
  labwork = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M10 2v7.31'/><path d='M14 9.3V2'/><path d='M8.5 2h7'/><path d='M14 9.3a6.5 6.5 0 1 1-4 0'/><path d='M5.52 16h12.96'/></svg>"
)

# ══════════════════════════════════════════════════════════════════════════════
#  UI
# ══════════════════════════════════════════════════════════════════════════════
studentPortalUI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head(
      tags$style(HTML("
        /* ── STUDENT PORTAL — INSTITUTIONAL THEME ───────────────────────────── */
        .st-app {
          display: flex;
          min-height: 100vh;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background-color: #f8fafc;
          color: #0f172a;
          font-size: 0.9375rem;
        }

        /* ── VERTICAL SIDEBAR ────────────────────────────────────────────────── */
        .st-sidebar {
          width: 260px;
          background: #ffffff;
          color: #0f172a;
          display: flex;
          flex-direction: column;
          flex-shrink: 0;
          position: fixed;
          top: 0; bottom: 0; left: 0;
          z-index: 100;
          border-right: 1px solid #e2e8f0;
          box-shadow: 1px 0 3px rgba(0, 0, 0, 0.03);
        }
        .st-sidebar-brand {
          padding: 20px 20px;
          display: flex;
          align-items: center;
          gap: 12px;
          border-bottom: 1px solid #e2e8f0;
          background: #ffffff;
        }
        .st-brand-icon {
          width: 38px; height: 38px;
          background: #4d6b1e;
          border-radius: 8px;
          display: flex; align-items: center; justify-content: center;
          color: #ffffff;
          flex-shrink: 0;
        }
        .st-brand-name {
          font-weight: 700;
          font-size: 1.05rem;
          color: #0f172a;
          letter-spacing: -0.02em;
          line-height: 1.2;
        }
        .st-brand-sub { font-size: 0.75rem; color: #64748b; margin-top: 2px; }

        /* Nav */
        .st-nav {
          padding: 16px 12px;
          display: flex;
          flex-direction: column;
          gap: 4px;
          flex: 1;
        }
        .st-nav-section-title {
          font-size: 0.6875rem;
          font-weight: 700;
          color: #94a3b8;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          padding: 12px 14px 6px 14px;
        }
        .st-nav-btn {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 9px 12px;
          border-radius: 6px;
          color: #475569;
          font-size: 0.875rem;
          font-weight: 500;
          background: transparent;
          border: none;
          cursor: pointer;
          width: 100%;
          text-align: left;
          transition: all 0.15s ease;
          position: relative;
        }
        .st-nav-btn:hover {
          background: #f1f5f9;
          color: #0f172a;
        }
        .st-nav-btn.active {
          background: #f0f5e6;
          color: #4d6b1e;
          font-weight: 600;
        }
        .st-nav-btn.active::before {
          content: '';
          position: absolute;
          left: 0;
          top: 4px;
          bottom: 4px;
          width: 3px;
          background: #4d6b1e;
          border-radius: 0 2px 2px 0;
        }
        .st-nav-icon {
          width: 18px; height: 18px;
          display: flex; align-items: center; justify-content: center;
          flex-shrink: 0;
        }

        /* Sidebar user badge & footer */
        .st-sidebar-user {
          padding: 14px 16px;
          border-top: 1px solid #e2e8f0;
          background: #f8fafc;
        }
        .st-user-avatar {
          width: 32px; height: 32px;
          border-radius: 6px;
          background: #4d6b1e;
          color: #ffffff;
          display: flex; align-items: center; justify-content: center;
          font-weight: 700;
          font-size: 0.8125rem;
          flex-shrink: 0;
        }
        .st-user-info { overflow: hidden; }
        .st-user-name { font-weight: 600; font-size: 0.8125rem; color: #0f172a; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .st-user-role { font-size: 0.72rem; color: #64748b; text-transform: uppercase; letter-spacing: 0.04em; }

        /* ── MAIN CONTENT CANVAS ─────────────────────────────────────────────── */
        .st-main {
          margin-left: 260px;
          flex: 1;
          background: #f8fafc;
          min-height: 100vh;
          display: flex;
          flex-direction: column;
        }

        /* Top Bar */
        .st-topbar {
          background: #ffffff;
          border-bottom: 1px solid #e2e8f0;
          padding: 14px 32px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          position: sticky;
          top: 0;
          z-index: 90;
        }
        .st-topbar-title {
          font-size: 1.125rem;
          font-weight: 700;
          color: #0f172a;
          letter-spacing: -0.015em;
          margin: 0;
        }
        .st-topbar-subtitle {
          font-size: 0.8125rem;
          color: #64748b;
          margin: 0;
        }

        /* Content Area */
        .st-content {
          padding: 24px 32px 48px 32px;
          flex: 1;
        }

        /* Card System */
        .st-card {
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
          padding: 20px 24px;
          margin-bottom: 20px;
        }
        .st-card-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 16px;
          padding-bottom: 12px;
          border-bottom: 1px solid #f1f5f9;
        }
        .st-card-title {
          font-size: 0.9375rem;
          font-weight: 700;
          color: #0f172a;
          margin: 0;
          letter-spacing: -0.01em;
          display: flex;
          align-items: center;
          gap: 8px;
        }

        /* Subject Tab Pills */
        .subj-tab-btn {
          padding: 8px 14px;
          border-radius: 6px;
          border: 1px solid #cbd5e1;
          background: #ffffff;
          color: #334155;
          font-size: 0.8125rem;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.15s ease;
          text-align: left;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .subj-tab-btn:hover {
          background: #f8fafc;
          border-color: #94a3b8;
        }
        .subj-tab-btn.active {
          background: #4d6b1e;
          border-color: #3d5516;
          color: #ffffff;
        }
        .subj-tab-btn.done {
          background: #f0fdf4;
          border-color: #86efac;
          color: #166534;
        }
        .subj-tab-btn.done.active {
          background: #4d6b1e;
          border-color: #3d5516;
          color: #ffffff;
        }
      "))
    ),

    div(class = "st-app",
      # ── LEFT VERTICAL SIDEBAR ──────────────────────────────────────────────
      div(class = "st-sidebar",
        # Brand Header
        div(class = "st-sidebar-brand",
          div(class = "st-brand-icon",
            tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="20", height="20",
              fill="none", stroke="currentColor", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
              tags$path(d="M22 10v6M2 10l10-5 10 5-10 5z"),
              tags$path(d="M6 12v5c3 3 9 3 12 0v-5")
            )
          ),
          div(
            div(class = "st-brand-name", "Campus Listen"),
            div(class = "st-brand-sub", "Student Evaluation Portal")
          )
        ),

        # Vertical Navigation Links
        div(class = "st-nav",
          div(class = "st-nav-section-title", "Academic Evaluations"),
          
          tags$button(
            id = ns("nav_evaluation"),
            class = "st-nav-btn active",
            onclick = sprintf("Shiny.setInputValue('%s', 'evaluation', {priority:'event'})", ns("active_tab")),
            div(class = "st-nav-icon",
              tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="16", height="16",
                fill="none", stroke="currentColor", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
                tags$path(d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"),
                tags$polyline(points="14 2 14 8 20 8"),
                tags$line(x1="16", y1="13", x2="8", y2="13"),
                tags$line(x1="16", y1="17", x2="8", y2="17")
              )
            ),
            "5-Subject Evaluation"
          ),

          tags$button(
            id = ns("nav_subjects"),
            class = "st-nav-btn",
            onclick = sprintf("Shiny.setInputValue('%s', 'subjects', {priority:'event'})", ns("active_tab")),
            div(class = "st-nav-icon",
              tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="16", height="16",
                fill="none", stroke="currentColor", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
                tags$path(d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"),
                tags$path(d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z")
              )
            ),
            "My 5 Assigned Subjects"
          ),

          tags$button(
            id = ns("nav_history"),
            class = "st-nav-btn",
            onclick = sprintf("Shiny.setInputValue('%s', 'history', {priority:'event'})", ns("active_tab")),
            div(class = "st-nav-icon",
              tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="16", height="16",
                fill="none", stroke="currentColor", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
                tags$circle(cx="12", cy="12", r="10"),
                tags$polyline(points="12 6 12 12 16 14")
              )
            ),
            "Evaluation History"
          ),

          div(class = "st-nav-section-title", "Institutional Notice"),
          
          tags$button(
            id = ns("nav_notice"),
            class = "st-nav-btn",
            onclick = sprintf("Shiny.setInputValue('%s', 'notice', {priority:'event'})", ns("active_tab")),
            div(class = "st-nav-icon",
              tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="16", height="16",
                fill="none", stroke="currentColor", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
                tags$path(d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"),
                tags$path(d="M13.73 21a2 2 0 0 1-3.46 0")
              )
            ),
            "Institutional Notice"
          )
        ),

        # Student Profile in Sidebar
        div(class = "st-sidebar-user",
          div(style = "display:flex; align-items:center; gap:10px; margin-bottom:12px;",
            uiOutput(ns("student_avatar_box")),
            div(class = "st-user-info",
              uiOutput(ns("student_name_label")),
              uiOutput(ns("student_sem_label"))
            )
          ),
          uiOutput(ns("student_status_pill")),
          div(style = "margin-top:12px;",
            actionButton(ns("btn_logout"), "Sign Out",
              class = "btn btn-outline-secondary btn-sm",
              style = "width:100%; font-size:12px; padding:5px;")
          )
        )
      ),

      # ── MAIN CANVAS ────────────────────────────────────────────────────────
      div(class = "st-main",
        # Top Bar
        div(class = "st-topbar",
          div(
            uiOutput(ns("st_page_title")),
            uiOutput(ns("st_page_subtitle"))
          ),
          div(style = "display:flex; align-items:center; gap:12px;",
            uiOutput(ns("topbar_deadline_chip"))
          )
        ),

        # Content Area
        div(class = "st-content",
          # Official Institutional Notice Banner
          uiOutput(ns("institutional_notice_banner")),

          # Main Active View
          uiOutput(ns("active_view_content"))
        )
      )
    )
  )
}

# ══════════════════════════════════════════════════════════════════════════════
#  SERVER
# ══════════════════════════════════════════════════════════════════════════════
studentPortalServer <- function(id, user, logout_trigger) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    source("helpers/db.R", local = TRUE)

    active_tab <- reactiveVal("evaluation")
    submission_refresh <- reactiveVal(0)
    current_subject_idx <- reactiveVal(1)

    # Active feedback cycle window
    feedback_window <- reactive({
      submission_refresh()
      get_active_feedback_window()
    })

    # Observe tab change
    observeEvent(input$active_tab, {
      active_tab(input$active_tab)
      shinyjs::runjs(sprintf("
        document.querySelectorAll('.st-nav-btn').forEach(b => b.classList.remove('active'));
        const activeBtn = document.getElementById('%s');
        if (activeBtn) activeBtn.classList.add('active');
      ", ns(paste0("nav_", input$active_tab))))
    })

    # Assigned 5 subjects for selected semester and student's department
    assigned_5_subjects <- reactive({
      submission_refresh()
      dept <- user$department %||% "Computer Science & Engineering"
      sem  <- input$eval_semester %||% user$semester %||% "Semester 1"
      get_department_subjects(dept, sem)
    })

    # Student submission history
    student_history_df <- reactive({
      submission_refresh()
      get_student_feedback(user$id)
    })

    # Check if student already submitted feedback for selected semester
    is_semester_submitted <- reactive({
      df <- student_history_df()
      sem <- input$eval_semester %||% user$semester %||% "Semester 1"
      if (nrow(df) == 0) return(FALSE)
      any(!is.na(df$semester) & df$semester == sem)
    })

    # ── SIDEBAR STUDENT LABELS ────────────────────────────────────────────────
    output$student_avatar_box <- renderUI({
      init <- toupper(substr(user$name %||% "Student", 1, 1))
      div(class = "st-user-avatar", init)
    })

    output$student_name_label <- renderUI({
      div(class = "st-user-name", user$name %||% "Student User")
    })

    output$student_sem_label <- renderUI({
      sem <- user$semester %||% "Semester 1"
      dept_short <- if (grepl("Computer", user$department %||% "")) "CSE" else "Dept"
      div(class = "st-user-role", sprintf("%s · %s", dept_short, sem))
    })

    output$student_status_pill <- renderUI({
      done <- is_semester_submitted()
      if (done) {
        div(style = "background:#dcfce7; border:1px solid #86efac; color:#15803d; font-size:11px; font-weight:700; padding:4px 8px; border-radius:4px; text-align:center; text-transform:uppercase; letter-spacing:0.04em;",
          "✓ Evaluation Submitted")
      } else {
        div(style = "background:#fef3c7; border:1px solid #fcd34d; color:#92400e; font-size:11px; font-weight:700; padding:4px 8px; border-radius:4px; text-align:center; text-transform:uppercase; letter-spacing:0.04em;",
          "● Evaluation Pending")
      }
    })

    # ── TOPBAR TITLES & DEADLINE CHIP ──────────────────────────────────────────
    output$st_page_title <- renderUI({
      tab <- active_tab()
      title_txt <- switch(tab,
        evaluation = "5-Subject Academic Evaluation",
        subjects   = "My 5 Assigned Semester Subjects",
        history    = "Evaluation History & Records",
        notice     = "Official Institutional Notice"
      )
      tags$h1(class = "st-topbar-title", title_txt)
    })

    output$st_page_subtitle <- renderUI({
      tab <- active_tab()
      sub_txt <- switch(tab,
        evaluation = "Provide comprehensive ratings and constructive feedback for your 5 assigned semester courses.",
        subjects   = "Official academic curriculum and allocated faculty instructors for your semester.",
        history    = "Review your past feedback submissions, recorded scores, and sentiment analysis.",
        notice     = "Principal & Dean's official announcements, evaluation deadlines, and academic quality policies."
      )
      tags$p(class = "st-topbar-subtitle", sub_txt)
    })

    output$topbar_deadline_chip <- renderUI({
      win <- feedback_window()
      days_lbl <- if (win$days_left > 0) sprintf("%d Days Left", win$days_left) else "Closing Today"
      badge_bg <- if (win$days_left <= 3) "#fef2f2" else "#f0f5e6"
      badge_col <- if (win$days_left <= 3) "#dc2626" else "#4d6b1e"
      badge_border <- if (win$days_left <= 3) "#fecaca" else "#c8dba0"

      div(style = sprintf("background:%s; color:%s; border:1px solid %s; font-size:12px; font-weight:700; padding:5px 12px; border-radius:6px; display:flex; align-items:center; gap:6px;", badge_bg, badge_col, badge_border),
        tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="14", height="14",
          fill="none", stroke="currentColor", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
          tags$circle(cx="12", cy="12", r="10"),
          tags$polyline(points="12 6 12 12 16 14")
        ),
        sprintf("Window Deadline: %s (%s)", format(as.Date(win$deadline_date), "%b %d"), days_lbl)
      )
    })

    # ── INSTITUTIONAL NOTICE BANNER ────────────────────────────────────────────
    output$institutional_notice_banner <- renderUI({
      win <- feedback_window()
      div(style = "background:#ffffff; border:1px solid #e2e8f0; border-left:4px solid #4d6b1e; border-radius:8px; padding:12px 18px; margin-bottom:20px; box-shadow:0 1px 2px rgba(0,0,0,0.02);",
        div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;",
          div(style = "display:flex; align-items:center; gap:10px;",
            div(style = "width:30px; height:30px; background:#f0f5e6; border-radius:6px; display:flex; align-items:center; justify-content:center; color:#4d6b1e; flex-shrink:0;",
              tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="16", height="16", fill="none", stroke="currentColor", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
                tags$path(d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"),
                tags$path(d="M13.73 21a2 2 0 0 1-3.46 0")
              )
            ),
            div(
              strong(style = "color:#0f172a; font-size:0.875rem;", sprintf("Notice: %s", win$term_name)),
              span(style = "color:#475569; font-size:0.8125rem; margin-left:6px;", win$description)
            )
          ),
          span(style = "font-size:0.75rem; color:#64748b; font-weight:600;", sprintf("Active Term: %s", win$term_name))
        )
      )
    })

    # ── DISPATCH MAIN ACTIVE VIEW ──────────────────────────────────────────────
    output$active_view_content <- renderUI({
      tab <- active_tab()
      switch(tab,
        evaluation = uiOutput(ns("view_evaluation")),
        subjects   = uiOutput(ns("view_subjects")),
        history    = uiOutput(ns("view_history")),
        notice     = uiOutput(ns("view_notice"))
      )
    })

    # ══════════════════════════════════════════════════════════════════════════
    #  VIEW 1: 5-SUBJECT EVALUATION FLOW
    # ══════════════════════════════════════════════════════════════════════════
    output$view_evaluation <- renderUI({
      sem <- input$eval_semester %||% user$semester %||% "Semester 1"
      done <- is_semester_submitted()
      subs_df <- assigned_5_subjects()

      tagList(
        # Control Strip: Term Selection & Anonymity
        div(class = "st-card", style = "padding:16px 20px; margin-bottom:16px;",
          fluidRow(
            column(6,
              div(style = "display:flex; align-items:center; gap:8px; margin-bottom:6px;",
                tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="15", height="15",
                  fill="none", stroke="#4d6b1e", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
                  tags$rect(x="3", y="4", width="18", height="18", rx="2", ry="2"),
                  tags$line(x1="16", y1="2", x2="16", y2="6"),
                  tags$line(x1="8", y1="2", x2="8", y2="6"),
                  tags$line(x1="3", y1="10", x2="21", y2="10")
                ),
                strong(style = "color:#0f172a; font-size:0.875rem;", "Academic Term / Semester")
              ),
              selectInput(ns("eval_semester"), label = NULL,
                choices = paste("Semester", 1:8),
                selected = sem,
                width = "100%")
            ),
            column(6,
              div(style = "display:flex; align-items:center; justify-content:space-between; padding:8px 14px; background:#f8fafc; border:1px solid #e2e8f0; border-radius:6px; margin-top:2px;",
                div(
                  strong(style = "color:#0f172a; font-size:0.84rem; display:block;", "Anonymous Evaluation"),
                  span(style = "color:#64748b; font-size:0.75rem;", "Disconnect student identity from submitted records")
                ),
                checkboxInput(ns("anon_toggle"), label = NULL, value = FALSE)
              )
            )
          )
        ),

        if (done) {
          # ALREADY SUBMITTED VIEW
          sem_history <- student_history_df()
          sem_entries <- sem_history[!is.na(sem_history$semester) & sem_history$semester == sem, ]
          
          tagList(
            div(style = "background:#f0fdf4; border:1px solid #bbf7d0; border-left:4px solid #059669; border-radius:8px; padding:18px 22px; margin-bottom:20px;",
              div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px;",
                div(
                  h3(style = "margin:0 0 4px 0; color:#065f46; font-size:1.05rem; font-weight:700;",
                    sprintf("✓ Evaluation Completed for %s", sem)),
                  p(style = "margin:0; color:#047857; font-size:0.84rem;",
                    sprintf("All 5 assigned subjects for %s have been successfully submitted and verified in the central registry.", sem))
                ),
                span(style = "background:#dcfce7; color:#15803d; font-weight:700; font-size:0.75rem; padding:4px 12px; border-radius:4px; border:1px solid #86efac; text-transform:uppercase;",
                  "Submitted")
              )
            ),

            div(class = "st-card",
              div(class = "st-card-header",
                tags$h3(class = "st-card-title", "Recorded Subject Evaluations for this Term"),
                span(style = "font-size:0.75rem; color:#64748b; font-weight:600;", sprintf("%d total feedback entries", nrow(sem_entries)))
              ),
              lapply(seq_len(nrow(sem_entries)), function(i) {
                r <- sem_entries[i, ]
                rating_lbl <- if (r$rating == 1) "Positive (4-5)" else if (r$rating == 0) "Neutral (3)" else "Needs Work (1-2)"
                badge_col  <- if (r$rating == 1) "#059669" else if (r$rating == 0) "#d97706" else "#dc2626"
                div(style = "padding:12px 14px; border-bottom:1px solid #f1f5f9; display:flex; justify-content:space-between; align-items:center;",
                  div(
                    strong(style = "color:#0f172a; font-size:0.875rem;", r$course_name %||% "General Academic"),
                    div(style = "color:#64748b; font-size:0.78rem; margin-top:2px;",
                      sprintf("Instructor: %s · Dimension: %s", r$teacher_name %||% "Department Faculty", tools::toTitleCase(gsub("_", " ", r$aspect))))
                  ),
                  div(style = "text-align:right;",
                    span(style = sprintf("color:%s; font-weight:700; font-size:0.8125rem;", badge_col), rating_lbl),
                    div(style = "font-size:0.72rem; color:#94a3b8; margin-top:2px;", format(as.POSIXct(r$created_at), "%b %d, %Y"))
                  )
                )
              })
            )
          )
        } else {
          # PENDING 5-SUBJECT EVALUATION FORM
          tagList(
            div(style = "background:#fffbeb; border:1px solid #fde68a; border-left:4px solid #d97706; border-radius:8px; padding:14px 18px; margin-bottom:18px;",
              div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px;",
                div(
                  strong(style = "color:#92400e; font-size:0.875rem; display:block;", sprintf("Evaluation Pending: %s (5 Assigned Subjects)", sem)),
                  span(style = "color:#b45309; font-size:0.8125rem;", "Please complete the evaluation sections below for each of the 5 assigned subjects in your semester curriculum.")
                ),
                span(style = "background:#fef3c7; color:#b45309; font-weight:700; font-size:0.75rem; padding:3px 9px; border-radius:4px; border:1px solid #fcd34d; text-transform:uppercase;",
                  "5 Subjects Required")
              )
            ),

            # 5-Subject Navigation Pills Bar
            div(class = "st-card", style = "padding:16px 20px; margin-bottom:18px;",
              div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;",
                strong(style = "color:#0f172a; font-size:0.875rem;", "5 Assigned Subjects for Evaluation"),
                span(style = "font-size:0.75rem; color:#64748b;", "Click any subject pill to jump")
              ),
              div(style = "display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:8px;",
                lapply(1:min(5, nrow(subs_df)), function(idx) {
                  subj <- subs_df[idx, ]
                  is_curr <- (idx == current_subject_idx())
                  btn_cls <- if (is_curr) "subj-tab-btn active" else "subj-tab-btn"
                  tags$button(
                    class = btn_cls,
                    onclick = sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})", ns("jump_subject"), idx),
                    div(style = "width:20px; height:20px; border-radius:50%; background:%s; color:%s; display:flex; align-items:center; justify-content:center; font-size:10px; font-weight:700;",
                      if (is_curr) "#ffffff" else "#e2e8f0",
                      if (is_curr) "#4d6b1e" else "#475569",
                      idx
                    ),
                    div(
                      div(style = "font-weight:700; font-size:0.78rem; line-height:1.2;", subj$course_code),
                      div(style = "font-size:0.72rem; opacity:0.85; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:130px;", subj$course_name)
                    )
                  )
                })
              )
            ),

            # Active Subject Evaluation Card
            uiOutput(ns("active_subject_form_card")),

            # Bottom Wizard Controls & Final Submit Button
            div(class = "st-card", style = "padding:16px 20px; display:flex; justify-content:space-between; align-items:center;",
              uiOutput(ns("subject_wizard_prev_btn")),
              uiOutput(ns("subject_wizard_next_btn"))
            ),

            uiOutput(ns("submit_result"))
          )
        }
      )
    })

    # Jump to subject
    observeEvent(input$jump_subject, {
      current_subject_idx(as.integer(input$jump_subject))
    })

    observeEvent(input$btn_subj_prev, {
      current_subject_idx(max(1, current_subject_idx() - 1))
    })

    observeEvent(input$btn_subj_next, {
      current_subject_idx(min(5, current_subject_idx() + 1))
    })

    # ── ACTIVE SUBJECT EVALUATION FORM CARD ────────────────────────────────────
    output$active_subject_form_card <- renderUI({
      subs_df <- assigned_5_subjects()
      idx <- current_subject_idx()
      if (nrow(subs_df) == 0 || idx > nrow(subs_df)) {
        return(div(class = "st-card", "No assigned subjects found for this semester."))
      }

      subj <- subs_df[idx, ]
      prefix <- paste0("subj_", idx)

      div(class = "st-card",
        # Subject Overview Header
        div(style = "background:#f8fafc; border:1px solid #e2e8f0; border-radius:6px; padding:14px 18px; margin-bottom:18px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;",
          div(
            div(style = "display:flex; align-items:center; gap:8px;",
              span(style = "background:#4d6b1e; color:#ffffff; font-weight:700; font-size:0.75rem; padding:2px 8px; border-radius:4px;", sprintf("Subject %d of 5", idx)),
              strong(style = "color:#0f172a; font-size:1.05rem;", sprintf("%s: %s", subj$course_code, subj$course_name))
            ),
            div(style = "color:#64748b; font-size:0.8125rem; margin-top:3px;",
              sprintf("Department: %s · Academic Credits: %d Credits", subj$department, subj$credits))
          ),
          div(style = "text-align:right;",
            span(style = "font-size:0.75rem; color:#64748b; display:block;", "Allocated Professor"),
            strong(style = "color:#4d6b1e; font-size:0.9rem;", subj$teacher_name %||% "Assigned Faculty")
          )
        ),

        # 4 Core Evaluation Dimensions
        fluidRow(
          column(6,
            div(style = "padding:14px 16px; background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; margin-bottom:14px;",
              div(style = "display:flex; align-items:center; gap:8px; margin-bottom:10px;",
                HTML(STUDENT_ASPECT_ICONS$teaching),
                strong(style = "color:#0f172a; font-size:0.875rem;", "1. Instructional Quality & Concept Clarity")
              ),
              sliderInput(ns(paste0(prefix, "_teaching")), label = "Clarity of explanations & pacing (1 Poor to 5 Excellent)",
                min = 1, max = 5, value = 4, step = 1, width = "100%")
            )
          ),
          column(6,
            div(style = "padding:14px 16px; background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; margin-bottom:14px;",
              div(style = "display:flex; align-items:center; gap:8px; margin-bottom:10px;",
                HTML(STUDENT_ASPECT_ICONS$coursecontent),
                strong(style = "color:#0f172a; font-size:0.875rem;", "2. Syllabus Coverage & Study Materials")
              ),
              sliderInput(ns(paste0(prefix, "_content")), label = "Study notes, slides & syllabus relevance (1 Poor to 5 Excellent)",
                min = 1, max = 5, value = 4, step = 1, width = "100%")
            )
          )
        ),

        fluidRow(
          column(6,
            div(style = "padding:14px 16px; background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; margin-bottom:14px;",
              div(style = "display:flex; align-items:center; gap:8px; margin-bottom:10px;",
                HTML(STUDENT_ASPECT_ICONS$examination),
                strong(style = "color:#0f172a; font-size:0.875rem;", "3. Evaluation Fairness & Internal Assessment")
              ),
              sliderInput(ns(paste0(prefix, "_exam")), label = "Fairness in grading & test schedule (1 Poor to 5 Excellent)",
                min = 1, max = 5, value = 4, step = 1, width = "100%")
            )
          ),
          column(6,
            div(style = "padding:14px 16px; background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; margin-bottom:14px;",
              div(style = "display:flex; align-items:center; gap:8px; margin-bottom:10px;",
                HTML(STUDENT_ASPECT_ICONS$labwork),
                strong(style = "color:#0f172a; font-size:0.875rem;", "4. Practical Application & Lab Support")
              ),
              sliderInput(ns(paste0(prefix, "_lab")), label = "Hands-on lab work & teacher support (1 Poor to 5 Excellent)",
                min = 1, max = 5, value = 4, step = 1, width = "100%")
            )
          )
        ),

        # Qualitative Comments Text
        div(style = "margin-top:6px;",
          strong(style = "color:#0f172a; font-size:0.875rem; display:block; margin-bottom:6px;",
            sprintf("Constructive Feedback for %s (%s)", subj$course_name, subj$teacher_name %||% "Faculty")),
          textAreaInput(ns(paste0(prefix, "_comments")), label = NULL,
            placeholder = sprintf("Provide specific comments regarding teaching quality, problem solving, lab experiments, or suggestions for %s...", subj$course_name),
            rows = 3, width = "100%")
        )
      )
    })

    # Wizard Navigation Buttons
    output$subject_wizard_prev_btn <- renderUI({
      idx <- current_subject_idx()
      if (idx > 1) {
        actionButton(ns("btn_subj_prev"), "← Previous Subject",
          class = "btn btn-outline-secondary",
          style = "font-weight:600; font-size:13px;")
      } else {
        tags$span(style = "color:#64748b; font-size:0.8125rem;", "Subject 1 of 5")
      }
    })

    output$subject_wizard_next_btn <- renderUI({
      idx <- current_subject_idx()
      if (idx < 5) {
        actionButton(ns("btn_subj_next"), "Save & Next Subject →",
          class = "btn btn-primary",
          style = "font-weight:600; font-size:13px;")
      } else {
        actionButton(ns("btn_submit_5_subjects"), "Submit 5-Subject Semester Evaluation",
          class = "btn btn-primary",
          style = "background:#059669 !important; border-color:#047857 !important; font-weight:700; font-size:13.5px; padding:8px 24px;")
      }
    })

    # ── 5-SUBJECT FINAL SUBMIT HANDLER ─────────────────────────────────────────
    observeEvent(input$btn_submit_5_subjects, {
      req(user$id)
      subs_df <- assigned_5_subjects()
      if (nrow(subs_df) == 0) return()

      sem  <- input$eval_semester %||% user$semester %||% "Semester 1"
      dept <- user$department %||% "Computer Science & Engineering"
      anon <- isTRUE(input$anon_toggle)

      count_inserted <- 0
      for (i in 1:min(5, nrow(subs_df))) {
        subj <- subs_df[i, ]
        prefix <- paste0("subj_", i)

        # Retrieve ratings
        r_teaching <- input[[paste0(prefix, "_teaching")]] %||% 4
        r_content  <- input[[paste0(prefix, "_content")]]  %||% 4
        r_exam     <- input[[paste0(prefix, "_exam")]]     %||% 4
        r_lab      <- input[[paste0(prefix, "_lab")]]      %||% 4
        
        comments_txt <- trimws(input[[paste0(prefix, "_comments")]] %||% "")
        if (comments_txt == "") {
          comments_txt <- sprintf("Structured 5-subject evaluation submitted for %s.", subj$course_name)
        }

        # Calculate average rating
        avg_score <- mean(c(r_teaching, r_content, r_exam, r_lab))
        calc_rating <- if (avg_score < 2.5) -1L else if (avg_score < 3.5) 0L else 1L
        emotion <- if (calc_rating == 1) "positive" else if (calc_rating == -1) "negative" else "neutral"

        sub_json <- sprintf('{"teaching":%d,"content":%d,"exam":%d,"lab":%d}',
                            r_teaching, r_content, r_exam, r_lab)

        # Insert Feedback for this course
        insert_feedback(
          student_id   = user$id,
          anonymous    = anon,
          faculty_id   = subj$faculty_id,
          aspect       = "teaching",
          rating       = calc_rating,
          text         = comments_txt,
          sub_ratings  = sub_json,
          emotion_tag  = emotion,
          semester     = sem,
          course_id    = subj$course_id,
          department   = dept
        )
        count_inserted <- count_inserted + 1
      }

      submission_refresh(submission_refresh() + 1)
      current_subject_idx(1)

      output$submit_result <- renderUI({
        div(style = "margin-top:16px; padding:16px 20px; background:#f0fdf4; border:1px solid #bbf7d0; border-radius:8px; color:#065f46;",
          div(style = "font-weight:700; font-size:1rem; margin-bottom:4px;", "✓ All 5 Subject Evaluations Successfully Submitted!"),
          p(style = "margin:0; font-size:0.875rem; color:#047857;",
            sprintf("Your evaluations for all 5 assigned courses in %s have been authenticated and logged in the institutional database.", sem))
        )
      })
    })

    # ══════════════════════════════════════════════════════════════════════════
    #  VIEW 2: MY 5 ASSIGNED SUBJECTS
    # ══════════════════════════════════════════════════════════════════════════
    output$view_subjects <- renderUI({
      sem <- input$eval_semester %||% user$semester %||% "Semester 1"
      subs_df <- assigned_5_subjects()

      div(class = "st-card",
        div(class = "st-card-header",
          tags$h3(class = "st-card-title",
            tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="16", height="16",
              fill="none", stroke="#4d6b1e", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
              tags$path(d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"),
              tags$path(d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z")
            ),
            sprintf("Official Curriculum — 5 Assigned Subjects for %s", sem)
          ),
          span(style = "font-size:0.75rem; color:#64748b; font-weight:600;", user$department %||% "Engineering")
        ),

        if (nrow(subs_df) == 0) {
          p("No courses found for this term.")
        } else {
          div(style = "display:flex; flex-direction:column; gap:10px;",
            lapply(seq_len(nrow(subs_df)), function(i) {
              r <- subs_df[i, ]
              div(style = "padding:14px 18px; background:#f8fafc; border:1px solid #e2e8f0; border-radius:6px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px;",
                div(
                  div(style = "display:flex; align-items:center; gap:8px;",
                    span(style = "background:#4d6b1e; color:#ffffff; font-weight:700; font-size:0.75rem; padding:2px 8px; border-radius:4px;", sprintf("Subject %d", i)),
                    strong(style = "color:#0f172a; font-size:0.9375rem;", sprintf("%s: %s", r$course_code, r$course_name))
                  ),
                  div(style = "color:#64748b; font-size:0.8125rem; margin-top:4px;",
                    sprintf("%s · %d Academic Credits · %s", r$department, r$credits, r$semester))
                ),
                div(style = "text-align:right;",
                  span(style = "font-size:0.72rem; color:#64748b; display:block;", "Assigned Professor"),
                  strong(style = "color:#4d6b1e; font-size:0.875rem;", r$teacher_name %||% "Department Faculty"),
                  div(style = "font-size:0.75rem; color:#64748b; margin-top:2px;", r$teacher_email %||% "")
                )
              )
            })
          )
        }
      )
    })

    # ══════════════════════════════════════════════════════════════════════════
    #  VIEW 3: SUBMISSION HISTORY
    # ══════════════════════════════════════════════════════════════════════════
    output$view_history <- renderUI({
      div(class = "st-card",
        div(class = "st-card-header",
          tags$h3(class = "st-card-title", "My Evaluation Records & History"),
          uiOutput(ns("history_count_badge"))
        ),
        DT::dataTableOutput(ns("history_dt_table"))
      )
    })

    output$history_count_badge <- renderUI({
      df <- student_history_df()
      tags$span(style = "color:#64748b; font-size:0.8125rem; font-weight:600;", sprintf("%d records logged", nrow(df)))
    })

    output$history_dt_table <- DT::renderDataTable({
      df <- student_history_df()
      if (nrow(df) == 0) {
        return(data.frame(Status = "No prior evaluations found."))
      }

      df$Sentiment <- ifelse(df$rating == 1, "Positive",
                      ifelse(df$rating == 0, "Neutral", "Negative"))
      df$Course <- ifelse(is.na(df$course_name) | df$course_name == "", "General", df$course_name)
      df$Instructor <- ifelse(is.na(df$teacher_name) | df$teacher_name == "", "Faculty", df$teacher_name)
      df$Timestamp <- format(as.POSIXct(df$created_at), "%b %d, %Y %H:%M")

      display_df <- df[, c("Timestamp", "semester", "Course", "Instructor", "Sentiment", "text")]
      names(display_df) <- c("Timestamp", "Semester", "Course", "Instructor", "Rating", "Comments")

      DT::datatable(
        display_df,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'frtip'
        ),
        rownames = FALSE
      )
    })

    # ══════════════════════════════════════════════════════════════════════════
    #  VIEW 4: INSTITUTIONAL NOTICE
    # ══════════════════════════════════════════════════════════════════════════
    output$view_notice <- renderUI({
      win <- feedback_window()

      div(class = "st-card",
        div(class = "st-card-header",
          tags$h3(class = "st-card-title",
            tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="16", height="16",
              fill="none", stroke="#4d6b1e", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
              tags$path(d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"),
              tags$path(d="M13.73 21a2 2 0 0 1-3.46 0")
            ),
            "Office of the Principal — Feedback Cycle Policy"
          ),
          span(style = "background:#f0f5e6; color:#4d6b1e; font-size:0.75rem; font-weight:700; padding:3px 9px; border-radius:4px; border:1px solid #c8dba0;",
            win$term_name)
        ),

        div(style = "line-height:1.6; color:#334155; font-size:0.9rem;",
          tags$p(strong("Academic Feedback Policy & Instructions:")),
          tags$ul(style = "padding-left:20px;",
            tags$li("Every enrolled student must submit formal evaluations for each of their ", strong("5 assigned academic subjects"), " per semester."),
            tags$li("Feedback submissions directly inform faculty performance reviews, curriculum restructuring, and accreditation standards (NBA/NAAC)."),
            tags$li("Anonymous submissions disconnect student identity from responses while preserving authentication verification."),
            tags$li(sprintf("The active submission window will strictly close on %s at 23:59 IST.", format(as.Date(win$deadline_date), "%B %d, %Y")))
          ),
          div(style = "margin-top:20px; padding:14px 18px; background:#f8fafc; border:1px solid #e2e8f0; border-radius:6px; font-size:0.8125rem; color:#64748b;",
            "For technical support or course assignment corrections, contact the College Academic Registrar at academic@college.edu."
          )
        )
      )
    })

    # Logout trigger
    observeEvent(input$btn_logout, {
      logout_trigger(logout_trigger() + 1)
    })
  })
}
