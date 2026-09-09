# modules/faculty_portal.R — Faculty Insights Dashboard
# Institutional Design System: Deep Blue (#1e40af) + 4 Assigned Subjects Breakdown + Precise Analytics

library(shiny)
library(plotly)
library(DT)

# ── Aspect Constants & Clean SVG Icons ────────────────────────────────────────
FACULTY_ASPECT_LABELS <- c(
  teaching           = "Teaching Quality",
  coursecontent      = "Course Content",
  examination        = "Examination",
  labwork            = "Lab Facilities",
  library_facilities = "Library & Resources",
  extracurricular    = "Extracurricular"
)

FACULTY_ASPECT_ICONS <- c(
  teaching           = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M22 10v6M2 10l10-5 10 5-10 5z'/><path d='M6 12.5V16a6 3 0 0 0 12 0v-3.5'/></svg>",
  coursecontent      = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M4 19.5A2.5 2.5 0 0 1 6.5 17H20'/><path d='M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z'/></svg>",
  examination        = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z'/><polyline points='14 2 14 8 20 8'/><line x1='16' y1='13' x2='8' y2='13'/><line x1='16' y1='17' x2='8' y2='17'/></svg>",
  labwork            = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M10 2v7.31'/><path d='M14 9.3V2'/><path d='M8.5 2h7'/><path d='M14 9.3a6.5 6.5 0 1 1-4 0'/><path d='M5.52 16h12.96'/></svg>",
  library_facilities = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='m16 6 4 14'/><path d='M12 6v14'/><path d='M8 8v12'/><path d='M4 4v16'/></svg>",
  extracurricular    = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='8' r='6'/><path d='M15.477 12.89 17 22l-5-3-5 3 1.523-9.11'/></svg>"
)

ALL_ASPECTS <- names(FACULTY_ASPECT_LABELS)

