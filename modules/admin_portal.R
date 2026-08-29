# modules/admin_portal.R — White & Olive Green Dashboard
# Features: White & Olive Green Sidebar + Selective Dropdown Filters + Black Welcome Text + Teacher Name Highlighting + Full Width Improvement Rows

library(shiny)
library(plotly)
library(DT)
library(jsonlite)

# ── Helpers ───────────────────────────────────────────────────────────────────
get_course_name <- function(dept, aspect) {
  if (is.na(aspect) || is.null(aspect) || aspect == "") return("General")
  switch(aspect,
    teaching           = "Teaching Quality",
    coursecontent      = "Course Content",
    examination        = "Examination",
    labwork            = "Lab Work",
    library_facilities = "Library Facilities",
    extracurricular    = "Extracurricular",
    aspect
  )
}

ASPECT_LABELS <- c(
  teaching           = "Teaching Quality",
  coursecontent      = "Course Content",
  examination        = "Examination",
  labwork            = "Lab Facilities",
  library_facilities = "Library & Resources",
  extracurricular    = "Extracurricular"
)

ASPECT_ICONS <- c(
  teaching           = "🎓",
  coursecontent      = "📚",
  examination        = "📝",
  labwork            = "🔬",
  library_facilities = "📖",
  extracurricular    = "🏆"
)

SEMESTER_ORDER <- c("Semester 1", "Semester 2", "Semester 3", "Semester 4",
                  "Semester 5", "Semester 6", "Semester 7", "Semester 8")

# Helper to render highlighted teacher name badge
format_teacher_badge <- function(teacher_name) {
  if (is.null(teacher_name) || is.na(teacher_name) || teacher_name == "" || teacher_name == "N/A") {
    return(span(class = "gw-teacher-badge-none", "Unassigned"))
  }
  span(class = "gw-teacher-badge", sprintf("👨‍🏫 %s", teacher_name))
}