# ══════════════════════════════════════════════════════════════════════════════
#  UI
# ══════════════════════════════════════════════════════════════════════════════
facultyPortalUI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head(
      tags$style(HTML("
        /* ── FACULTY PORTAL — INSTITUTIONAL THEME ───────────────────────────── */
        .fc-app {
          display: flex;
          min-height: 100vh;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background-color: #f8fafc;
          color: #0f172a;
          font-size: 0.9375rem;
        }

        /* ── SIDEBAR ─────────────────────────────────────────────────────────── */
        .fc-sidebar {
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
        .fc-sidebar-brand {
          padding: 20px 20px;
          display: flex;
          align-items: center;
          gap: 12px;
          border-bottom: 1px solid #e2e8f0;
          background: #ffffff;
        }
        .fc-brand-icon {
          width: 38px; height: 38px;
          background: #1e40af;
          border-radius: 8px;
          display: flex; align-items: center; justify-content: center;
          color: #ffffff;
          flex-shrink: 0;
        }
        .fc-brand-name {
          font-weight: 700;
          font-size: 1.05rem;
          color: #0f172a;
          letter-spacing: -0.02em;
          line-height: 1.2;
        }
        .fc-brand-sub { font-size: 0.75rem; color: #64748b; margin-top: 2px; }

        /* Nav */
        .fc-nav {
          padding: 16px 12px;
          display: flex;
          flex-direction: column;
          gap: 4px;
          flex: 1;
        }
        .fc-nav-section-title {
          font-size: 0.6875rem;
          font-weight: 700;
          color: #94a3b8;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          padding: 12px 14px 6px 14px;
        }
        .fc-nav-btn {
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
        }
        .fc-nav-btn:hover { background: #f1f5f9; color: #0f172a; }
        .fc-nav-btn.active {
          background: #eff6ff !important;
          color: #1e40af !important;
          font-weight: 600;
          border-left: 3px solid #1e40af;
        }
        .fc-nav-btn.active svg { stroke: #1e40af !important; }

        /* Sidebar footer */
        .fc-sidebar-user {
          padding: 16px 18px;
          border-top: 1px solid #e2e8f0;
          display: flex;
          align-items: center;
          justify-content: space-between;
          background: #ffffff;
        }
        .fc-user-info { display: flex; flex-direction: column; gap: 1px; }
        .fc-user-name { font-weight: 600; font-size: 0.875rem; color: #0f172a; }
        .fc-user-role { font-size: 0.75rem; color: #64748b; }

        /* ── MAIN CANVAS ─────────────────────────────────────────────────────── */
        .fc-main {
          margin-left: 260px;
          flex: 1;
          display: flex;
          flex-direction: column;
          min-width: 0;
        }
        .fc-header {
          background: #ffffff;
          border-bottom: 1px solid #e2e8f0;
          padding: 16px 28px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          position: sticky;
          top: 0;
          z-index: 90;
        }
        .fc-header-title {
          font-size: 1.25rem;
          font-weight: 700;
          color: #0f172a;
          margin: 0;
          letter-spacing: -0.02em;
        }
        .fc-header-sub { font-size: 0.8125rem; color: #64748b; margin: 2px 0 0 0; }

        /* Filter bar */
        .fc-filter-bar { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .fc-filter-item {
          display: flex;
          align-items: center;
          gap: 6px;
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 6px;
          padding: 4px 10px;
        }
        .fc-filter-item label, .fc-filter-item .control-label {
          margin: 0 !important;
          font-size: 0.75rem !important;
          font-weight: 600 !important;
          color: #64748b !important;
          text-transform: uppercase !important;
          letter-spacing: 0.04em !important;
        }
        .fc-filter-item select {
          border: none !important;
          background: transparent !important;
          font-size: 0.84rem !important;
          color: #0f172a !important;
          font-weight: 600 !important;
          outline: none !important;
          cursor: pointer !important;
          padding: 2px 4px !important;
        }

        .fc-body { padding: 24px 28px 48px 28px; flex: 1; }

        /* ── CARDS ────────────────────────────────────────────────────────────── */
        .fc-card {
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 20px 22px;
          margin-bottom: 20px;
          box-shadow: 0 1px 2px rgba(0,0,0,0.03);
        }
        .fc-card-title {
          font-size: 0.9375rem;
          font-weight: 700;
          color: #0f172a;
          margin: 0 0 4px 0;
          display: flex; align-items: center; gap: 8px;
        }
        .fc-card-sub { font-size: 0.8125rem; color: #64748b; margin: 0 0 16px 0; }

        /* KPI Grid */
        .fc-kpi-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 16px;
          margin-bottom: 20px;
        }
        .fc-kpi-card {
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 16px 18px;
          display: flex;
          flex-direction: column;
          gap: 6px;
          box-shadow: 0 1px 2px rgba(0,0,0,0.02);
          border-left: 3px solid #1e40af;
        }
        .fc-kpi-card.tot { border-left-color: #1e40af; }
        .fc-kpi-card.pos { border-left-color: #059669; }
        .fc-kpi-card.neg { border-left-color: #dc2626; }
        .fc-kpi-card.neu { border-left-color: #d97706; }
        .fc-kpi-label {
          font-size: 0.6875rem; font-weight: 700;
          text-transform: uppercase; letter-spacing: 0.06em; color: #64748b;
        }
        .fc-kpi-value { font-size: 1.875rem; font-weight: 700; color: #0f172a; line-height: 1.1; }
        .fc-kpi-sub { font-size: 0.75rem; color: #64748b; }
        .fc-progress {
          width: 100%; height: 5px;
          background: #f1f5f9;
          border-radius: 9999px;
          overflow: hidden;
          margin-top: 4px;
        }
        .fc-progress-bar { height: 100%; border-radius: 9999px; }

        /* Assigned 4 Courses Grid */
        .fc-courses-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 14px;
          margin-bottom: 20px;
        }
        .fc-course-card {
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 14px 16px;
          border-top: 3px solid #1e40af;
          transition: border-color 0.15s;
        }
        .fc-course-code {
          font-size: 0.72rem;
          font-weight: 700;
          color: #1e40af;
          text-transform: uppercase;
          letter-spacing: 0.04em;
        }
        .fc-course-title {
          font-weight: 700;
          font-size: 0.88rem;
          color: #0f172a;
          margin: 4px 0;
          line-height: 1.3;
        }
        .fc-course-meta {
          font-size: 0.75rem;
          color: #64748b;
        }

        /* Aspect row bars */
        .fc-aspect-row {
          display: flex; align-items: center; gap: 12px;
          padding: 10px 14px;
          border-radius: 6px;
          border: 1px solid #f1f5f9;
          margin-bottom: 8px;
          background: #ffffff;
          transition: background 0.15s;
        }
        .fc-aspect-row:hover { background: #f8fafc; border-color: #e2e8f0; }
        .fc-aspect-icon-wrap {
          width: 28px; height: 28px; border-radius: 6px;
          background: #f1f5f9; color: #1e40af;
          display: flex; align-items: center; justify-content: center;
          flex-shrink: 0;
        }
        .fc-aspect-label { font-weight: 600; font-size: 0.84rem; color: #0f172a; min-width: 140px; }
        .fc-aspect-bar-wrap { flex: 1; height: 6px; background: #f1f5f9; border-radius: 9999px; overflow: hidden; }
        .fc-aspect-bar-fill { height: 100%; border-radius: 9999px; }
        .fc-aspect-pct { font-size: 0.8125rem; font-weight: 600; color: #1e40af; min-width: 40px; text-align: right; }
        .fc-aspect-count { font-size: 0.75rem; color: #94a3b8; min-width: 50px; text-align: right; }

        /* Comment cards */
        .fc-comment-card {
          padding: 14px 16px;
          background: #f8fafc;
          border: 1px solid #e2e8f0;
          border-left: 3px solid #059669;
          border-radius: 0 6px 6px 0;
          margin-bottom: 10px;
        }
        .fc-comment-text {
          color: #0f172a; font-size: 0.84rem;
          margin: 0 0 6px 0; line-height: 1.5;
        }
        .fc-comment-meta { font-size: 0.75rem; color: #64748b; margin: 0; }
        .fc-comment-card.negative {
          border-left-color: #dc2626;
          background: #fef2f2;
        }

        /* Profile section */
        .fc-profile-avatar {
          width: 56px; height: 56px;
          background: #1e40af;
          border-radius: 8px;
          display: flex; align-items: center; justify-content: center;
          color: #ffffff;
          flex-shrink: 0;
        }
        .fc-profile-badge {
          display: inline-flex; align-items: center;
          background: #f1f5f9; color: #334155;
          font-size: 0.75rem; font-weight: 600;
          padding: 3px 9px; border-radius: 4px;
          border: 1px solid #e2e8f0;
        }
        .fc-stat-box {
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 14px 16px;
          text-align: center;
        }
        .fc-stat-val { font-size: 1.625rem; font-weight: 700; color: #0f172a; }
        .fc-stat-lbl { font-size: 0.75rem; color: #64748b; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; }

        /* Responsive */
        @media (max-width: 900px) {
          .fc-sidebar { width: 64px; }
          .fc-brand-name, .fc-brand-sub, .fc-nav-btn span, .fc-nav-section-title, .fc-user-info { display: none; }
          .fc-main { margin-left: 64px; }
          .fc-kpi-grid, .fc-courses-grid { grid-template-columns: repeat(2,1fr); }
          .fc-body { padding: 16px; }
        }
      "))
    ),

    div(class = "fc-app",

      # ── SIDEBAR ──────────────────────────────────────────────────────────────
      div(class = "fc-sidebar",

        div(class = "fc-sidebar-brand",
          div(class = "fc-brand-icon",
            tags$svg(xmlns = "http://www.w3.org/2000/svg", viewBox = "0 0 24 24", width = "20", height = "20",
                     fill = "none", stroke = "#ffffff", strokeWidth = "2", strokeLinecap = "round", strokeLinejoin = "round",
                     tags$path(d = "M22 10v6M2 10l10-5 10 5-10 5z"),
                     tags$path(d = "M6 12.5V16a6 3 0 0 0 12 0v-3.5"))
          ),
          div(
            div(class = "fc-brand-name", "Campus Listen"),
            div(class = "fc-brand-sub", "Faculty Portal")
          )
        ),

        div(class = "fc-nav",
          div(class = "fc-nav-section-title", "MY DASHBOARD"),
          uiOutput(ns("fc_sidebar_nav"))
        ),

        div(class = "fc-sidebar-user",
          div(class = "fc-user-info",
            uiOutput(ns("fc_user_name_ui")),
            span(class = "fc-user-role", "Faculty Member")
          ),
          actionButton(ns("btn_logout"), label = NULL,
            icon = icon("sign-out-alt"),
            style = "background:transparent;border:none;color:#64748b;font-size:1rem;cursor:pointer;",
            title = "Logout")
        )
      ),

      # ── MAIN CANVAS ──────────────────────────────────────────────────────────
      div(class = "fc-main",

        div(class = "fc-header",
          div(uiOutput(ns("fc_header_title_ui"))),
          div(class = "fc-filter-bar",
            div(class = "fc-filter-item",
              selectInput(ns("fc_course_filter"), label = "Subject",
                choices = c("All Assigned Subjects" = "all"), width = "180px")
            ),
            div(class = "fc-filter-item",
              selectInput(ns("fc_semester_filter"), label = "Semester",
                choices = c("All Semesters" = "all"), width = "130px")
            ),
            div(class = "fc-filter-item",
              selectInput(ns("fc_aspect_filter"), label = "Aspect",
                choices = c("All Aspects" = "all",
                  "Teaching"        = "teaching",
                  "Course Content"  = "coursecontent",
                  "Examination"     = "examination",
                  "Lab Work"        = "labwork",
                  "Library"         = "library_facilities",
                  "Extracurricular" = "extracurricular"),
                width = "140px")
            )
          )
        ),

        div(class = "fc-body",
          uiOutput(ns("fc_tab_content_ui"))
        )
      )
    )
  )
}

# ══════════════════════════════════════════════════════════════════════════════
#  SERVER
# ══════════════════════════════════════════════════════════════════════════════
facultyPortalServer <- function(id, user, logout_trigger) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    source("helpers/db.R",  local = TRUE)
    source("helpers/nlp.R", local = TRUE)

    # ── State ─────────────────────────────────────────────────────────────────
    active_tab <- reactiveVal("overview")
    observeEvent(input$fc_nav_click, { active_tab(input$fc_nav_click) })

    # ── Sidebar Nav ───────────────────────────────────────────────────────────
    output$fc_sidebar_nav <- renderUI({
      cur <- active_tab()
      tabs <- list(
        list(id = "overview",  label = "Overview",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect width='7' height='9' x='3' y='3' rx='1'/><rect width='7' height='5' x='14' y='3' rx='1'/><rect width='7' height='9' x='14' y='12' rx='1'/><rect width='7' height='5' x='3' y='16' rx='1'/></svg>"),
        list(id = "trends",    label = "Sentiment Trends",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='22 7 13.5 15.5 8.5 10.5 2 17'/><polyline points='16 7 22 7 22 13'/></svg>"),
        list(id = "comments",  label = "Student Comments",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z'/></svg>"),
        list(id = "profile",   label = "My Profile",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2'/><circle cx='12' cy='7' r='4'/></svg>")
      )
      lapply(tabs, function(t) {
        cls <- if (cur == t$id) "fc-nav-btn active" else "fc-nav-btn"
        tags$button(class = cls,
          onclick = sprintf("Shiny.setInputValue('%s','%s',{priority:'event'})",
                            ns("fc_nav_click"), t$id),
          HTML(t$svg),
          span(t$label)
        )
      })
    })

    # ── User Name in Sidebar ──────────────────────────────────────────────────
    output$fc_user_name_ui <- renderUI({
      span(class = "fc-user-name", user$name %||% "Faculty")
    })

    # ── Header Title ──────────────────────────────────────────────────────────
    output$fc_header_title_ui <- renderUI({
      t <- active_tab()
      title_txt <- switch(t,
        overview = "Faculty Feedback Overview",
        trends   = "Sentiment Trends & Analysis",
        comments = "Student Comments",
        profile  = "Faculty Profile & Statistics"
      )
      sub_txt <- switch(t,
        overview = paste0("Evaluation summary for ", user$name %||% "you", " — 4 Assigned Courses in ", user$department %||% "department"),
        trends   = "Chronological time-series and aspect breakdown of student ratings",
        comments = "Actionable qualitative feedback written by students",
        profile  = "Teaching profile, assigned courses, and evaluation metrics"
      )
      tagList(
        h1(class = "fc-header-title", title_txt),
        p(class = "fc-header-sub", sub_txt)
      )
    })

    # ── Null-coalescing helper ─────────────────────────────────────────────────
    `%||%` <- function(a, b) if (!is.null(a) && !is.na(a) && a != "") a else b

    # ── 4 Assigned Courses Data ───────────────────────────────────────────────
    teacher_assigned_courses <- reactive({
      get_teacher_assigned_subjects(user$id)
    })

    # Populate course filter dropdown
    observe({
      df <- teacher_assigned_courses()
      if (nrow(df) > 0) {
        choices <- c("All 4 Assigned Subjects" = "all")
        course_opts <- setNames(as.character(df$course_id), paste0(df$course_code, " - ", df$course_name))
        updateSelectInput(session, "fc_course_filter", choices = c(choices, course_opts))
      }
    })

    # ── Raw Feedback Data ─────────────────────────────────────────────────────
    all_faculty_df <- reactive({
      get_faculty_feedback_all(user$id)
    })

    # Populate semester filter
    observe({
      df <- all_faculty_df()
      sems <- unique(df$semester[!is.na(df$semester) & df$semester != ""])
      sem_order <- paste("Semester", 1:8)
      sems <- c(sem_order[sem_order %in% sems], setdiff(sems, sem_order))
      updateSelectInput(session, "fc_semester_filter",
        choices = c("All Semesters" = "all", setNames(sems, sems)))
    })

    # Filtered data (by course + semester + aspect)
    filtered_df <- reactive({
      df  <- all_faculty_df()
      sem <- input$fc_semester_filter
      asp <- input$fc_aspect_filter
      crs <- input$fc_course_filter

      if (!is.null(sem) && sem != "all") df <- df[!is.na(df$semester) & df$semester == sem, ]
      if (!is.null(asp) && asp != "all") df <- df[!is.na(df$aspect)   & df$aspect   == asp, ]
      if (!is.null(crs) && crs != "all" && "course_id" %in% names(df)) {
        df <- df[!is.na(df$course_id) & df$course_id == as.integer(crs), ]
      }
      df
    })

    # ── KPI values ────────────────────────────────────────────────────────────
    kpi_vals <- reactive({
      df  <- filtered_df()
      n   <- nrow(df)
      pos <- sum(df$rating == 1,  na.rm = TRUE)
      neu <- sum(df$rating == 0,  na.rm = TRUE)
      neg <- sum(df$rating == -1, na.rm = TRUE)
      list(
        n = n, pos = pos, neu = neu, neg = neg,
        pos_pct = if (n > 0) round(pos/n*100) else 0L,
        neu_pct = if (n > 0) round(neu/n*100) else 0L,
        neg_pct = if (n > 0) round(neg/n*100) else 0L
      )
    })

    # ── Per-Aspect Summary ────────────────────────────────────────────────────
    aspect_summary <- reactive({
      df <- all_faculty_df()
      sem <- input$fc_semester_filter
      crs <- input$fc_course_filter
      if (!is.null(sem) && sem != "all") df <- df[!is.na(df$semester) & df$semester == sem, ]
      if (!is.null(crs) && crs != "all" && "course_id" %in% names(df)) {
        df <- df[!is.na(df$course_id) & df$course_id == as.integer(crs), ]
      }
      do.call(rbind, lapply(ALL_ASPECTS, function(asp) {
        sub <- df[df$aspect == asp, ]
        n   <- nrow(sub)
        pos <- if (n > 0) sum(sub$rating == 1, na.rm = TRUE) else 0L
        neg <- if (n > 0) sum(sub$rating == -1, na.rm = TRUE) else 0L
        data.frame(
          aspect    = asp,
          label     = FACULTY_ASPECT_LABELS[asp],
          icon      = FACULTY_ASPECT_ICONS[asp],
          n         = n,
          pos       = pos,
          neg       = neg,
          pos_pct   = if (n > 0) round(pos/n*100) else 0L,
          neg_pct   = if (n > 0) round(neg/n*100) else 0L,
          stringsAsFactors = FALSE
        )
      }))
    })

    # ══════════════════════════════════════════════════════════════════════════
    #  TAB DISPATCHER
    # ══════════════════════════════════════════════════════════════════════════
    output$fc_tab_content_ui <- renderUI({
      switch(active_tab(),
        overview = render_overview_tab(),
        trends   = render_trends_tab(),
        comments = render_comments_tab(),
        profile  = render_profile_tab()
      )
    })

    # ── 1. OVERVIEW TAB ───────────────────────────────────────────────────────
    render_overview_tab <- function() {
      kv <- kpi_vals()
      courses_df <- teacher_assigned_courses()
      win <- get_active_feedback_window()

      # Assigned 4 Subjects Cards
      course_cards <- if (nrow(courses_df) > 0) {
        lapply(seq_len(nrow(courses_df)), function(i) {
          r <- courses_df[i, ]
          pos_lbl <- if (!is.na(r$pos_pct)) sprintf("%.1f%% Positive", r$pos_pct) else "Pending Feedback"
          div(class = "fc-course-card",
            div(class = "fc-course-code", sprintf("Course %d · %s", i, r$course_code)),
            div(class = "fc-course-title", r$course_name),
            div(class = "fc-course-meta", sprintf("%s · %d Credits", r$semester, r$credits)),
            div(style = "margin-top:8px; font-size:0.75rem; font-weight:600; color:#059669;", pos_lbl)
          )
        })
      } else { NULL }

      # Institutional Notice Banner
      notice_banner <- div(style = "background:#ffffff; border:1px solid #e2e8f0; border-left:4px solid #1e40af; border-radius:8px; padding:12px 18px; margin-bottom:18px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;",
        div(
          strong(style = "color:#0f172a; font-size:0.88rem; display:block;", sprintf("Official Notice: %s", win$term_name)),
          span(style = "color:#475569; font-size:0.8125rem;", win$description)
        ),
        span(style = "background:#eff6ff; color:#1e40af; border:1px solid #bfdbfe; font-size:0.75rem; font-weight:700; padding:3px 9px; border-radius:4px; text-transform:uppercase;",
          sprintf("Deadline: %s (%d Days Left)", format(as.Date(win$deadline_date), "%b %d"), win$days_left))
      )

      tagList(
        notice_banner,

        # 4 Assigned Courses Banner
        div(class = "fc-card", style = "padding:16px 20px;",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;",
            div(
              h4(style = "font-size:0.9375rem; font-weight:700; color:#0f172a; margin:0;", "My 4 Assigned Academic Courses"),
              p(style = "font-size:0.8125rem; color:#64748b; margin:2px 0 0 0;", "Instructional course allocation across academic semesters")
            ),
            span(style = "background:#eff6ff; color:#1e40af; font-weight:600; font-size:0.75rem; padding:3px 8px; border-radius:4px; border:1px solid #bfdbfe;",
              "4 Courses Assigned")
          ),
          div(class = "fc-courses-grid", course_cards)
        ),

        # KPI Grid
        div(class = "fc-kpi-grid",
          div(class = "fc-kpi-card tot",
            span(class = "fc-kpi-label", "Total Reviews"),
            div(class = "fc-kpi-value", formatC(kv$n, format = "d", big.mark = ",")),
            span(class = "fc-kpi-sub", "student submissions")
          ),
          div(class = "fc-kpi-card pos",
            span(class = "fc-kpi-label", "Positive"),
            div(class = "fc-kpi-value", style = "color:#059669;", sprintf("%d%%", kv$pos_pct)),
            div(class = "fc-progress",
              div(class = "fc-progress-bar",
                style = sprintf("width:%d%%;background:#059669;", kv$pos_pct))),
            span(class = "fc-kpi-sub", sprintf("%d responses", kv$pos))
          ),
          div(class = "fc-kpi-card neg",
            span(class = "fc-kpi-label", "Negative"),
            div(class = "fc-kpi-value", style = "color:#dc2626;", sprintf("%d%%", kv$neg_pct)),
            div(class = "fc-progress",
              div(class = "fc-progress-bar",
                style = sprintf("width:%d%%;background:#dc2626;", kv$neg_pct))),
            span(class = "fc-kpi-sub", sprintf("%d responses", kv$neg))
          ),
          div(class = "fc-kpi-card neu",
            span(class = "fc-kpi-label", "Neutral"),
            div(class = "fc-kpi-value", style = "color:#d97706;", sprintf("%d%%", kv$neu_pct)),
            div(class = "fc-progress",
              div(class = "fc-progress-bar",
                style = sprintf("width:%d%%;background:#d97706;", kv$neu_pct))),
            span(class = "fc-kpi-sub", sprintf("%d responses", kv$neu))
          )
        ),

        # Top row: Donut + Aspect bars
        div(style = "display:grid; grid-template-columns:1fr 1.6fr; gap:20px; margin-bottom:20px;",
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", "Sentiment Distribution"),
            p(class = "fc-card-sub", "Share of positive, neutral and negative student ratings"),
            plotlyOutput(ns("chart_donut"), height = "260px")
          ),
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", "Feedback by Dimension"),
            p(class = "fc-card-sub", "Positivity rate across all 6 feedback dimensions"),
            uiOutput(ns("aspect_bars_ui"))
          )
        ),

        # Bottom row: Timeline + Word Clouds
        div(class = "fc-card",
          p(class = "fc-card-title", "Sentiment Over Time"),
          p(class = "fc-card-sub", "Chronological average score across academic cycles and semesters"),
          plotlyOutput(ns("chart_timeline"), height = "260px")
        ),

        div(style = "display:grid; grid-template-columns:1fr 1fr; gap:20px;",
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", style = "color:#059669;", "Positive Key Themes"),
            p(class = "fc-card-sub", "Most frequent positive keywords from student reviews"),
            uiOutput(ns("wc_positive"))
          ),
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", style = "color:#dc2626;", "Improvement Themes"),
            p(class = "fc-card-sub", "Most frequent concern keywords from student reviews"),
            uiOutput(ns("wc_negative"))
          )
        )
      )
    }

    # ── 2. TRENDS TAB ─────────────────────────────────────────────────────────
    render_trends_tab <- function() {
      tagList(
        div(class = "fc-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;",
            div(
              p(class = "fc-card-title", style = "margin:0;", "Semester-wise Sentiment Trend"),
              p(class = "fc-card-sub", style = "margin:4px 0 0;",
                "Average sentiment across sequential semesters (1 through 8)")
            )
          ),
          plotlyOutput(ns("chart_semester_trend"), height = "300px")
        ),

        # Per-aspect grouped bar
        div(class = "fc-card",
          p(class = "fc-card-title", "Aspect Comparison — Positive vs Negative"),
          p(class = "fc-card-sub", "Side-by-side count of positive and negative reviews per category"),
          plotlyOutput(ns("chart_aspect_bar"), height = "300px")
        ),

        # Radar chart
        div(class = "fc-card",
          p(class = "fc-card-title", "Performance Radar"),
          p(class = "fc-card-sub", "Positivity distribution across all 6 teaching evaluation dimensions"),
          plotlyOutput(ns("chart_radar"), height = "340px")
        )
      )
    }

    # ── 3. COMMENTS TAB ───────────────────────────────────────────────────────
    render_comments_tab <- function() {
      tagList(
        div(style = "display:grid; grid-template-columns:1fr 1fr; gap:20px;",
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", style = "color:#059669;", "Constructive Positive Feedback"),
            p(class = "fc-card-sub", "Detailed positive student feedback"),
            uiOutput(ns("comments_positive"))
          ),
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", style = "color:#dc2626;", "Areas for Attention"),
            p(class = "fc-card-sub", "Specific feedback highlighting potential improvements"),
            uiOutput(ns("comments_negative"))
          )
        ),

        br(),

        div(class = "fc-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;",
            div(
              p(class = "fc-card-title", style = "margin:0;", "All Student Comments"),
              p(class = "fc-card-sub", style = "margin:4px 0 0;", "Searchable log of written student feedback")
            )
          ),
          DT::dataTableOutput(ns("comments_table"))
        )
      )
    }

    # ── 4. PROFILE TAB ────────────────────────────────────────────────────────
    render_profile_tab <- function() {
      tagList(
        # Profile header card
        div(class = "fc-card",
          div(style = "display:flex; align-items:center; gap:20px; flex-wrap:wrap;",
            div(class = "fc-profile-avatar",
              tags$svg(xmlns = "http://www.w3.org/2000/svg", viewBox = "0 0 24 24", width = "28", height = "28",
                       fill = "none", stroke = "#ffffff", strokeWidth = "2", strokeLinecap = "round", strokeLinejoin = "round",
                       tags$path(d = "M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"),
                       tags$circle(cx = "12", cy = "7", r = "4"))
            ),
            div(
              tags$h2(style = "margin:0; font-size:1.25rem; font-weight:700; color:#0f172a;",
                user$name %||% "Faculty Member"),
              p(style = "margin:4px 0 8px; color:#64748b; font-size:0.84rem;",
                paste0(user$email %||% "faculty@college.edu", "  •  ", user$department %||% "Department")),
              span(class = "fc-profile-badge", "Faculty Member"),
              tags$span(" "),
              span(class = "fc-profile-badge", style = "background:#eff6ff;color:#1e40af;border-color:#bfdbfe;",
                paste0(user$department %||% "Academic Department"))
            )
          )
        ),

        # Stats row
        div(style = "display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:20px;",
          uiOutput(ns("profile_stat_total")),
          uiOutput(ns("profile_stat_pos")),
          uiOutput(ns("profile_stat_neg")),
          uiOutput(ns("profile_stat_avg"))
        ),

        # Aspect breakdown for profile
        div(class = "fc-card",
          p(class = "fc-card-title", "Teaching Dimension Breakdown"),
          p(class = "fc-card-sub", "Positive feedback rate for each aspect students evaluated"),
          uiOutput(ns("profile_aspect_detail"))
        ),

        # Best semester card
        div(class = "fc-card",
          p(class = "fc-card-title", "Highest & Lowest Rated Semesters"),
          p(class = "fc-card-sub", "Performance overview by semester based on average sentiment score"),
          uiOutput(ns("profile_best_worst_sem"))
        )
      )
    }

    # ══════════════════════════════════════════════════════════════════════════
    #  CHART OUTPUTS
    # ══════════════════════════════════════════════════════════════════════════

    # Donut chart
    output$chart_donut <- renderPlotly({
      kv <- kpi_vals()
      if (kv$n == 0) return(plot_ly() %>%
        layout(paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
               annotations = list(text="No data", showarrow=FALSE,
                                  font=list(color="#94a3b8", size=14))))
      plot_ly(
        labels = c("Positive", "Neutral", "Negative"),
        values = c(kv$pos, kv$neu, kv$neg),
        type   = "pie",
        hole   = 0.6,
        marker = list(colors = c("#059669", "#d97706", "#dc2626"),
                      line = list(color = "#ffffff", width = 2)),
        textinfo = "percent",
        textfont = list(color = "#ffffff", size = 12)
      ) %>%
        layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          showlegend = TRUE,
          legend = list(orientation = "h", x = 0.1, y = -0.1, font = list(color="#475569")),
          margin = list(l=10, r=10, t=10, b=35),
          annotations = list(list(
            text = paste0("<b>", kv$pos_pct, "%</b><br><span style='font-size:10px;color:#64748b;'>Positive</span>"),
            x = 0.5, y = 0.5, showarrow = FALSE,
            font = list(size = 14, color = "#0f172a")
          ))
        )
    })

    # Aspect bars UI
    output$aspect_bars_ui <- renderUI({
      df <- aspect_summary()
      lapply(seq_len(nrow(df)), function(i) {
        row <- df[i, ]
        bar_color <- if (row$pos_pct >= 60) "#059669"
                     else if (row$pos_pct >= 40) "#d97706"
                     else "#dc2626"
        div(class = "fc-aspect-row",
          div(class = "fc-aspect-icon-wrap", HTML(row$icon)),
          span(class = "fc-aspect-label", row$label),
          div(class = "fc-aspect-bar-wrap",
            div(class = "fc-aspect-bar-fill",
              style = sprintf("width:%d%%;background:%s;", row$pos_pct, bar_color))
          ),
          span(class = "fc-aspect-pct", sprintf("%d%%", row$pos_pct)),
          span(class = "fc-aspect-count", sprintf("(%d)", row$n))
        )
      })
    })

    # Timeline chart (Strict chronological ordering)
    output$chart_timeline <- renderPlotly({
      df <- filtered_df()
      if (nrow(df) == 0) return(
        plot_ly() %>% layout(paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
          annotations=list(text="No data for selected filters", showarrow=FALSE,
                           font=list(color="#94a3b8", size=13))))

      if ("semester" %in% names(df) && any(!is.na(df$semester) & df$semester != "")) {
        sem_df <- aggregate(rating ~ semester, data = df, FUN = function(x)
          round(mean(ifelse(x == 1, 5, ifelse(x == 0, 3, 1))), 2))
        sem_df$sem_num <- as.integer(gsub("[^0-9]", "", sem_df$semester))
        sem_df <- sem_df[order(sem_df$sem_num), ]
        
        plot_ly(sem_df, x = ~semester, y = ~rating,
          type = "scatter", mode = "lines+markers",
          line   = list(color = "#1e40af", width = 2.5),
          marker = list(color = "#1e40af", size = 8,
                        line = list(color = "#ffffff", width = 2)),
          text = ~paste0(semester, "<br>Avg Score: ", rating, " / 5"),
          hoverinfo = "text"
        ) %>% layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(
            title = "Academic Semester",
            color = "#64748b",
            categoryorder = "array",
            categoryarray = sem_df$semester,
            gridcolor = "rgba(0,0,0,0.05)"
          ),
          yaxis = list(title = "Avg Score (1-5)", color = "#64748b",
                       range = c(1, 5.2), gridcolor = "rgba(0,0,0,0.05)"),
          margin = list(l=50, r=20, t=10, b=45)
        )
      } else {
        df$dt  <- as.POSIXct(df$created_at, format = "%Y-%m-%d %H:%M:%S")
        df$mon <- format(df$dt, "%Y-%m")
        monthly <- aggregate(rating ~ mon, data = df, FUN = mean)
        monthly <- monthly[order(monthly$mon), ]
        monthly$mon_label <- format(as.Date(paste0(monthly$mon, "-01")), "%b %Y")
        
        plot_ly(monthly, x = ~mon_label, y = ~round(rating, 2),
          type = "scatter", mode = "lines+markers",
          line = list(color = "#1e40af", width = 2.5),
          marker = list(color = "#1e40af", size = 8, line = list(color="#fff", width=2))
        ) %>% layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(
            title = "",
            color = "#64748b",
            tickangle = -30,
            categoryorder = "array",
            categoryarray = monthly$mon_label,
            gridcolor = "rgba(0,0,0,0.05)"
          ),
          yaxis = list(title="Avg Sentiment", color="#64748b",
                       range=c(-1.2,1.2), tickvals=c(-1,0,1),
                       ticktext=c("Neg","Neutral","Pos"),
                       gridcolor="rgba(0,0,0,0.05)"),
          margin = list(l=50, r=20, t=10, b=50)
        )
      }
    })

    # Word clouds
    output$wc_positive <- renderUI({
      df  <- filtered_df()
      pos <- df[!is.na(df$text) & df$rating == 1, "text"]
      render_wordcloud_html(pos, sentiment_filter = "positive")
    })
    output$wc_negative <- renderUI({
      df  <- filtered_df()
      neg <- df[!is.na(df$text) & df$rating == -1, "text"]
      render_wordcloud_html(neg, sentiment_filter = "negative")
    })

    # Semester trend (trends tab)
    output$chart_semester_trend <- renderPlotly({
      df <- filtered_df()
      if (nrow(df) == 0) return(plot_ly() %>%
        layout(annotations=list(text="No data",showarrow=FALSE,
               font=list(color="#94a3b8")),
               paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)"))

      sem_df <- aggregate(rating ~ semester, data = df, FUN = function(x)
        round(mean(ifelse(x == 1, 5, ifelse(x == 0, 3, 1))), 2))
      sem_df$sem_num <- as.integer(gsub("[^0-9]", "", sem_df$semester))
      sem_df <- sem_df[order(sem_df$sem_num), ]

      plot_ly(sem_df, x = ~semester, y = ~rating,
        type = "scatter", mode = "lines+markers+text",
        text = ~round(rating, 1), textposition = "top center",
        line   = list(color="#1e40af", width=2.5),
        marker = list(color="#1e40af", size=8, line=list(color="#fff",width=2))
      ) %>% layout(
        paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
        xaxis = list(
          title="Semester",
          color="#64748b",
          categoryorder = "array",
          categoryarray = sem_df$semester,
          gridcolor="rgba(0,0,0,0.05)"
        ),
        yaxis = list(title="Avg Score (1–5)", color="#64748b",
                     range=c(0.8,5.5), gridcolor="rgba(0,0,0,0.05)"),
        margin = list(l=50, r=20, t=20, b=45)
      )
    })

    # Aspect grouped bar
    output$chart_aspect_bar <- renderPlotly({
      df <- aspect_summary()
      plot_ly(df, x = ~label,
        y = ~pos, name = "Positive", type = "bar",
        marker = list(color = "#059669", line = list(color="#fff", width=1))
      ) %>%
        add_trace(y = ~neg, name = "Negative",
          marker = list(color = "#dc2626", line = list(color="#fff", width=1))) %>%
        layout(
          barmode = "group",
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(title = "", color = "#64748b", gridcolor="rgba(0,0,0,0.04)",
                       tickangle = -20),
          yaxis = list(title = "Responses", color = "#64748b", gridcolor="rgba(0,0,0,0.04)"),
          legend = list(orientation = "h", x = 0, y = 1.1, font=list(color="#334155")),
          margin = list(l=50, r=20, t=40, b=70)
        )
    })

    # Radar chart
    output$chart_radar <- renderPlotly({
      df <- aspect_summary()
      categories <- c(df$label, df$label[1])  # close the loop
      values     <- c(df$pos_pct, df$pos_pct[1])

      plot_ly(
        type = "scatterpolar",
        r    = values,
        theta = categories,
        fill  = "toself",
        fillcolor = "rgba(30, 64, 175, 0.12)",
        line  = list(color = "#1e40af", width = 2),
        marker = list(color = "#1e40af", size = 6)
      ) %>% layout(
        polar = list(
          radialaxis = list(visible=TRUE, range=c(0,100), color="#64748b",
                            gridcolor="rgba(0,0,0,0.08)"),
          angularaxis = list(color="#334155", gridcolor="rgba(0,0,0,0.06)")
        ),
        paper_bgcolor = "rgba(0,0,0,0)",
        showlegend = FALSE,
        margin = list(l=60, r=60, t=20, b=20)
      )
    })

    # Comments — positive
    output$comments_positive <- renderUI({
      df <- filtered_df()
      comments <- get_actionable_comments(df[df$rating >= 0,], top_n = 6)
      if (length(comments) == 0)
        return(p(style="color:#94a3b8;text-align:center;padding:20px;", "No positive comments found."))
      lapply(seq_along(comments), function(i) {
        div(class = "fc-comment-card",
          p(class = "fc-comment-text", paste0("\u201C", comments[i], "\u201D")),
          p(class = "fc-comment-meta", paste("Comment", i))
        )
      })
    })

    # Comments — negative
    output$comments_negative <- renderUI({
      df <- filtered_df()
      neg_df <- df[df$rating == -1 & !is.na(df$text) & nchar(df$text) > 15, ]
      neg_df <- neg_df[order(-nchar(neg_df$text)), ]
      comments <- head(neg_df$text, 6)
      if (length(comments) == 0)
        return(p(style="color:#94a3b8;text-align:center;padding:20px;", "No concern comments found."))
      lapply(seq_along(comments), function(i) {
        div(class = "fc-comment-card negative",
          p(class = "fc-comment-text", paste0("\u201C", comments[i], "\u201D")),
          p(class = "fc-comment-meta", paste("Concern", i))
        )
      })
    })

    # Comments table
    output$comments_table <- DT::renderDataTable({
      df <- filtered_df()
      df <- df[!is.na(df$text) & df$text != "", ]
      if (nrow(df) == 0) return(data.frame(Message = "No written comments yet."))
      df$Sentiment <- ifelse(df$rating == 1, "Positive",
                      ifelse(df$rating == 0, "Neutral", "Negative"))
      df$Aspect    <- FACULTY_ASPECT_LABELS[df$aspect]
      df$Aspect    <- ifelse(is.na(df$Aspect), df$aspect, df$Aspect)
      df$Date      <- substr(df$created_at, 1, 16)
      out <- df[, c("Aspect", "semester", "Sentiment", "text", "Date")]
      names(out) <- c("Aspect", "Semester", "Sentiment", "Comment", "Date")
      out
    }, options = list(pageLength = 10, dom = "frtip", scrollX = TRUE), rownames = FALSE)

    # ── PROFILE STATS ─────────────────────────────────────────────────────────
    make_stat_box <- function(val, label) {
      div(class = "fc-stat-box",
        div(class = "fc-stat-val", val),
        div(class = "fc-stat-lbl", label)
      )
    }

    output$profile_stat_total <- renderUI({
      make_stat_box(formatC(kpi_vals()$n, format="d", big.mark=","), "Total Responses")
    })
    output$profile_stat_pos <- renderUI({
      kv <- kpi_vals()
      make_stat_box(sprintf("%d%%", kv$pos_pct), "Positive Rate")
    })
    output$profile_stat_neg <- renderUI({
      kv <- kpi_vals()
      make_stat_box(sprintf("%d%%", kv$neg_pct), "Negative Rate")
    })
    output$profile_stat_avg <- renderUI({
      df  <- all_faculty_df()
      avg <- if (nrow(df) > 0) round(mean(ifelse(df$rating==1,5,ifelse(df$rating==0,3,1))),1) else 0
      make_stat_box(sprintf("%.1f/5", avg), "Avg Rating")
    })

    # Profile aspect detail
    output$profile_aspect_detail <- renderUI({
      df <- aspect_summary()
      lapply(seq_len(nrow(df)), function(i) {
        row <- df[i, ]
        bar_color <- if (row$pos_pct >= 60) "#059669"
                     else if (row$pos_pct >= 40) "#d97706"
                     else "#dc2626"
        sentiment_label <- if (row$pos_pct >= 60) "Good" else if (row$pos_pct >= 40) "Fair" else "Needs Attention"
        div(class = "fc-aspect-row",
          div(class = "fc-aspect-icon-wrap", HTML(row$icon)),
          span(class = "fc-aspect-label", row$label),
          div(class = "fc-aspect-bar-wrap",
            div(class = "fc-aspect-bar-fill",
              style = sprintf("width:%d%%;background:%s;", row$pos_pct, bar_color))),
          span(class = "fc-aspect-pct", sprintf("%d%%", row$pos_pct)),
          span(class = "fc-aspect-count", sprintf("(%d)", row$n)),
          span(style = sprintf("font-size:0.75rem;font-weight:600;color:%s;min-width:80px;text-align:right;",
                               bar_color), sentiment_label)
        )
      })
    })

    # Best/Worst semester
    output$profile_best_worst_sem <- renderUI({
      df <- all_faculty_df()
      if (nrow(df) == 0 || !("semester" %in% names(df)))
        return(p(style="color:#94a3b8;padding:10px;", "No semester data available yet."))

      sem_df <- aggregate(rating ~ semester, data = df, FUN = function(x)
        round(mean(ifelse(x == 1, 5, ifelse(x == 0, 3, 1))), 2))
      names(sem_df) <- c("semester", "avg")
      sem_df$n <- sapply(sem_df$semester, function(s) nrow(df[df$semester == s, ]))
      sem_df <- sem_df[order(-sem_df$avg), ]

      best <- sem_df[1, ]
      worst <- sem_df[nrow(sem_df), ]

      div(style = "display:grid; grid-template-columns:1fr 1fr; gap:16px;",
        div(style = "background:#f0fdf4; border:1px solid #bbf7d0; border-left:3px solid #059669; border-radius:6px; padding:14px 18px;",
          div(style = "font-size:0.72rem; font-weight:700; color:#059669; text-transform:uppercase; letter-spacing:0.06em; margin-bottom:4px;",
            "Highest Rated Semester"),
          div(style = "font-size:1.25rem; font-weight:700; color:#0f172a;", best$semester),
          div(style = "font-size:0.8125rem; color:#64748b; margin-top:4px;",
            sprintf("Avg rating: %.2f / 5 • %d responses", best$avg, best$n))
        ),
        div(style = "background:#fef2f2; border:1px solid #fecaca; border-left:3px solid #dc2626; border-radius:6px; padding:14px 18px;",
          div(style = "font-size:0.72rem; font-weight:700; color:#dc2626; text-transform:uppercase; letter-spacing:0.06em; margin-bottom:4px;",
            "Needs Improvement"),
          div(style = "font-size:1.25rem; font-weight:700; color:#0f172a;", worst$semester),
          div(style = "font-size:0.8125rem; color:#64748b; margin-top:4px;",
            sprintf("Avg rating: %.2f / 5 • %d responses", worst$avg, worst$n))
        )
      )
    })

    # ── LOGOUT ────────────────────────────────────────────────────────────────
    observeEvent(input$btn_logout, { logout_trigger(logout_trigger() + 1) })
  })
}