# ══════════════════════════════════════════════════════════════════════════════
#  UI
# ══════════════════════════════════════════════════════════════════════════════
adminPortalUI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head(
      tags$style(HTML("
        /* ── WHITE & OLIVE GREEN DASHBOARD SYSTEM ─────────────────────────── */
        html { font-size: 100% !important; }
        .gw-app {
          display: flex;
          min-height: 100vh;
          font-family: 'Inter', sans-serif;
          background-color: #f7faf6;
          color: #1a2e23;
          font-size: 0.95rem;
        }

        /* ── WHITE & OLIVE SIDEBAR ────────────────────────────────────────── */
        .gw-sidebar {
          width: 260px;
          background: #ffffff !important;
          color: #1e3314 !important;
          display: flex;
          flex-direction: column;
          flex-shrink: 0;
          position: fixed;
          top: 0; bottom: 0; left: 0;
          z-index: 100;
          border-right: 1px solid #dbe8d2 !important;
          box-shadow: 2px 0 12px rgba(61,90,43,0.06);
        }
        .gw-sidebar-brand {
          padding: 22px 20px;
          display: flex;
          align-items: center;
          gap: 12px;
          border-bottom: 1px solid #e0ebd5;
          background: #f4f8f2;
        }
        .gw-brand-icon {
          width: 40px; height: 40px;
          background: linear-gradient(135deg, #4a6b35 0%, #2e4720 100%) !important;
          border-radius: 10px;
          display: flex; align-items: center; justify-content: center;
          color: #ffffff;
          box-shadow: 0 4px 10px rgba(74,107,53,0.25);
        }
        .gw-brand-name {
          font-weight: 800;
          font-size: 1.1rem;
          color: #1e3314 !important;
          letter-spacing: -0.02em;
        }
        .gw-brand-sub {
          font-size: 0.72rem;
          color: #557544 !important;
        }

        /* Nav links */
        .gw-nav {
          padding: 16px 12px;
          display: flex;
          flex-direction: column;
          gap: 4px;
          flex: 1;
        }
        .gw-nav-section-title {
          font-size: 0.68rem;
          font-weight: 700;
          color: #6b8e58 !important;
          text-transform: uppercase;
          letter-spacing: 0.1em;
          padding: 12px 14px 4px 14px;
        }
        .gw-nav-btn {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 10px 14px;
          border-radius: 8px;
          color: #2b451c !important;
          font-size: 0.88rem;
          font-weight: 600;
          background: transparent;
          border: none;
          cursor: pointer;
          width: 100%;
          text-align: left;
          transition: all 0.15s ease;
        }
        .gw-nav-btn:hover {
          background: #f0f5eb !important;
          color: #1e3314 !important;
        }
        .gw-nav-btn.active {
          background: #183d2e !important;
          color: #ffffff !important;
          font-weight: 800 !important;
          border-left: 4px solid #10b981 !important;
          box-shadow: 0 4px 12px rgba(16,185,129,0.25) !important;
        }
        .gw-nav-btn.active span, .gw-nav-btn.active div {
          color: #ffffff !important;
          opacity: 1 !important;
          font-weight: 800 !important;
        }

        /* Sidebar user footer - BLACK WELCOME TEXT */
        .gw-sidebar-user {
          padding: 16px 20px;
          border-top: 1px solid #e0ebd5;
          display: flex;
          align-items: center;
          justify-content: space-between;
          background: #f4f8f2;
        }
        .gw-user-info { display: flex; flex-direction: column; gap: 1px; }
        .gw-user-name {
          font-weight: 800 !important;
          font-size: 0.88rem;
          color: #000000 !important; /* BLACK COLOR */
        }
        .gw-user-role {
          font-size: 0.72rem;
          color: #4a6b35 !important;
          font-weight: 600;
        }

        /* ── HIGHLIGHTED TEACHER BADGE ────────────────────────────────────── */
        .gw-teacher-badge {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          background: #f0f5eb;
          color: #2b451c;
          font-weight: 700;
          padding: 3px 9px;
          border-radius: 6px;
          border: 1px solid #cce0bf;
          font-size: 0.8rem;
        }
        .gw-teacher-badge-none {
          display: inline-flex;
          align-items: center;
          background: #f1f5f9;
          color: #94a3b8;
          font-size: 0.75rem;
          padding: 2px 7px;
          border-radius: 4px;
        }

        /* ── MAIN CONTENT CANVAS ─────────────────────────────────────────── */
        .gw-main {
          margin-left: 260px;
          flex: 1;
          display: flex;
          flex-direction: column;
          min-width: 0;
        }

        /* Top header bar */
        .gw-header {
          background: #ffffff;
          border-bottom: 1px solid #e2ebd8;
          padding: 16px 32px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          position: sticky;
          top: 0;
          z-index: 90;
          box-shadow: 0 1px 3px rgba(0,0,0,0.02);
        }
        .gw-header-title {
          font-size: 1.4rem;
          font-weight: 800;
          color: #1e3314;
          margin: 0;
          letter-spacing: -0.02em;
        }
        .gw-header-sub {
          font-size: 0.82rem;
          color: #64748b;
          margin: 2px 0 0 0;
        }

        /* SELECTIVE DROPDOWN CONTROLS IN HEADER */
        .gw-filter-bar {
          display: flex;
          align-items: center;
          gap: 12px;
        }
        .gw-filter-item {
          display: flex;
          align-items: center;
          gap: 8px;
          background: #f4f8f2;
          border: 1px solid #d4e3ca;
          border-radius: 8px;
          padding: 4px 10px;
        }
        .gw-filter-item label, .gw-filter-item .control-label {
          margin: 0 !important;
          font-size: 0.75rem !important;
          font-weight: 700 !important;
          color: #3b572a !important;
          text-transform: uppercase !important;
          letter-spacing: 0.04em !important;
        }
        .gw-filter-item select {
          border: none !important;
          background: transparent !important;
          font-size: 0.85rem !important;
          color: #1e3314 !important;
          font-weight: 700 !important;
          outline: none !important;
          cursor: pointer !important;
          padding: 2px 4px !important;
        }

        /* Scope Bar */
        .gw-scope-bar {
          padding: 12px 32px 0 32px;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .gw-scope-badge {
          display: inline-flex; align-items: center; gap: 4px;
          background: #eef6ea; color: #2b451c;
          font-size: 0.75rem; font-weight: 700;
          padding: 3px 10px; border-radius: 9999px;
          border: 1px solid #d4e3ca;
        }

        /* Canvas body */
        .gw-body {
          padding: 24px 32px 48px 32px;
          flex: 1;
        }

        /* ── CARDS & METRICS ─────────────────────────────────────────────── */
        .gw-card {
          background: #ffffff;
          border: 1px solid #e2ebd8;
          border-radius: 14px;
          padding: 22px 24px;
          margin-bottom: 22px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.03);
          transition: all 0.2s ease;
        }
        .gw-card:hover { box-shadow: 0 6px 18px rgba(61,90,43,0.06); }
        .gw-card-title {
          font-size: 1rem;
          font-weight: 800;
          color: #1e3314;
          margin: 0 0 4px 0;
          display: flex; align-items: center; gap: 8px;
        }
        .gw-card-sub {
          font-size: 0.8rem;
          color: #64748b;
          margin: 0 0 16px 0;
        }

        /* KPI grid */
        .gw-kpi-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 18px;
          margin-bottom: 24px;
        }
        .gw-kpi-card {
          background: #ffffff;
          border: 1px solid #e2ebd8;
          border-radius: 14px;
          padding: 20px;
          display: flex;
          flex-direction: column;
          gap: 8px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.02);
          border-top: 4px solid #3d5a2b;
          transition: transform 0.2s;
        }
        .gw-kpi-card:hover { transform: translateY(-2px); }
        .gw-kpi-card.tot { border-top-color: #1e3314; }
        .gw-kpi-card.pos { border-top-color: #059669; }
        .gw-kpi-card.neg { border-top-color: #ef4444; }
        .gw-kpi-card.neu { border-top-color: #f59e0b; }

        .gw-kpi-label {
          font-size: 0.75rem;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.06em;
          color: #64748b;
        }
        .gw-kpi-value {
          font-size: 2.2rem;
          font-weight: 800;
          color: #1e3314;
          line-height: 1;
        }
        .gw-kpi-sub { font-size: 0.78rem; color: #64748b; }

        /* Progress bars */
        .gw-progress {
          width: 100%; height: 6px;
          background: #f1f5f9;
          border-radius: 9999px;
          overflow: hidden;
          margin-top: 2px;
        }
        .gw-progress-bar { height: 100%; border-radius: 9999px; }

        /* Highlight cards */
        .gw-highlight-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 18px;
          margin-bottom: 22px;
        }
        .gw-highlight-card {
          border-radius: 12px;
          padding: 18px 20px;
          border: 1px solid #e2ebd8;
          background: #ffffff;
        }
        .gw-highlight-card.top { border-left: 4px solid #059669; background: #f4fbf7; }
        .gw-highlight-card.bottom { border-left: 4px solid #ef4444; background: #fff5f5; }

        /* Dept ranking rows */
        .gw-dept-row {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 10px 12px;
          border-radius: 8px;
          margin-bottom: 6px;
          border: 1px solid #f1f5f9;
        }
        .gw-dept-row:hover { background: #f8fafc; }
        .gw-dept-rank {
          width: 26px; height: 26px; border-radius: 6px;
          display: flex; align-items: center; justify-content: center;
          font-size: 0.75rem; font-weight: 800; flex-shrink: 0;
        }
        .gw-dept-rank.gold { background: #d1fae5; color: #065f46; }
        .gw-dept-rank.bottom { background: #fee2e2; color: #991b1b; }
        .gw-dept-rank.other { background: #f1f5f9; color: #64748b; }

        /* FULL WIDTH HORIZONTAL DEPARTMENT AREAS TO IMPROVE */
        .gw-improve-list {
          display: flex;
          flex-direction: column;
          gap: 12px;
          width: 100%;
        }
        .gw-improve-card {
          border: 1px solid #e2ebd8;
          border-radius: 12px;
          padding: 14px 20px;
          background: #ffffff;
          width: 100%;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 20px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.02);
          transition: all 0.15s ease;
        }
        .gw-improve-card:hover {
          border-color: #cbd5e1;
          background: #fafbfc;
        }
        .gw-improve-dept-info {
          min-width: 180px;
          flex-shrink: 0;
        }
        .gw-improve-dept-name {
          font-weight: 800;
          font-size: 0.95rem;
          color: #1e3314;
          margin: 0;
        }
        .gw-improve-dept-meta {
          font-size: 0.76rem;
          color: #64748b;
          margin-top: 2px;
        }
        .gw-improve-tags-wrap {
          display: flex;
          flex-wrap: wrap;
          gap: 6px;
          align-items: center;
          justify-content: flex-end;
          flex: 1;
        }
        .gw-tag {
          display: inline-flex; align-items: center; gap: 5px;
          padding: 4px 10px; border-radius: 9999px; font-size: 0.76rem; font-weight: 600;
          white-space: nowrap;
        }
        .gw-tag.critical { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; }
        .gw-tag.moderate { background: #fef3c7; color: #92400e; border: 1px solid #fde68a; }
        .gw-tag.good { background: #d1fae5; color: #065f46; border: 1px solid #a7f3d0; }

        /* AI section */
        .gw-ai-box {
          background: #f8fafc;
          border: 1px solid #e2e8f0;
          border-radius: 10px;
          padding: 14px 16px;
          margin-bottom: 12px;
        }
        .gw-ai-title {
          font-size: 0.72rem; font-weight: 700; text-transform: uppercase;
          letter-spacing: 0.08em; color: #64748b; margin-bottom: 6px;
        }
        .gw-action-item {
          display: flex; align-items: flex-start; gap: 8px;
          padding: 6px 0; font-size: 0.84rem; color: #334155;
          border-bottom: 1px solid #f1f5f9;
        }
        .gw-action-item:last-child { border-bottom: none; }
        .gw-action-num {
          width: 18px; height: 18px; background: #3d5a2b; color: #fff;
          border-radius: 50%; font-size: 0.65rem; font-weight: 700;
          display: flex; align-items: center; justify-content: center; flex-shrink: 0;
        }

        /* Settings form styling */
        .gw-settings-group {
          background: #ffffff;
          border: 1px solid #e2ebd8;
          border-radius: 12px;
          padding: 20px 22px;
          margin-bottom: 18px;
        }
        .gw-settings-title {
          font-weight: 800; font-size: 0.92rem; color: #1e3314; margin-bottom: 4px;
        }
        .gw-settings-desc {
          font-size: 0.78rem; color: #64748b; margin-bottom: 14px;
        }

        /* Responsive */
        @media (max-width: 900px) {
          .gw-sidebar { width: 70px; }
          .gw-brand-name, .gw-brand-sub, .gw-nav-btn span, .gw-nav-section-title, .gw-user-info { display: none; }
          .gw-main { margin-left: 70px; }
          .gw-kpi-grid { grid-template-columns: repeat(2, 1fr); }
          .gw-highlight-grid { grid-template-columns: 1fr; }
          .gw-body { padding: 18px; }
        }
      "))
    ),

    div(class = "gw-app",

      # ── LEFT SIDEBAR (WHITE & OLIVE GREEN) ──────────────────────────────────
      div(class = "gw-sidebar",

        # Brand header
        div(class = "gw-sidebar-brand",
          div(class = "gw-brand-icon",
            tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24",
              style="width:20px;height:20px;fill:none;stroke:#fff;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round;",
              tags$path(d="M22 10v6M2 10l10-5 10 5-10 5z"),
              tags$path(d="M6 12.5V16a6 3 0 0 0 12 0v-3.5")
            )
          ),
          div(
            div(class = "gw-brand-name", "Campus Listen"),
            div(class = "gw-brand-sub", "College Feedback Portal")
          )
        ),

        # Navigation links
        div(class = "gw-nav",
          div(class = "gw-nav-section-title", "MAIN MENU"),

          uiOutput(ns("sidebar_nav_buttons"))
        ),

        # Sidebar footer user info - BLACK WELCOME TEXT
        div(class = "gw-sidebar-user",
          div(class = "gw-user-info",
            span(class = "gw-user-name", "Welcome, Admin Principal"),
            span(class = "gw-user-role", "System Administrator")
          ),
          actionButton(ns("btn_logout"), label = NULL,
            icon = icon("sign-out-alt"),
            style = "background:transparent;border:none;color:#3b572a;font-size:1.1rem;cursor:pointer;",
            title = "Logout")
        )
      ),

      # ── MAIN CANVAS ─────────────────────────────────────────────────────────
      div(class = "gw-main",

        # Header bar
        div(class = "gw-header",
          div(
            uiOutput(ns("header_title_ui"))
          ),
          div(class = "gw-filter-bar",
            # Selective Dropdown: Semester
            div(class = "gw-filter-item",
              tags$span("📅"),
              selectInput(ns("admin_semester_filter"), label = "Semester", choices = c("All Semesters" = "all"), width = "140px")
            ),
            # Selective Dropdown: Department
            div(class = "gw-filter-item",
              tags$span("🏫"),
              selectInput(ns("admin_dept_filter"), label = "Dept", choices = c("All Departments" = "all"), width = "170px")
            ),
            # PDF export
            downloadButton(ns("export_pdf"),
              label = HTML("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' style='width:13px;height:13px;fill:none;stroke:currentColor;stroke-width:2;vertical-align:middle;margin-right:4px;'><polyline points='6 9 6 2 18 2 18 9'/><path d='M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2'/><rect x='6' y='14' width='12' height='8'/></svg>Export PDF"),
              style = "background:#3d5a2b;color:#fff;border:none;border-radius:8px;font-weight:600;font-size:0.8rem;padding:7px 14px;height:36px;display:inline-flex;align-items:center;"
            )
          )
        ),

        # Scope bar
        div(class = "gw-scope-bar",
          span(style = "font-size:0.78rem; color:#64748b;", "Active Scope:"),
          uiOutput(ns("scope_badges_ui"))
        ),

        # Main body content switching based on active sidebar tab
        div(class = "gw-body",
          uiOutput(ns("tab_content_ui"))
        )
      )
    )
  )
}

# ══════════════════════════════════════════════════════════════════════════════
#  SERVER
# ══════════════════════════════════════════════════════════════════════════════
adminPortalServer <- function(id, user, logout_trigger) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    source("helpers/db.R",     local = TRUE)
    source("helpers/nlp.R",    local = TRUE)
    source("helpers/export.R", local = TRUE)

    # State
    active_tab <- reactiveVal("overview")
    observeEvent(input$nav_click, { active_tab(input$nav_click) })

    # ── SIDEBAR NAV BUTTONS ───────────────────────────────────────────────────
    output$sidebar_nav_buttons <- renderUI({
      cur <- active_tab()
      tabs <- list(
        list(id = "overview",  icon = "📊", label = "Overview"),
        list(id = "analytics", icon = "📈", label = "Analytics & Trends"),
        list(id = "explorer",  icon = "🔍", label = "Feedback Explorer"),
        list(id = "settings",  icon = "⚙️", label = "Settings")
      )
      lapply(tabs, function(t) {
        cls <- if (cur == t$id) "gw-nav-btn active" else "gw-nav-btn"
        tags$button(class = cls,
          onclick = sprintf("Shiny.setInputValue('%s','%s',{priority:'event'})", session$ns("nav_click"), t$id),
          span(t$icon),
          span(t$label)
        )
      })
    })

    # ── HEADER TITLE UI ───────────────────────────────────────────────────────
    output$header_title_ui <- renderUI({
      t <- active_tab()
      title_txt <- switch(t,
        overview  = "Dashboard Overview",
        analytics = "Analytics & Sentiment Trends",
        explorer  = "Feedback Explorer",
        settings  = "Portal Settings & Configuration"
      )
      sub_txt <- switch(t,
        overview  = "High-level summary of campus feedback performance",
        analytics = "Deep-dive into sentiment time-series and department metrics",
        explorer  = "Search and inspect individual student feedback entries",
        settings  = "System thresholds, notification settings and defaults"
      )
      tagList(
        h1(class = "gw-header-title", title_txt),
        p(class = "gw-header-sub", sub_txt)
      )
    })

    # ── RAW & FILTERED DATA ───────────────────────────────────────────────────
    raw_df <- reactive({ get_all_feedback() })

    avail_semesters <- reactive({
      df <- raw_df()
      sems <- unique(df$semester[!is.na(df$semester) & df$semester != ""])
      c(SEMESTER_ORDER[SEMESTER_ORDER %in% sems], setdiff(sems, SEMESTER_ORDER))
    })

    avail_depts <- reactive({
      df <- raw_df()
      sort(unique(df$teacher_dept[!is.na(df$teacher_dept) & df$teacher_dept != ""]))
    })

    # Populate SELECTIVE DROPDOWN choices
    observe({
      df <- raw_df()
      sems <- avail_semesters()
      updateSelectInput(session, "admin_semester_filter", choices = c("All Semesters" = "all", setNames(sems, sems)))

      depts <- avail_depts()
      updateSelectInput(session, "admin_dept_filter", choices = c("All Departments" = "all", setNames(depts, depts)))
    })

    filtered_df <- reactive({
      df   <- raw_df()
      sem  <- input$admin_semester_filter
      dept <- input$admin_dept_filter

      if (!is.null(sem)  && sem  != "all") df <- df[!is.na(df$semester)    & df$semester    == sem,  ]
      if (!is.null(dept) && dept != "all") df <- df[!is.na(df$teacher_dept) & df$teacher_dept == dept, ]
      df
    })

    # Scope Badges
    output$scope_badges_ui <- renderUI({
      sem_lbl  <- if (is.null(input$admin_semester_filter) || input$admin_semester_filter == "all") "All Semesters" else input$admin_semester_filter
      dept_lbl <- if (is.null(input$admin_dept_filter) || input$admin_dept_filter == "all") "All Departments" else input$admin_dept_filter
      n        <- nrow(filtered_df())
      tagList(
        span(class = "gw-scope-badge", sem_lbl),
        span(class = "gw-scope-badge", dept_lbl),
        span(class = "gw-scope-badge", style = "background:#e0e7ff;color:#3730a3;border-color:#c7d2fe;",
          sprintf("%s responses", formatC(n, format = "d", big.mark = ",")))
      )
    })

    # KPI VALUES
    kpi_vals <- reactive({
      df  <- filtered_df()
      n   <- nrow(df)
      pos <- sum(df$rating == 1,  na.rm = TRUE)
      neu <- sum(df$rating == 0,  na.rm = TRUE)
      neg <- sum(df$rating == -1, na.rm = TRUE)
      list(
        n = n, pos = pos, neu = neu, neg = neg,
        pos_pct = if (n > 0) round(pos / n * 100) else 0L,
        neu_pct = if (n > 0) round(neu / n * 100) else 0L,
        neg_pct = if (n > 0) round(neg / n * 100) else 0L
      )
    })

    # DEPT SUMMARY
    dept_summary <- reactive({
      df <- filtered_df()
      if (nrow(df) == 0) return(NULL)
      depts <- unique(df$teacher_dept[!is.na(df$teacher_dept)])
      if (length(depts) == 0) return(NULL)

      res <- do.call(rbind, lapply(depts, function(d) {
        sub <- df[df$teacher_dept == d, ]
        n   <- nrow(sub)
        if (n == 0) return(NULL)
        pos <- sum(sub$rating == 1, na.rm = TRUE)
        neu <- sum(sub$rating == 0, na.rm = TRUE)
        neg <- sum(sub$rating == -1, na.rm = TRUE)
        mapped <- ifelse(sub$rating == 1, 5, ifelse(sub$rating == 0, 3, 1))
        data.frame(
          department = d, total = n, pos = pos, neu = neu, neg = neg,
          pos_pct = round(pos / n * 100),
          neg_pct = round(neg / n * 100),
          avg_rating = round(mean(mapped), 2),
          stringsAsFactors = FALSE
        )
      }))
      res[order(-res$pos_pct, -res$total), ]
    })

    # ── TAB SWITCHER DISPATCH ─────────────────────────────────────────────────
    output$tab_content_ui <- renderUI({
      switch(active_tab(),
        overview  = render_overview_tab(),
        analytics = render_analytics_tab(),
        explorer  = render_explorer_tab(),
        settings  = render_settings_tab()
      )
    })

    # ── 1. OVERVIEW TAB VIEW ──────────────────────────────────────────────────
    render_overview_tab <- function() {
      kv <- kpi_vals()
      tagList(
        # KPI Grid
        div(class = "gw-kpi-grid",
          div(class = "gw-kpi-card tot",
            span(class = "gw-kpi-label", "Total Responses"),
            div(class = "gw-kpi-value", formatC(kv$n, format = "d", big.mark = ",")),
            span(class = "gw-kpi-sub", "collected entries")
          ),
          div(class = "gw-kpi-card pos",
            span(class = "gw-kpi-label", "Positive"),
            div(class = "gw-kpi-value", style = "color:#059669;", sprintf("%d%%", kv$pos_pct)),
            div(class = "gw-progress", div(class = "gw-progress-bar", style = sprintf("width:%d%%;background:#059669;", kv$pos_pct))),
            span(class = "gw-kpi-sub", sprintf("%d responses", kv$pos))
          ),
          div(class = "gw-kpi-card neg",
            span(class = "gw-kpi-label", "Negative"),
            div(class = "gw-kpi-value", style = "color:#ef4444;", sprintf("%d%%", kv$neg_pct)),
            div(class = "gw-progress", div(class = "gw-progress-bar", style = sprintf("width:%d%%;background:#ef4444;", kv$neg_pct))),
            span(class = "gw-kpi-sub", sprintf("%d responses", kv$neg))
          ),
          div(class = "gw-kpi-card neu",
            span(class = "gw-kpi-label", "Neutral"),
            div(class = "gw-kpi-value", style = "color:#d97706;", sprintf("%d%%", kv$neu_pct)),
            div(class = "gw-progress", div(class = "gw-progress-bar", style = sprintf("width:%d%%;background:#f59e0b;", kv$neu_pct))),
            span(class = "gw-kpi-sub", sprintf("%d responses", kv$neu))
          )
        ),

        # Timely Feedback Responses & Date Timeline Card
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;",
            p(class = "gw-card-title", style = "margin:0;", "📅 Timely Feedback Responses & Date Timeline"),
            span(style = "font-size:0.75rem; color:#3d5a2b; font-weight:700; background:#eef6ea; padding:3px 10px; border-radius:9999px; border:1px solid #d4e3ca;", "Multi-Semester Chronological View")
          ),
          p(class = "gw-card-sub", "Real-time timeline breakdown of submission volume and sentiment distribution across dates and academic semesters"),
          plotlyOutput(ns("chart_overview_timeline"), height = "280px")
        ),

        # Highlight Top vs Bottom
        div(class = "gw-highlight-grid",
          uiOutput(ns("highlight_top_ui")),
          uiOutput(ns("highlight_bottom_ui"))
        ),

        # FULL WIDTH HORIZONTAL AREAS TO IMPROVE
        div(class = "gw-card",
          p(class = "gw-card-title", "🔧 Department Areas That Need Improvement"),
          p(class = "gw-card-sub", "Per-department status breakdown across lab facilities, exams, teaching, library, and extracurricular areas"),
          div(class = "gw-improve-list",
            uiOutput(ns("improve_areas_ui"))
          )
        ),

        # AI Insights
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;",
            p(class = "gw-card-title", style = "margin:0;", "🤖 AI Qualitative Insights & Action Items"),
            actionButton(ns("btn_refresh_ai"), "↻ Refresh Analysis",
              style = "background:#3d5a2b; color:#fff; border:none; border-radius:6px; font-size:0.75rem; font-weight:600; padding:5px 12px;")
          ),
          p(class = "gw-card-sub", "Automatic feedback text summary and generated action items"),
          uiOutput(ns("ai_insights_ui"))
        ),

        # Most Positive & Most Negative Cards
        div(style = "display:grid; grid-template-columns:1fr 1fr; gap:18px; margin-bottom:20px;",
          div(class = "gw-card", style = "margin-bottom:0;",
            p(class = "gw-card-title", style = "color:#059669;", "👍 Most Positive Responses"),
            p(class = "gw-card-sub", "Highest-scoring written feedback"),
            uiOutput(ns("most_positive_ui"))
          ),
          div(class = "gw-card", style = "margin-bottom:0;",
            p(class = "gw-card-title", style = "color:#ef4444;", "👎 Most Negative Responses"),
            p(class = "gw-card-sub", "Lowest-scoring feedback needing attention"),
            uiOutput(ns("most_negative_ui"))
          )
        )
      )
    }

    # ── 2. ANALYTICS TAB VIEW ─────────────────────────────────────────────────
    render_analytics_tab <- function() {
      tagList(
        # Top Row: Sentiment Share & Monthly Volume
        div(style = "display:grid; grid-template-columns: 1fr 1.6fr; gap:20px; margin-bottom:22px;",
          div(class = "gw-card", style = "margin-bottom:0;",
            p(class = "gw-card-title", "Sentiment Share"),
            p(class = "gw-card-sub", "Distribution across responses"),
            plotlyOutput(ns("chart_pie"), height = "280px")
          ),
          div(class = "gw-card", style = "margin-bottom:0;",
            p(class = "gw-card-title", "Sentiment Over Time"),
            p(class = "gw-card-sub", "Monthly volume trend across semesters"),
            plotlyOutput(ns("chart_time"), height = "280px")
          )
        ),

        # MULTI-YEAR DEPARTMENT TRENDS ACROSS SEMESTERS (July-Nov & Dec-Apr)
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px; margin-bottom:12px;",
            div(
              p(class = "gw-card-title", style = "margin:0;", "📈 Multi-Year Department Trends Across Semesters"),
              p(class = "gw-card-sub", style = "margin:2px 0 0 0;", "Comparing feedback positivity & ratings across July–Nov (Odd Sems) and Dec–April (Even Sems)")
            ),
            div(style = "display:flex; gap:10px; align-items:center;",
              selectInput(ns("analytics_cycle_filter"), label = NULL,
                choices = c(
                  "All Semesters (Sem 1-8)" = "all",
                  "July–Nov (Odd Sems 1,3,5,7)" = "odd",
                  "Dec–April (Even Sems 2,4,6,8)" = "even"
                ), width = "220px"),
              selectInput(ns("analytics_metric_type"), label = NULL,
                choices = c("Positive Sentiment %" = "pos_pct", "Average Rating (1-5)" = "avg_rating"),
                width = "180px")
            )
          ),
          plotlyOutput(ns("chart_dept_multi_semester"), height = "360px")
        ),

        # TEACHER IMPROVEMENT TRACKER
        div(class = "gw-card",
          p(class = "gw-card-title", "👨‍🏫 Faculty Improvement & Performance Trajectory"),
          p(class = "gw-card-sub", "Tracking teacher rating evolution and positivity gains across consecutive semesters"),
          div(style = "display:grid; grid-template-columns: 1fr 1.2fr; gap:20px;",
            div(
              p(style = "font-weight:700; font-size:0.85rem; color:#1e3314; margin-bottom:8px;", "🏆 Top Improved Faculty Leaderboard"),
              uiOutput(ns("teacher_improvement_leaderboard_ui"))
            ),
            div(
              div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; margin-bottom:8px;",
                p(style = "font-weight:700; font-size:0.85rem; color:#1e3314; margin:0;", "🔍 Faculty Multi-Semester Trajectory"),
                div(style = "display:flex; gap:8px; align-items:center;",
                  selectInput(ns("inspector_dept_filter"), label = NULL, choices = c("All Departments" = "all"), width = "165px"),
                  selectInput(ns("teacher_select_inspector"), label = NULL, choices = c("Select Faculty" = ""), width = "180px")
                )
              ),
              uiOutput(ns("teacher_inspector_badge_ui")),
              plotlyOutput(ns("chart_teacher_trajectory"), height = "260px")
            )
          )
        ),

        # SUBJECT & ASPECT SATISFACTION TRAJECTORY
        div(class = "gw-card",
          p(class = "gw-card-title", "📚 Subject & Aspect Improvement Trajectory"),
          p(class = "gw-card-sub", "Longitudinal satisfaction trends for Teaching, Labs, Exams, Content, Library & Extracurriculars"),
          div(style = "display:grid; grid-template-columns: 1.4fr 1fr; gap:20px;",
            plotlyOutput(ns("chart_subject_trends"), height = "340px"),
            div(
              p(style = "font-weight:700; font-size:0.85rem; color:#1e3314; margin-bottom:8px;", "📊 Aspect Improvement Delta Summary"),
              uiOutput(ns("subject_delta_summary_ui"))
            )
          )
        ),

        # Department Ranking Breakdown
        div(class = "gw-card",
          p(class = "gw-card-title", "Department Performance Breakdown"),
          p(class = "gw-card-sub", "Current overall sentiment distribution per department"),
          div(style = "display:grid; grid-template-columns: 1.2fr 1fr; gap:20px;",
            uiOutput(ns("dept_rankings_list_ui")),
            plotlyOutput(ns("chart_dept_bar"), height = "340px")
          )
        )
      )
    }

    # ── 3. EXPLORER TAB VIEW ──────────────────────────────────────────────────
    render_explorer_tab <- function() {
      tagList(
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;",
            p(class = "gw-card-title", style = "margin:0;", "🔍 Search Student Reviews"),
            uiOutput(ns("explorer_pill_filters_ui"))
          ),
          textInput(ns("exp_search"), label = NULL, placeholder = "Search department, teacher, aspect or keyword...", width = "100%"),
          fluidRow(
            column(5,
              div(style = "max-height:460px; overflow-y:auto; border:1px solid #e2e8f0; border-radius:10px; background:#fff;",
                uiOutput(ns("explorer_items_list_ui"))
              )
            ),
            column(7,
              div(class = "gw-card", style = "background:#fafbfc; min-height:460px; margin-bottom:0;",
                uiOutput(ns("explorer_item_detail_ui"))
              )
            )
          )
        )
      )
    }

    # ── 4. SETTINGS TAB VIEW ──────────────────────────────────────────────────
    render_settings_tab <- function() {
      tagList(
        div(class = "gw-settings-group",
          div(class = "gw-settings-title", "🚨 Negative Alert Threshold"),
          div(class = "gw-settings-desc", "Trigger warning badges when an aspect's negative feedback exceeds this percentage."),
          sliderInput(ns("set_threshold"), label = NULL, min = 10, max = 50, value = 20, post = "%", width = "350px")
        ),
        div(class = "gw-settings-group",
          div(class = "gw-settings-title", "🤖 AI Insights Configuration"),
          div(class = "gw-settings-desc", "Enable background AI text processing and auto-refresh."),
          checkboxInput(ns("set_auto_ai"), label = "Auto-generate AI Insights on filter update", value = TRUE),
          checkboxInput(ns("set_extract_keywords"), label = "Extract positive & complaint keyword themes", value = TRUE)
        ),
        div(class = "gw-settings-group",
          div(class = "gw-settings-title", "📧 Admin Notification Preferences"),
          div(class = "gw-settings-desc", "Receive automated summaries and critical alerts."),
          checkboxInput(ns("set_email_digest"), label = "Send weekly sentiment summary digest email", value = TRUE),
          checkboxInput(ns("set_critical_alert"), label = "Send instant notification on critical lab/exam alerts (>30% neg)", value = TRUE)
        ),
        div(class = "gw-settings-group",
          actionButton(ns("btn_save_settings"), "Save Settings", class = "btn-success",
            style = "background:#3d5a2b; color:#fff; font-weight:700; border:none; padding:10px 24px; border-radius:8px; cursor:pointer;"),
          uiOutput(ns("settings_saved_msg"))
        )
      )
    }

    observeEvent(input$btn_save_settings, {
      output$settings_saved_msg <- renderUI({
        div(style = "margin-top:10px; color:#3d5a2b; font-weight:700; font-size:0.88rem;",
          "✓ Settings saved successfully!")
      })
    })

    # ── OVERVIEW: HIGHLIGHT CARDS (WITH HIGHLIGHTED TEACHER NAME) ────────────
    output$highlight_top_ui <- renderUI({
      ds <- dept_summary()
      if (is.null(ds) || nrow(ds) == 0) return(NULL)
      td <- ds[1, ]
      
      df <- filtered_df()
      top_fac <- df[!is.na(df$teacher_dept) & df$teacher_dept == td$department & !is.na(df$teacher_name), ]
      teacher_name_val <- if (nrow(top_fac) > 0) top_fac$teacher_name[1] else NULL

      div(class = "gw-highlight-card top",
        div(style = "display:flex; justify-content:space-between; align-items:center;",
          span(style = "font-size:0.75rem; font-weight:700; color:#059669; text-transform:uppercase;", "🏆 Top Performing Department"),
          span(style = "background:#d1fae5; color:#065f46; font-size:0.72rem; font-weight:700; padding:2px 8px; border-radius:9999px;", "Leading")
        ),
        h3(style = "margin:6px 0 4px; color:#1e3314; font-weight:800;", td$department),
        div(style = "margin-bottom:8px;", format_teacher_badge(teacher_name_val)),
        p(style = "font-size:0.85rem; color:#64748b; margin:0 0 10px;", sprintf("%d%% positive sentiment across %d responses", td$pos_pct, td$total)),
        div(style = "display:grid; grid-template-columns:repeat(3,1fr); gap:8px; border-top:1px dashed #a7f3d0; padding-top:8px; font-size:0.8rem;",
          div(span(style="color:#64748b;display:block;font-size:0.7rem;","Avg Rating"), span(style="font-weight:700;", sprintf("%.2f", td$avg_rating))),
          div(span(style="color:#64748b;display:block;font-size:0.7rem;","Positive"), span(style="font-weight:700;color:#059669;", td$pos)),
          div(span(style="color:#64748b;display:block;font-size:0.7rem;","Negative"), span(style="font-weight:700;color:#ef4444;", td$neg))
        )
      )
    })

    output$highlight_bottom_ui <- renderUI({
      ds <- dept_summary()
      if (is.null(ds) || nrow(ds) == 0) return(NULL)
      bd <- ds[nrow(ds), ]

      df <- filtered_df()
      bot_fac <- df[!is.na(df$teacher_dept) & df$teacher_dept == bd$department & !is.na(df$teacher_name), ]
      teacher_name_val <- if (nrow(bot_fac) > 0) bot_fac$teacher_name[1] else NULL

      primary_issue <- function(dept_name) {
        sub_neg <- df[!is.na(df$teacher_dept) & df$teacher_dept == dept_name & df$rating == -1, ]
        if (nrow(sub_neg) == 0) return("No major issues reported.")
        ac <- table(sub_neg$aspect)
        if (length(ac) == 0) return("No major issues reported.")
        w_asp <- names(ac)[which.max(ac)]
        w_lbl <- ASPECT_LABELS[w_asp] %||% w_asp
        sprintf("%s (%d negative reviews)", w_lbl, max(ac))
      }

      div(class = "gw-highlight-card bottom",
        div(style = "display:flex; justify-content:space-between; align-items:center;",
          span(style = "font-size:0.75rem; font-weight:700; color:#ef4444; text-transform:uppercase;", "⚠️ Needs Attention"),
          span(style = "background:#fee2e2; color:#991b1b; font-size:0.72rem; font-weight:700; padding:2px 8px; border-radius:9999px;", "Lowest")
        ),
        h3(style = "margin:6px 0 4px; color:#1e3314; font-weight:800;", bd$department),
        div(style = "margin-bottom:8px;", format_teacher_badge(teacher_name_val)),
        p(style = "font-size:0.85rem; color:#64748b; margin:0 0 10px;", sprintf("%d%% negative sentiment across %d responses", bd$neg_pct, bd$total)),
        div(style = "background:rgba(239,68,68,0.06); border:1px solid rgba(239,68,68,0.15); border-radius:6px; padding:6px 10px; font-size:0.78rem; color:#991b1b;",
          span(style = "font-weight:700; display:block; font-size:0.68rem; text-transform:uppercase;", "Primary Issue:"),
          primary_issue(bd$department)
        )
      )
    })

    # ── OVERVIEW: AREAS TO IMPROVE (FULL WIDTH HORIZONTAL LAYOUT) ─────────────
    output$improve_areas_ui <- renderUI({
      df <- filtered_df()
      ds <- dept_summary()
      if (is.null(ds) || nrow(df) == 0) return(p("No data available."))

      thresh <- if (!is.null(input$set_threshold)) input$set_threshold else 20

      cards <- lapply(ds$department, function(dept) {
        sub <- df[!is.na(df$teacher_dept) & df$teacher_dept == dept, ]
        if (nrow(sub) == 0) return(NULL)

        dp_row <- ds[ds$department == dept, ]
        pos_pct_lbl <- if (nrow(dp_row) > 0) sprintf("%d%% pos", dp_row$pos_pct[1]) else ""
        total_lbl <- sprintf("%d responses", nrow(sub))

        tags_html <- lapply(names(ASPECT_LABELS), function(asp) {
          asp_sub <- sub[!is.na(sub$aspect) & sub$aspect == asp, ]
          n <- nrow(asp_sub)
          if (n < 3) return(NULL)
          neg_pct <- round(sum(asp_sub$rating == -1, na.rm = TRUE) / n * 100)

          if (neg_pct >= (thresh + 10)) {
            span(class = "gw-tag critical", sprintf("%s %s 🔴 %d%% neg", ASPECT_ICONS[asp], ASPECT_LABELS[asp], neg_pct))
          } else if (neg_pct >= thresh) {
            span(class = "gw-tag moderate", sprintf("%s %s 🟡 %d%% neg", ASPECT_ICONS[asp], ASPECT_LABELS[asp], neg_pct))
          } else {
            span(class = "gw-tag good", sprintf("%s %s ✓", ASPECT_ICONS[asp], ASPECT_LABELS[asp]))
          }
        })
        tags_html <- Filter(Negate(is.null), tags_html)

        div(class = "gw-improve-card",
          div(class = "gw-improve-dept-info",
            div(class = "gw-improve-dept-name", dept),
            div(class = "gw-improve-dept-meta", sprintf("%s · %s", pos_pct_lbl, total_lbl))
          ),
          div(class = "gw-improve-tags-wrap", tags_html)
        )
      })
      tagList(Filter(Negate(is.null), cards))
    })

    # ── OVERVIEW: AI INSIGHTS ─────────────────────────────────────────────────
    output$ai_insights_ui <- renderUI({
      input$btn_refresh_ai
      df <- filtered_df()
      if (nrow(df) == 0) return(p("No data."))

      pos_texts <- df$text[df$rating == 1  & !is.na(df$text) & nchar(df$text) > 8]
      neg_texts <- df$text[df$rating == -1 & !is.na(df$text) & nchar(df$text) > 8]

      pos_words <- tryCatch(get_word_frequencies(pos_texts, top_n = 5)$word, error = function(e) character(0))
      neg_words <- tryCatch(get_word_frequencies(neg_texts, top_n = 5)$word, error = function(e) character(0))

      pos_badges <- if (length(pos_words) > 0) lapply(pos_words, function(w) span(class = "gw-tag good", w)) else list(span("N/A"))
      neg_badges <- if (length(neg_words) > 0) lapply(neg_words, function(w) span(class = "gw-tag critical", w)) else list(span("N/A"))

      actions <- c()
      if (any(c("lab", "equipment", "hardware", "software") %in% neg_words)) {
        actions <- c(actions, "🔬 Lab Facilities: Upgrade practical lab computers, update software packages, and ensure adequate student setups.")
      }
      if (any(c("exam", "schedule", "clashes", "grading", "marks") %in% neg_words)) {
        actions <- c(actions, "📝 Examinations: Resolve timetable clashes, publish results promptly, and ensure transparent evaluation rubrics.")
      }
      if (any(c("library", "books", "seating", "wifi") %in% neg_words)) {
        actions <- c(actions, "📖 Library & Resources: Add reference copies for core subjects, extend operating hours, and boost Wi-Fi bandwidth.")
      }
      if (any(c("teaching", "professor", "lectures", "slides") %in% neg_words)) {
        actions <- c(actions, "🎓 Teaching Quality: Offer instructional design workshops and faculty peer-learning sessions.")
      }
      if (length(actions) == 0) {
        actions <- c(
          "Review core course delivery and establish student feedback advisory groups.",
          "Inspect laboratory safety and equipment functionality quarterly.",
          "Share top-performing teaching methodologies across departments."
        )
      }

      action_lis <- lapply(seq_along(actions), function(i) {
        div(class = "gw-action-item",
          div(class = "gw-action-num", i),
          span(actions[[i]])
        )
      })

      div(
        div(class = "gw-ai-box",
          div(class = "gw-ai-title", "📊 Overall Summary"),
          p(style = "margin:0; font-size:0.85rem; color:#334155;",
            sprintf("Analysed %s responses for %s in %s: %d%% positive, %d%% negative.",
                    formatC(nrow(df), format="d", big.mark=","),
                    if (is.null(input$admin_dept_filter) || input$admin_dept_filter == "all") "All Departments" else input$admin_dept_filter,
                    if (is.null(input$admin_semester_filter) || input$admin_semester_filter == "all") "All Semesters" else input$admin_semester_filter,
                    round(sum(df$rating == 1) / nrow(df) * 100),
                    round(sum(df$rating == -1) / nrow(df) * 100)))
        ),
        div(style = "display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-bottom:12px;",
          div(class = "gw-ai-box",
            div(class = "gw-ai-title", "✅ Positive Themes"),
            div(pos_badges)
          ),
          div(class = "gw-ai-box",
            div(class = "gw-ai-title", "❌ Complaint Themes"),
            div(neg_badges)
          )
        ),
        div(class = "gw-ai-box",
          div(class = "gw-ai-title", "🎯 Recommended Action Items"),
          div(action_lis)
        )
      )
    })

    # ── OVERVIEW: MOST POSITIVE / NEGATIVE (WITH HIGHLIGHTED TEACHER BADGE) ────
    render_feedback_cards <- function(df_sub, empty_msg) {
      if (nrow(df_sub) == 0) return(div(style="color:#94a3b8;font-style:italic;padding:14px;text-align:center;", empty_msg))
      df_sub$len <- nchar(df_sub$text)
      df_sub <- df_sub[order(-df_sub$len), ]
      top3   <- head(df_sub, 3)
      lapply(seq_len(nrow(top3)), function(i) {
        r <- top3[i, ]
        course <- get_course_name(r$teacher_dept, r$aspect)
        dept   <- if (is.na(r$teacher_dept)) "Other" else r$teacher_dept
        teacher <- if (is.na(r$teacher_name)) NULL else r$teacher_name

        div(style="border:1px solid #e2ebd8;border-radius:8px;padding:12px;margin-bottom:8px;background:#fff;",
          p(style="margin:0 0 8px;color:#1a2e23;font-size:0.84rem;line-height:1.45;", r$text),
          div(style="display:flex;gap:6px;align-items:center;flex-wrap:wrap;",
            span(class="gw-tag good", dept),
            span(class="gw-tag good", course),
            format_teacher_badge(teacher)
          )
        )
      })
    }

    output$most_positive_ui <- renderUI({
      df <- filtered_df()
      sub <- df[df$rating == 1 & !is.na(df$text) & nchar(df$text) > 5, ]
      tagList(render_feedback_cards(sub, "No positive feedback in this scope."))
    })

    output$most_negative_ui <- renderUI({
      df <- filtered_df()
      sub <- df[df$rating == -1 & !is.na(df$text) & nchar(df$text) > 5, ]
      tagList(render_feedback_cards(sub, "No negative feedback in this scope."))
    })

    # ── ANALYTICS: CHARTS ─────────────────────────────────────────────────────
    output$chart_pie <- renderPlotly({
      kv <- kpi_vals()
      if (kv$n == 0) return(plot_ly())
      df <- data.frame(
        Sentiment = c("Positive", "Neutral", "Negative"),
        Count     = c(kv$pos, kv$neu, kv$neg),
        Color     = c("#059669", "#f59e0b", "#ef4444")
      )
      plot_ly(df, labels = ~Sentiment, values = ~Count, type = "pie", hole = 0.6,
              marker = list(colors = ~Color), textinfo = "percent") %>%
        layout(
          annotations = list(list(
            text = sprintf("<b>%s</b><br><span style='color:#94a3b8;font-size:10px'>responses</span>", formatC(kv$n, format="d", big.mark=",")),
            x=0.5, y=0.5, showarrow=FALSE, font=list(size=14)
          )),
          paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
          margin = list(l=10,r=10,t=10,b=10), showlegend = TRUE
        )
    })

    output$chart_time <- renderPlotly({
      df <- raw_df()
      if (nrow(df) == 0) return(plot_ly())

      dept <- input$admin_dept_filter
      if (!is.null(dept) && dept != "all") df <- df[!is.na(df$teacher_dept) & df$teacher_dept == dept, ]

      df$yr_mon <- format(as.POSIXct(df$created_at), "%b %Y")
      df$yr_mon_order <- format(as.POSIXct(df$created_at), "%Y-%m")

      months_df <- aggregate(cbind(pos = rating == 1, neu = rating == 0, neg = rating == -1) ~ yr_mon + yr_mon_order, data = df, FUN = sum)
      months_df <- months_df[order(months_df$yr_mon_order), ]

      plot_ly(months_df, x = ~yr_mon, y = ~pos, name = "Positive", type = "scatter", mode = "lines+markers",
              line = list(color = "#059669", width = 2.5), marker = list(color = "#059669", size = 6)) %>%
        add_trace(y = ~neu, name = "Neutral", line = list(color = "#f59e0b", width = 2.5), marker = list(color = "#f59e0b", size = 6)) %>%
        add_trace(y = ~neg, name = "Negative", line = list(color = "#ef4444", width = 2.5), marker = list(color = "#ef4444", size = 6)) %>%
        layout(
          paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
          xaxis = list(title = "", tickangle = -25), yaxis = list(title = "Responses"),
          margin = list(l=30,r=10,t=10,b=40), showlegend = TRUE
        )
    })

    output$dept_rankings_list_ui <- renderUI({
      ds <- dept_summary()
      if (is.null(ds)) return(p("No data."))
      n_depts <- nrow(ds)

      rows <- lapply(seq_len(n_depts), function(i) {
        d <- ds[i, ]
        rank_cls <- if (i == 1) "gold" else if (i == n_depts) "bottom" else "other"
        rank_lbl <- if (i == 1) "1st" else if (i == 2) "2nd" else if (i == 3) "3rd" else if (i == n_depts) "↓" else sprintf("%d", i)

        div(class = "gw-dept-row",
          div(class = sprintf("gw-dept-rank %s", rank_cls), rank_lbl),
          div(style = "font-weight:700; font-size:0.85rem; flex:1;", d$department),
          div(style = "width:120px; font-size:0.75rem;",
            div(style = "color:#059669; font-weight:700;", sprintf("%d%% pos", d$pos_pct)),
            div(class = "gw-progress", div(class = "gw-progress-bar", style = sprintf("width:%d%%;background:#059669;", d$pos_pct)))
          ),
          span(style = "font-size:0.72rem; color:#64748b;", sprintf("%d resp.", d$total))
        )
      })
      tagList(rows)
    })

    output$chart_dept_bar <- renderPlotly({
      ds <- dept_summary()
      if (is.null(ds)) return(plot_ly())
      plot_ly(ds, y = ~reorder(department, pos_pct), x = ~pos, name = "Positive", type = "bar", orientation = "h", marker = list(color = "#059669")) %>%
        add_trace(x = ~neu, name = "Neutral", marker = list(color = "#f59e0b")) %>%
        add_trace(x = ~neg, name = "Negative", marker = list(color = "#ef4444")) %>%
        layout(barmode = "stack", paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", margin = list(l=10,r=10,t=10,b=30))
    })

    # ── OVERVIEW: TIMELY RESPONSES & DATE TIMELINE ───────────────────────────
    output$chart_overview_timeline <- renderPlotly({
      df <- get_timely_response_timeline()
      if (nrow(df) == 0) return(plot_ly())

      sem_summary <- aggregate(cbind(response_count, positive_count, neutral_count, negative_count) ~ semester, data = df, FUN = sum)
      sem_summary$sem_num <- as.integer(gsub("[^0-9]", "", sem_summary$semester))
      sem_summary <- sem_summary[order(sem_summary$sem_num), ]

      plot_ly(sem_summary, x = ~semester, y = ~positive_count, name = "Positive Feedback", type = "bar", marker = list(color = "#059669")) %>%
        add_trace(y = ~neutral_count, name = "Neutral Feedback", marker = list(color = "#f59e0b")) %>%
        add_trace(y = ~negative_count, name = "Negative Feedback", marker = list(color = "#ef4444")) %>%
        layout(
          barmode = "stack",
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(title = "Academic Semester Cycle & Submission Dates", tickangle = -15),
          yaxis = list(title = "Total Student Responses"),
          margin = list(l = 40, r = 10, t = 10, b = 40),
          legend = list(orientation = "h", x = 0, y = -0.25)
        )
    })

    # ── ANALYTICS: MULTI-YEAR DEPARTMENT TRENDS ACROSS SEMESTERS ─────────────
    output$chart_dept_multi_semester <- renderPlotly({
      trends <- get_semester_department_trends()
      if (nrow(trends) == 0) return(plot_ly())

      # Filter by academic cycle (July-Nov odd vs Dec-Apr even)
      cycle <- input$analytics_cycle_filter
      if (!is.null(cycle) && cycle != "all") {
        sem_nums <- as.integer(gsub("[^0-9]", "", trends$semester))
        if (cycle == "odd") {
          trends <- trends[!is.na(sem_nums) & sem_nums %% 2 == 1, ]
        } else if (cycle == "even") {
          trends <- trends[!is.na(sem_nums) & sem_nums %% 2 == 0, ]
        }
      }

      # Filter by header department filter
      dept <- input$admin_dept_filter
      if (!is.null(dept) && dept != "all") {
        trends <- trends[!is.na(trends$teacher_dept) & trends$teacher_dept == dept, ]
      }

      metric <- input$analytics_metric_type
      if (is.null(metric)) metric <- "pos_pct"

      trends$sem_num <- as.integer(gsub("[^0-9]", "", trends$semester))
      trends <- trends[order(trends$sem_num), ]

      depts <- unique(trends$teacher_dept)
      p <- plot_ly()
      colors <- c("#059669", "#2563eb", "#d97706", "#7c3aed", "#db2777", "#0891b2", "#ea580c", "#475569")

      for (i in seq_along(depts)) {
        d_name <- depts[i]
        d_sub <- trends[trends$teacher_dept == d_name, ]
        col <- colors[((i - 1) %% length(colors)) + 1]
        
        y_vals <- if (metric == "avg_rating") d_sub$avg_rating else d_sub$pos_pct
        hover_txt <- sprintf("<b>%s</b><br>%s<br>Positivity: %.1f%%<br>Avg Rating: %.2f / 5<br>Total Responses: %d",
                             d_name, d_sub$semester, d_sub$pos_pct, d_sub$avg_rating, d_sub$total_responses)

        p <- p %>% add_trace(
          data = d_sub,
          x = ~semester,
          y = y_vals,
          name = d_name,
          type = "scatter",
          mode = "lines+markers",
          hoverinfo = "text",
          text = hover_txt,
          line = list(width = 3, color = col),
          marker = list(size = 8, color = col)
        )
      }

      y_title <- if (metric == "avg_rating") "Average Rating (1 to 5)" else "Positive Sentiment %"
      p %>% layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        xaxis = list(title = "Academic Semester Cycle (Chronological)", tickangle = -15),
        yaxis = list(title = y_title),
        margin = list(l = 40, r = 10, t = 10, b = 40),
        legend = list(orientation = "h", x = 0, y = -0.25)
      )
    })

    # ── ANALYTICS: FACULTY IMPROVEMENT TRACKER ────────────────────────────────
    teacher_metrics_df <- reactive({
      get_teacher_improvement_metrics()
    })

    observe({
      fac_df <- get_faculty_list()
      if (nrow(fac_df) > 0) {
        depts <- sort(unique(fac_df$department[!is.na(fac_df$department) & fac_df$department != ""]))
        updateSelectInput(session, "inspector_dept_filter", choices = c("All Departments" = "all", setNames(depts, depts)))
      }
    })

    observe({
      fac_df <- get_faculty_list()
      sel_dept <- input$inspector_dept_filter
      if (!is.null(sel_dept) && sel_dept != "all") {
        fac_df <- fac_df[!is.na(fac_df$department) & fac_df$department == sel_dept, ]
      }
      if (nrow(fac_df) > 0) {
        teachers <- sort(unique(fac_df$name))
        cur_sel <- input$teacher_select_inspector
        sel_val <- if (!is.null(cur_sel) && cur_sel %in% teachers) cur_sel else teachers[1]
        updateSelectInput(session, "teacher_select_inspector", choices = setNames(teachers, teachers), selected = sel_val)
      }
    })

    output$teacher_improvement_leaderboard_ui <- renderUI({
      df <- teacher_metrics_df()
      if (nrow(df) == 0) return(p("No faculty feedback data available."))

      teachers <- unique(df$teacher_name)
      summary_list <- lapply(teachers, function(t) {
        sub <- df[df$teacher_name == t, ]
        sub$sem_num <- as.integer(gsub("[^0-9]", "", sub$semester))
        sub <- sub[order(sub$sem_num), ]
        n_sems <- nrow(sub)
        if (n_sems == 0) return(NULL)
        
        first_pos <- sub$pos_pct[1]
        last_pos  <- sub$pos_pct[n_sems]
        delta     <- last_pos - first_pos
        last_avg  <- sub$avg_rating[n_sems]
        dept      <- sub$teacher_dept[1]
        total_n   <- sum(sub$total_responses)

        data.frame(
          teacher_name = t,
          teacher_dept = dept,
          first_pos    = first_pos,
          last_pos     = last_pos,
          delta        = delta,
          last_avg     = last_avg,
          total_n      = total_n,
          sems_covered = n_sems,
          stringsAsFactors = FALSE
        )
      })

      summary_df <- do.call(rbind, Filter(Negate(is.null), summary_list))
      if (is.null(summary_df) || nrow(summary_df) == 0) return(p("No metrics computed."))

      summary_df <- summary_df[order(-summary_df$delta), ]
      top_teachers <- head(summary_df, 6)

      cards <- lapply(seq_len(nrow(top_teachers)), function(i) {
        r <- top_teachers[i, ]
        delta_str <- sprintf("%s%.1f%% Positivity", if (r$delta >= 0) "+" else "", r$delta)
        badge_cls <- if (r$delta > 5) "gw-tag good" else if (r$delta < -5) "gw-tag critical" else "gw-tag moderate"
        icon_str  <- if (r$delta > 5) "📈" else if (r$delta < -5) "🔻" else "➡️"

        div(style = "padding:10px 12px; border:1px solid #e2ebd8; border-radius:8px; margin-bottom:8px; background:#fff; display:flex; justify-content:space-between; align-items:center;",
          div(
            div(style = "font-weight:700; font-size:0.86rem; color:#1e3314;", sprintf("👨‍🏫 %s", r$teacher_name)),
            div(style = "font-size:0.75rem; color:#64748b;", sprintf("%s · %d sems", r$teacher_dept, r$sems_covered))
          ),
          div(style = "text-align:right;",
            span(class = badge_cls, sprintf("%s %s", icon_str, delta_str)),
            div(style = "font-size:0.72rem; color:#64748b; margin-top:2px;", sprintf("Rating: %.2f/5", r$last_avg))
          )
        )
      })

      tagList(cards)
    })

    output$teacher_inspector_badge_ui <- renderUI({
      sel_t <- input$teacher_select_inspector
      df <- teacher_metrics_df()
      if (is.null(sel_t) || sel_t == "" || nrow(df) == 0) return(NULL)

      sub <- df[df$teacher_name == sel_t, ]
      if (nrow(sub) == 0) return(NULL)

      sub$sem_num <- as.integer(gsub("[^0-9]", "", sub$semester))
      sub <- sub[order(sub$sem_num), ]
      
      first_pos <- sub$pos_pct[1]
      last_pos  <- sub$pos_pct[nrow(sub)]
      delta     <- last_pos - first_pos
      avg_rat   <- mean(sub$avg_rating)
      tot_fbs   <- sum(sub$total_responses)

      status_msg <- if (delta >= 10) "Significant Improvement 🚀"
                    else if (delta >= 0) "Steady / Consistent Performance ⭐"
                    else "Needs Targeted Support ⚠️"

      div(style = "background:#f4f8f2; border:1px solid #d4e3ca; border-radius:8px; padding:10px 14px; margin-bottom:12px; font-size:0.8rem;",
        div(style = "display:flex; justify-content:space-between; align-items:center;",
          span(style = "font-weight:800; color:#1e3314; font-size:0.9rem;", sel_t),
          span(style = "font-weight:700; color:#3d5a2b;", status_msg)
        ),
        div(style = "display:grid; grid-template-columns:repeat(3,1fr); gap:8px; margin-top:6px; color:#475569;",
          div(span("Sem 1 Positivity: "), b(sprintf("%.1f%%", first_pos))),
          div(span("Latest Positivity: "), b(sprintf("%.1f%%", last_pos))),
          div(span("Net Delta: "), b(style = if (delta >= 0) "color:#059669;" else "color:#ef4444;", sprintf("%s%.1f%%", if (delta>=0) "+" else "", delta)))
        )
      )
    })

    output$chart_teacher_trajectory <- renderPlotly({
      sel_t <- input$teacher_select_inspector
      df <- teacher_metrics_df()
      if (is.null(sel_t) || sel_t == "" || nrow(df) == 0) return(plot_ly())

      sub <- df[df$teacher_name == sel_t, ]
      if (nrow(sub) == 0) return(plot_ly())

      sub$sem_num <- as.integer(gsub("[^0-9]", "", sub$semester))
      sub <- sub[order(sub$sem_num), ]

      plot_ly(sub, x = ~semester, y = ~pos_pct, type = "scatter", mode = "lines+markers",
              name = "Positivity %", line = list(color = "#059669", width = 3),
              marker = list(color = "#059669", size = 8)) %>%
        add_trace(y = ~avg_rating * 20, name = "Avg Rating (x20)", line = list(color = "#2563eb", width = 2, dash = "dash"),
                  marker = list(color = "#2563eb", size = 6)) %>%
        layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(title = ""), yaxis = list(title = "Percentage (%)", range = c(0, 100)),
          margin = list(l = 35, r = 10, t = 10, b = 35),
          showlegend = TRUE
        )
    })

    # ── ANALYTICS: SUBJECT & ASPECT SATISFACTION TRAJECTORY ───────────────────
    output$chart_subject_trends <- renderPlotly({
      sub_df <- get_subject_satisfaction_trends()
      if (nrow(sub_df) == 0) return(plot_ly())

      sub_df$sem_num <- as.integer(gsub("[^0-9]", "", sub_df$semester))
      sub_df <- sub_df[order(sub_df$sem_num), ]

      aspects <- unique(sub_df$aspect)
      p <- plot_ly()
      colors <- c("#059669", "#2563eb", "#d97706", "#7c3aed", "#db2777", "#ea580c")

      for (i in seq_along(aspects)) {
        asp <- aspects[i]
        a_sub <- sub_df[sub_df$aspect == asp, ]
        col <- colors[((i - 1) %% length(colors)) + 1]
        lbl <- ASPECT_LABELS[asp] %||% asp

        p <- p %>% add_trace(
          data = a_sub,
          x = ~semester,
          y = ~pos_pct,
          name = lbl,
          type = "scatter",
          mode = "lines+markers",
          line = list(width = 2.5, color = col),
          marker = list(size = 7, color = col)
        )
      }

      p %>% layout(
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
        xaxis = list(title = "Semester", tickangle = -15),
        yaxis = list(title = "Positive Sentiment %", range = c(0, 100)),
        margin = list(l = 40, r = 10, t = 10, b = 40),
        legend = list(orientation = "h", x = 0, y = -0.25)
      )
    })

    output$subject_delta_summary_ui <- renderUI({
      sub_df <- get_subject_satisfaction_trends()
      if (nrow(sub_df) == 0) return(p("No aspect trend data."))

      aspects <- unique(sub_df$aspect)
      cards <- lapply(aspects, function(asp) {
        a_sub <- sub_df[sub_df$aspect == asp, ]
        a_sub$sem_num <- as.integer(gsub("[^0-9]", "", a_sub$semester))
        a_sub <- a_sub[order(a_sub$sem_num), ]
        n <- nrow(a_sub)
        if (n == 0) return(NULL)

        first_p <- a_sub$pos_pct[1]
        last_p  <- a_sub$pos_pct[n]
        delta   <- last_p - first_p
        lbl     <- ASPECT_LABELS[asp] %||% asp
        ico     <- ASPECT_ICONS[asp] %||% "📚"

        badge_cls <- if (delta > 3) "gw-tag good" else if (delta < -3) "gw-tag critical" else "gw-tag moderate"
        status_txt <- if (delta > 3) sprintf("+%.1f%% Improved", delta)
                      else if (delta < -3) sprintf("%.1f%% Declined", delta)
                      else "Stable"

        div(style = "padding:8px 12px; border:1px solid #e2ebd8; border-radius:8px; margin-bottom:6px; background:#fff; display:flex; justify-content:space-between; align-items:center;",
          div(
            span(style = "font-weight:700; font-size:0.83rem; color:#1e3314;", sprintf("%s %s", ico, lbl)),
            div(style = "font-size:0.72rem; color:#64748b;", sprintf("Latest Rating: %.2f/5", a_sub$avg_rating[n]))
          ),
          span(class = badge_cls, status_txt)
        )
      })
      tagList(Filter(Negate(is.null), cards))
    })

    # ── EXPLORER TAB (WITH HIGHLIGHTED TEACHER BADGE) ─────────────────────────
    exp_pill <- reactiveVal("all")
    exp_active_id <- reactiveVal(NULL)

    output$explorer_pill_filters_ui <- renderUI({
      cur <- exp_pill()
      pills <- c(all = "All", positive = "Positive", negative = "Negative", neutral = "Neutral")
      btns <- lapply(names(pills), function(k) {
        cls <- if (cur == k) "gw-pill-btn active" else "gw-pill-btn"
        tags$button(class = cls,
          onclick = sprintf("Shiny.setInputValue('%s','%s',{priority:'event'})", session$ns("exp_pill_click"), k),
          pills[[k]])
      })
      tagList(btns)
    })

    observeEvent(input$exp_pill_click, { exp_pill(input$exp_pill_click) })

    exp_df <- reactive({
      df <- filtered_df()
      q <- input$exp_search
      if (!is.null(q) && nchar(trimws(q)) > 0) {
        q <- tolower(trimws(q))
        df <- df[grepl(q, tolower(df$text)) | grepl(q, tolower(df$aspect)) | grepl(q, tolower(df$teacher_dept)) | grepl(q, tolower(df$teacher_name)), ]
      }
      k <- exp_pill()
      if (k != "all") {
        target <- switch(k, positive = 1L, neutral = 0L, negative = -1L)
        df <- df[df$rating == target, ]
      }
      df
    })

    observe({
      df <- exp_df()
      if (nrow(df) > 0) {
        cur <- exp_active_id()
        if (is.null(cur) || !(cur %in% df$id)) exp_active_id(df$id[1])
      } else {
        exp_active_id(NULL)
      }
    })

    observeEvent(input$exp_item_click, { exp_active_id(input$exp_item_click) })

    output$explorer_items_list_ui <- renderUI({
      df <- exp_df()
      if (nrow(df) == 0) return(div(style="padding:20px;text-align:center;color:#94a3b8;", "No entries found."))
      top50 <- head(df, 50)
      sel <- exp_active_id()

      items <- lapply(seq_len(nrow(top50)), function(i) {
        r <- top50[i, ]
        bg <- if (!is.null(sel) && sel == r$id) "#f4f8f2" else "#fff"
        badge_cls <- if (r$rating == 1) "gw-tag good" else if (r$rating == -1) "gw-tag critical" else "gw-tag"
        badge_lbl <- if (r$rating == 1) "positive" else if (r$rating == -1) "negative" else "neutral"

        div(style = sprintf("padding:12px 14px; border-bottom:1px solid #f1f5f9; cursor:pointer; background:%s;", bg),
          onclick = sprintf("Shiny.setInputValue('%s',%d,{priority:'event'})", session$ns("exp_item_click"), r$id),
          div(style = "display:flex; justify-content:space-between; align-items:center;",
            span(style = "font-weight:700; font-size:0.84rem; color:#1e3314;", get_course_name(r$teacher_dept, r$aspect)),
            span(class = badge_cls, badge_lbl)
          ),
          p(style = "margin:4px 0; font-size:0.78rem; color:#64748b; line-height:1.4;", substr(r$text, 1, 85)),
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-top:4px;",
            span(style = "font-size:0.7rem; color:#94a3b8;", sprintf("%s · %s", if (is.na(r$teacher_dept)) "Other" else r$teacher_dept,
              tryCatch(format(as.POSIXct(r$created_at), "%b %d, %Y"), error=function(e) ""))),
            format_teacher_badge(r$teacher_name)
          )
        )
      })
      tagList(items)
    })

    output$explorer_item_detail_ui <- renderUI({
      sel_id <- exp_active_id()
      if (is.null(sel_id)) return(div(style="padding:60px;text-align:center;color:#94a3b8;","Select an item to view details."))
      df <- raw_df()
      item <- df[df$id == sel_id, ]
      if (nrow(item) == 0) return(NULL)

      sent_score <- if (item$rating == 1) "+0.85" else if (item$rating == -1) "-0.75" else "+0.05"
      course <- get_course_name(item$teacher_dept, item$aspect)
      dept <- if (is.na(item$teacher_dept)) "Other" else item$teacher_dept

      div(style = "display:flex; flex-direction:column; gap:14px;",
        div(style = "display:flex; justify-content:space-between; align-items:flex-start;",
          div(
            span(style = "font-size:0.7rem; color:#94a3b8; font-family:monospace;", sprintf("FB-%04d", item$id)),
            h4(style = "margin:2px 0; color:#1e3314; font-weight:800; font-size:1.1rem;", course),
            div(style = "margin-top:4px; display:flex; align-items:center; gap:8px;",
              span(style = "font-size:0.82rem; color:#64748b;", dept),
              format_teacher_badge(item$teacher_name)
            )
          ),
          span(class = if (item$rating == 1) "gw-tag good" else if (item$rating == -1) "gw-tag critical" else "gw-tag",
            if (item$rating == 1) "positive" else if (item$rating == -1) "negative" else "neutral")
        ),
        div(style = "display:grid; grid-template-columns:repeat(3,1fr); gap:8px; padding:10px 0; border-top:1px dashed #e0ebd5; border-bottom:1px dashed #e0ebd5;",
          div(span(style="font-size:0.67rem;color:#94a3b8;display:block;","Sentiment Score"), span(style="font-weight:700;font-family:monospace;color:#1e3314;", sent_score)),
          div(span(style="font-size:0.67rem;color:#94a3b8;display:block;","Semester"), span(style="font-weight:700;color:#1e3314;", item$semester %||% "N/A")),
          div(span(style="font-size:0.67rem;color:#94a3b8;display:block;","Received"), span(style="font-weight:600;color:#64748b;", format(as.POSIXct(item$created_at), "%b %d, %Y")))
        ),
        div(
          span(style="font-size:0.7rem;color:#94a3b8;text-transform:uppercase;font-weight:700;display:block;margin-bottom:4px;","Student Feedback"),
          tags$blockquote(style="margin:0; padding:10px 14px; border-left:3px solid #3d5a2b; font-size:0.88rem; color:#1a2e23; line-height:1.5; font-style:italic; background:#fff; border-radius:0 8px 8px 0;", item$text)
        ),
        div(style="background:#ffffff; border:1px solid #e0ebd5; border-radius:8px; padding:12px 14px;",
          span(style="font-size:0.7rem; color:#94a3b8; text-transform:uppercase; font-weight:700; display:block; margin-bottom:4px;","Action Situation"),
          p(style="margin:0; font-size:0.83rem; color:#334155; line-height:1.45;",
            switch(as.character(item$rating),
              "1"  = "Positive — stable performance. Maintain teaching methodology.",
              "0"  = "Neutral — monitor trends. No immediate intervention required.",
              "-1" = sprintf("Negative — action needed. Recommend review session with %s regarding %s.", item$teacher_name %||% "faculty", course)
            ))
        )
      )
    })

    # `%||%` helper
    `%||%` <- function(a, b) if (!is.null(a) && !is.na(a) && a != "") a else b

    # Export PDF & Logout
    output$export_pdf <- pdf_report_handler(filtered_df, "Campus Listen Report")
    observeEvent(input$btn_logout, { logout_trigger(logout_trigger() + 1) })
  })
}
