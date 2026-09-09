# modules/admin_portal.R — Institutional Executive Analytics Dashboard
# Features: Enterprise Institutional Design + Deep Blue & Slate Theme + Chronological Time-Series Fixes + Raw Submissions Dataset & Notice Center

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
  teaching           = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='14' height='14' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M22 10v6M2 10l10-5 10 5-10 5z'/><path d='M6 12.5V16a6 3 0 0 0 12 0v-3.5'/></svg>",
  coursecontent      = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='14' height='14' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M4 19.5A2.5 2.5 0 0 1 6.5 17H20'/><path d='M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z'/></svg>",
  examination        = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='14' height='14' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z'/><polyline points='14 2 14 8 20 8'/></svg>",
  labwork            = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='14' height='14' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M10 2v7.31'/><path d='M14 9.3V2'/><path d='M8.5 2h7'/><path d='M14 9.3a6.5 6.5 0 1 1-4 0'/><path d='M5.52 16h12.96'/></svg>",
  library_facilities = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='14' height='14' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='m16 6 4 14'/><path d='M12 6v14'/><path d='M8 8v12'/><path d='M4 4v16'/></svg>",
  extracurricular    = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='14' height='14' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='8' r='6'/><path d='M15.477 12.89 17 22l-5-3-5 3 1.523-9.11'/></svg>"
)

SEMESTER_ORDER <- paste("Semester", 1:8)

# Helper to render clean faculty name badge
format_teacher_badge <- function(teacher_name) {
  if (is.null(teacher_name) || is.na(teacher_name) || teacher_name == "" || teacher_name == "N/A") {
    return(span(class = "gw-teacher-badge-none", "Unassigned"))
  }
  span(class = "gw-teacher-badge",
    HTML("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='13' height='13' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' style='vertical-align:middle;margin-right:3px;'><path d='M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2'/><circle cx='12' cy='7' r='4'/></svg>"),
    teacher_name
  )
}

# ══════════════════════════════════════════════════════════════════════════════
#  UI
# ══════════════════════════════════════════════════════════════════════════════
adminPortalUI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head(
      tags$style(HTML("
        /* ── ENTERPRISE INSTITUTIONAL SYSTEM ────────────────────────────────── */
        .gw-app {
          display: flex;
          min-height: 100vh;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background-color: #f8fafc;
          color: #0f172a;
          font-size: 0.9375rem;
        }

        /* ── SIDEBAR ─────────────────────────────────────────────────────────── */
        .gw-sidebar {
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
        .gw-sidebar-brand {
          padding: 20px 20px;
          display: flex;
          align-items: center;
          gap: 12px;
          border-bottom: 1px solid #e2e8f0;
          background: #ffffff;
        }
        .gw-brand-icon {
          width: 38px; height: 38px;
          background: #1e40af;
          border-radius: 8px;
          display: flex; align-items: center; justify-content: center;
          color: #ffffff;
          flex-shrink: 0;
        }
        .gw-brand-name {
          font-weight: 700;
          font-size: 1.05rem;
          color: #0f172a;
          letter-spacing: -0.02em;
          line-height: 1.2;
        }
        .gw-brand-sub { font-size: 0.75rem; color: #64748b; margin-top: 2px; }

        /* Nav links */
        .gw-nav {
          padding: 16px 12px;
          display: flex;
          flex-direction: column;
          gap: 4px;
          flex: 1;
        }
        .gw-nav-section-title {
          font-size: 0.6875rem;
          font-weight: 700;
          color: #94a3b8;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          padding: 12px 14px 6px 14px;
        }
        .gw-nav-btn {
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
        .gw-nav-btn:hover {
          background: #f1f5f9;
          color: #0f172a;
        }
        .gw-nav-btn.active {
          background: #eff6ff !important;
          color: #1e40af !important;
          font-weight: 600;
          border-left: 3px solid #1e40af;
        }
        .gw-nav-btn.active svg { stroke: #1e40af !important; }

        /* Sidebar user footer */
        .gw-sidebar-user {
          padding: 16px 18px;
          border-top: 1px solid #e2e8f0;
          display: flex;
          align-items: center;
          justify-content: space-between;
          background: #ffffff;
        }
        .gw-user-info { display: flex; flex-direction: column; gap: 1px; }
        .gw-user-name {
          font-weight: 600;
          font-size: 0.875rem;
          color: #0f172a;
        }
        .gw-user-role {
          font-size: 0.75rem;
          color: #64748b;
        }

        /* ── BADGES ─────────────────────────────────────────────────────────── */
        .gw-teacher-badge {
          display: inline-flex;
          align-items: center;
          background: #f1f5f9;
          color: #1e40af;
          font-weight: 600;
          padding: 2px 8px;
          border-radius: 4px;
          border: 1px solid #e2e8f0;
          font-size: 0.75rem;
        }
        .gw-teacher-badge-none {
          display: inline-flex;
          align-items: center;
          background: #f8fafc;
          color: #94a3b8;
          font-size: 0.72rem;
          padding: 2px 6px;
          border-radius: 4px;
          border: 1px dashed #cbd5e1;
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
          border-bottom: 1px solid #e2e8f0;
          padding: 16px 28px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          position: sticky;
          top: 0;
          z-index: 90;
        }
        .gw-header-title {
          font-size: 1.25rem;
          font-weight: 700;
          color: #0f172a;
          margin: 0;
          letter-spacing: -0.02em;
        }
        .gw-header-sub {
          font-size: 0.8125rem;
          color: #64748b;
          margin: 2px 0 0 0;
        }

        /* Filter bar */
        .gw-filter-bar {
          display: flex;
          align-items: center;
          gap: 10px;
        }
        .gw-filter-item {
          display: flex;
          align-items: center;
          gap: 6px;
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 6px;
          padding: 4px 10px;
        }
        .gw-filter-item label, .gw-filter-item .control-label {
          margin: 0 !important;
          font-size: 0.75rem !important;
          font-weight: 600 !important;
          color: #64748b !important;
          text-transform: uppercase !important;
          letter-spacing: 0.04em !important;
        }
        .gw-filter-item select {
          border: none !important;
          background: transparent !important;
          font-size: 0.84rem !important;
          color: #0f172a !important;
          font-weight: 600 !important;
          outline: none !important;
          cursor: pointer !important;
          padding: 2px 4px !important;
        }

        /* Scope Bar */
        .gw-scope-bar {
          padding: 12px 28px 0 28px;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .gw-scope-badge {
          display: inline-flex; align-items: center; gap: 4px;
          background: #f1f5f9; color: #334155;
          font-size: 0.75rem; font-weight: 600;
          padding: 3px 9px; border-radius: 4px;
          border: 1px solid #e2e8f0;
        }

        /* Canvas body */
        .gw-body {
          padding: 24px 28px 48px 28px;
          flex: 1;
        }

        /* ── CARDS & METRICS ─────────────────────────────────────────────── */
        .gw-card {
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 20px 22px;
          margin-bottom: 20px;
          box-shadow: 0 1px 2px rgba(0,0,0,0.03);
        }
        .gw-card-title {
          font-size: 0.9375rem;
          font-weight: 700;
          color: #0f172a;
          margin: 0 0 4px 0;
          display: flex; align-items: center; gap: 8px;
        }
        .gw-card-sub {
          font-size: 0.8125rem;
          color: #64748b;
          margin: 0 0 16px 0;
        }

        /* KPI grid */
        .gw-kpi-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 16px;
          margin-bottom: 20px;
        }
        .gw-kpi-card {
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
        .gw-kpi-card.tot { border-left-color: #1e40af; }
        .gw-kpi-card.pos { border-left-color: #059669; }
        .gw-kpi-card.neg { border-left-color: #dc2626; }
        .gw-kpi-card.neu { border-left-color: #d97706; }

        .gw-kpi-label {
          font-size: 0.6875rem;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.06em;
          color: #64748b;
        }
        .gw-kpi-value {
          font-size: 1.875rem;
          font-weight: 700;
          color: #0f172a;
          line-height: 1.1;
        }
        .gw-kpi-sub { font-size: 0.75rem; color: #64748b; }

        /* Progress bars */
        .gw-progress {
          width: 100%; height: 5px;
          background: #f1f5f9;
          border-radius: 9999px;
          overflow: hidden;
          margin-top: 4px;
        }
        .gw-progress-bar { height: 100%; border-radius: 9999px; }

        /* Highlight cards */
        .gw-highlight-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
          margin-bottom: 20px;
        }
        .gw-highlight-card {
          border-radius: 8px;
          padding: 16px 18px;
          border: 1px solid #e2e8f0;
          background: #ffffff;
        }
        .gw-highlight-card.top { border-left: 3px solid #059669; }
        .gw-highlight-card.bottom { border-left: 3px solid #dc2626; }

        /* Dept ranking rows */
        .gw-dept-row {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 9px 12px;
          border-radius: 6px;
          margin-bottom: 6px;
          border: 1px solid #f1f5f9;
        }
        .gw-dept-row:hover { background: #f8fafc; border-color: #e2e8f0; }
        .gw-dept-rank {
          width: 24px; height: 24px; border-radius: 4px;
          display: flex; align-items: center; justify-content: center;
          font-size: 0.75rem; font-weight: 700; flex-shrink: 0;
        }
        .gw-dept-rank.gold { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; }
        .gw-dept-rank.bottom { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
        .gw-dept-rank.other { background: #f1f5f9; color: #64748b; }

        /* Department Areas to Improve */
        .gw-improve-list {
          display: flex;
          flex-direction: column;
          gap: 10px;
          width: 100%;
        }
        .gw-improve-card {
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 12px 16px;
          background: #ffffff;
          width: 100%;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 16px;
        }
        .gw-improve-dept-info {
          min-width: 170px;
          flex-shrink: 0;
        }
        .gw-improve-dept-name {
          font-weight: 700;
          font-size: 0.9rem;
          color: #0f172a;
          margin: 0;
        }
        .gw-improve-dept-meta {
          font-size: 0.75rem;
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
          padding: 3px 8px; border-radius: 4px; font-size: 0.75rem; font-weight: 600;
          white-space: nowrap;
        }
        .gw-tag.critical { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
        .gw-tag.moderate { background: #fffbeb; color: #92400e; border: 1px solid #fde68a; }
        .gw-tag.good { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; }

        /* AI section */
        .gw-ai-box {
          background: #f8fafc;
          border: 1px solid #e2e8f0;
          border-radius: 6px;
          padding: 12px 14px;
          margin-bottom: 10px;
        }
        .gw-ai-title {
          font-size: 0.6875rem; font-weight: 700; text-transform: uppercase;
          letter-spacing: 0.08em; color: #64748b; margin-bottom: 6px;
        }
        .gw-action-item {
          display: flex; align-items: flex-start; gap: 8px;
          padding: 6px 0; font-size: 0.8125rem; color: #334155;
          border-bottom: 1px solid #f1f5f9;
        }
        .gw-action-item:last-child { border-bottom: none; }
        .gw-action-num {
          width: 18px; height: 18px; background: #1e40af; color: #fff;
          border-radius: 50%; font-size: 0.65rem; font-weight: 700;
          display: flex; align-items: center; justify-content: center; flex-shrink: 0;
        }

        /* Settings form styling */
        .gw-settings-group {
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 18px 20px;
          margin-bottom: 16px;
        }
        .gw-settings-title {
          font-weight: 700; font-size: 0.9rem; color: #0f172a; margin-bottom: 2px;
        }
        .gw-settings-desc {
          font-size: 0.78rem; color: #64748b; margin-bottom: 12px;
        }

        /* Explorer Pill Filters */
        .gw-pill-btn {
          background: #f1f5f9;
          border: 1px solid #e2e8f0;
          border-radius: 4px;
          padding: 4px 10px;
          font-size: 0.75rem;
          font-weight: 600;
          color: #475569;
          cursor: pointer;
          margin-left: 4px;
        }
        .gw-pill-btn.active {
          background: #1e40af;
          color: #ffffff;
          border-color: #1e40af;
        }

        /* Responsive */
        @media (max-width: 900px) {
          .gw-sidebar { width: 64px; }
          .gw-brand-name, .gw-brand-sub, .gw-nav-btn span, .gw-nav-section-title, .gw-user-info { display: none; }
          .gw-main { margin-left: 64px; }
          .gw-kpi-grid { grid-template-columns: repeat(2, 1fr); }
          .gw-highlight-grid { grid-template-columns: 1fr; }
          .gw-body { padding: 16px; }
        }
      "))
    ),

    div(class = "gw-app",

      # ── LEFT SIDEBAR ────────────────────────────────────────────────────────
      div(class = "gw-sidebar",

        # Brand header
        div(class = "gw-sidebar-brand",
          div(class = "gw-brand-icon",
            tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24", width="20", height="20",
              fill="none", stroke="#fff", strokeWidth="2", strokeLinecap="round", strokeLinejoin="round",
              tags$path(d="M22 10v6M2 10l10-5 10 5-10 5z"),
              tags$path(d="M6 12.5V16a6 3 0 0 0 12 0v-3.5")
            )
          ),
          div(
            div(class = "gw-brand-name", "Campus Listen"),
            div(class = "gw-brand-sub", "Executive Analytics")
          )
        ),

        # Navigation links
        div(class = "gw-nav",
          div(class = "gw-nav-section-title", "EXECUTIVE MENU"),
          uiOutput(ns("sidebar_nav_buttons"))
        ),

        # Sidebar footer user info
        div(class = "gw-sidebar-user",
          div(class = "gw-user-info",
            span(class = "gw-user-name", "Principal Administrator"),
            span(class = "gw-user-role", "System Governance")
          ),
          actionButton(ns("btn_logout"), label = NULL,
            icon = icon("sign-out-alt"),
            style = "background:transparent;border:none;color:#64748b;font-size:1rem;cursor:pointer;",
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
            # Semester Filter
            div(class = "gw-filter-item",
              selectInput(ns("admin_semester_filter"), label = "Semester", choices = c("All Semesters" = "all"), width = "140px")
            ),
            # Department Filter
            div(class = "gw-filter-item",
              selectInput(ns("admin_dept_filter"), label = "Department", choices = c("All Departments" = "all"), width = "165px")
            ),
            # PDF export
            downloadButton(ns("export_pdf"),
              label = HTML("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='13' height='13' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' style='vertical-align:middle;margin-right:4px;'><polyline points='6 9 6 2 18 2 18 9'/><path d='M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2'/><rect x='6' y='14' width='12' height='8'/></svg>Export Brief"),
              style = "background:#1e40af;color:#fff;border:none;border-radius:6px;font-weight:600;font-size:0.8rem;padding:6px 12px;height:34px;display:inline-flex;align-items:center;"
            )
          )
        ),

        # Scope bar
        div(class = "gw-scope-bar",
          span(style = "font-size:0.75rem; color:#64748b;", "Active Scope:"),
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
    dataset_refresh <- reactiveVal(0)
    observeEvent(input$nav_click, { active_tab(input$nav_click) })

    # ── SIDEBAR NAV BUTTONS ───────────────────────────────────────────────────
    output$sidebar_nav_buttons <- renderUI({
      cur <- active_tab()
      tabs <- list(
        list(id = "overview",  label = "Overview",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect width='7' height='9' x='3' y='3' rx='1'/><rect width='7' height='5' x='14' y='3' rx='1'/><rect width='7' height='9' x='14' y='12' rx='1'/><rect width='7' height='5' x='3' y='16' rx='1'/></svg>"),
        list(id = "analytics", label = "Analytics & Trends",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='22 7 13.5 15.5 8.5 10.5 2 17'/><polyline points='16 7 22 7 22 13'/></svg>"),
        list(id = "explorer",  label = "Feedback Explorer",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='11' cy='11' r='8'/><line x1='21' y1='21' x2='16.65' y2='16.65'/></svg>"),
        list(id = "dataset",   label = "Submissions Dataset",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><ellipse cx='12' cy='5' rx='9' ry='3'/><path d='M21 12c0 1.66-4 3-9 3s-9-1.34-9-3'/><path d='M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5'/></svg>"),
        list(id = "settings",  label = "Governance & Notices",
             svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='16' height='16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z'/><circle cx='12' cy='12' r='3'/></svg>")
      )
      lapply(tabs, function(t) {
        cls <- if (cur == t$id) "gw-nav-btn active" else "gw-nav-btn"
        tags$button(class = cls,
          onclick = sprintf("Shiny.setInputValue('%s','%s',{priority:'event'})", session$ns("nav_click"), t$id),
          HTML(t$svg),
          span(t$label)
        )
      })
    })

    # ── HEADER TITLE UI ───────────────────────────────────────────────────────
    output$header_title_ui <- renderUI({
      t <- active_tab()
      title_txt <- switch(t,
        overview  = "Executive Dashboard Overview",
        analytics = "Institutional Analytics & Sentiment Trends",
        explorer  = "Feedback Explorer",
        dataset   = "Submissions Dataset & Sentiment Records",
        settings  = "Governance & Institutional Notice Center"
      )
      sub_txt <- switch(t,
        overview  = "College-wide feedback metrics across departments and academic cycles",
        analytics = "Longitudinal sentiment time-series and faculty trajectory analytics",
        explorer  = "Search and inspect individual student feedback entries",
        dataset   = "Live raw feedback dataset, sentiment scores, and historical record explorer",
        settings  = "Broadcast evaluation notices, set deadlines, and configure governance parameters"
      )
      tagList(
        h1(class = "gw-header-title", title_txt),
        p(class = "gw-header-sub", sub_txt)
      )
    })

    # ── RAW & FILTERED DATA ───────────────────────────────────────────────────
    raw_df <- reactive({
      dataset_refresh()
      get_all_feedback()
    })

    avail_semesters <- reactive({
      df <- raw_df()
      sems <- unique(df$semester[!is.na(df$semester) & df$semester != ""])
      c(SEMESTER_ORDER[SEMESTER_ORDER %in% sems], setdiff(sems, SEMESTER_ORDER))
    })

    avail_depts <- reactive({
      df <- raw_df()
      sort(unique(df$teacher_dept[!is.na(df$teacher_dept) & df$teacher_dept != ""]))
    })

    # Populate dropdown choices
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
        span(class = "gw-scope-badge", style = "background:#eff6ff;color:#1e40af;border-color:#bfdbfe;",
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
        dataset   = render_dataset_tab(),
        settings  = render_settings_tab()
      )
    })

    # ── 1. OVERVIEW TAB VIEW ──────────────────────────────────────────────────
    render_overview_tab <- function() {
      kv <- kpi_vals()
      tagList(
        # Active Notice Card Banner
        uiOutput(ns("admin_notice_strip_ui")),

        # KPI Grid
        div(class = "gw-kpi-grid",
          div(class = "gw-kpi-card tot",
            span(class = "gw-kpi-label", "Total Responses"),
            div(class = "gw-kpi-value", formatC(kv$n, format = "d", big.mark = ",")),
            span(class = "gw-kpi-sub", "collected student entries")
          ),
          div(class = "gw-kpi-card pos",
            span(class = "gw-kpi-label", "Positive"),
            div(class = "gw-kpi-value", style = "color:#059669;", sprintf("%d%%", kv$pos_pct)),
            div(class = "gw-progress", div(class = "gw-progress-bar", style = sprintf("width:%d%%;background:#059669;", kv$pos_pct))),
            span(class = "gw-kpi-sub", sprintf("%d responses", kv$pos))
          ),
          div(class = "gw-kpi-card neg",
            span(class = "gw-kpi-label", "Negative"),
            div(class = "gw-kpi-value", style = "color:#dc2626;", sprintf("%d%%", kv$neg_pct)),
            div(class = "gw-progress", div(class = "gw-progress-bar", style = sprintf("width:%d%%;background:#dc2626;", kv$neg_pct))),
            span(class = "gw-kpi-sub", sprintf("%d responses", kv$neg))
          ),
          div(class = "gw-kpi-card neu",
            span(class = "gw-kpi-label", "Neutral"),
            div(class = "gw-kpi-value", style = "color:#d97706;", sprintf("%d%%", kv$neu_pct)),
            div(class = "gw-progress", div(class = "gw-progress-bar", style = sprintf("width:%d%%;background:#d97706;", kv$neu_pct))),
            span(class = "gw-kpi-sub", sprintf("%d responses", kv$neu))
          )
        ),

        # Timely Feedback Responses & Date Timeline Card
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;",
            p(class = "gw-card-title", style = "margin:0;", "Academic Cycle Submission Volume & Sentiment"),
            span(style = "font-size:0.75rem; color:#1e40af; font-weight:600; background:#eff6ff; padding:3px 8px; border-radius:4px; border:1px solid #bfdbfe;", "Chronological Timeline")
          ),
          p(class = "gw-card-sub", "Submission volume and sentiment distribution across semesters and feedback cycles"),
          plotlyOutput(ns("chart_overview_timeline"), height = "280px")
        ),

        # Highlight Top vs Bottom
        div(class = "gw-highlight-grid",
          uiOutput(ns("highlight_top_ui")),
          uiOutput(ns("highlight_bottom_ui"))
        ),

        # FULL WIDTH HORIZONTAL AREAS TO IMPROVE
        div(class = "gw-card",
          p(class = "gw-card-title", "Department Areas Requiring Attention"),
          p(class = "gw-card-sub", "Status breakdown across lab facilities, examinations, teaching, and library resources"),
          div(class = "gw-improve-list",
            uiOutput(ns("improve_areas_ui"))
          )
        ),

        # AI Insights
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;",
            p(class = "gw-card-title", style = "margin:0;", "Qualitative Insights & Recommended Actions"),
            actionButton(ns("btn_refresh_ai"), "Refresh Analysis",
              style = "background:#1e40af; color:#fff; border:none; border-radius:4px; font-size:0.75rem; font-weight:600; padding:5px 12px;")
          ),
          p(class = "gw-card-sub", "Automated feedback text analysis and key institutional action items"),
          uiOutput(ns("ai_insights_ui"))
        ),

        # Department Submission Readiness Tracker
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;",
            p(class = "gw-card-title", style = "margin:0;", "Department Feedback Submission Readiness Tracker"),
            span(style = "font-size:0.75rem; color:#1e40af; font-weight:600; background:#eff6ff; padding:3px 8px; border-radius:4px; border:1px solid #bfdbfe;", "College-Wide Quota Tracking")
          ),
          p(class = "gw-card-sub", "Monitor which engineering departments have met evaluation readiness vs pending submissions"),
          DT::dataTableOutput(ns("dept_readiness_table"))
        ),

        # Most Positive & Most Negative Cards
        div(style = "display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-bottom:20px;",
          div(class = "gw-card", style = "margin-bottom:0;",
            p(class = "gw-card-title", style = "color:#059669;", "Most Positive Student Responses"),
            p(class = "gw-card-sub", "Representative high-scoring written feedback"),
            uiOutput(ns("most_positive_ui"))
          ),
          div(class = "gw-card", style = "margin-bottom:0;",
            p(class = "gw-card-title", style = "color:#dc2626;", "Critical Concerns Raised"),
            p(class = "gw-card-sub", "Feedback highlighting immediate operational priorities"),
            uiOutput(ns("most_negative_ui"))
          )
        )
      )
    }

    # ── 2. ANALYTICS TAB VIEW ─────────────────────────────────────────────────
    render_analytics_tab <- function() {
      tagList(
        # Top Row: Sentiment Share & Monthly Volume
        div(style = "display:grid; grid-template-columns: 1fr 1.6fr; gap:16px; margin-bottom:20px;",
          div(class = "gw-card", style = "margin-bottom:0;",
            p(class = "gw-card-title", "Sentiment Share"),
            p(class = "gw-card-sub", "Overall distribution across submissions"),
            plotlyOutput(ns("chart_pie"), height = "280px")
          ),
          div(class = "gw-card", style = "margin-bottom:0;",
            p(class = "gw-card-title", "Sentiment Over Time"),
            p(class = "gw-card-sub", "Monthly chronological volume and polarity trend"),
            plotlyOutput(ns("chart_time"), height = "280px")
          )
        ),

        # MULTI-YEAR DEPARTMENT TRENDS ACROSS SEMESTERS
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px; margin-bottom:12px;",
            div(
              p(class = "gw-card-title", style = "margin:0;", "Multi-Year Department Trends Across Semesters"),
              p(class = "gw-card-sub", style = "margin:2px 0 0 0;", "Comparing feedback positivity and ratings across academic semesters (Sem 1 to Sem 8)")
            ),
            div(style = "display:flex; gap:8px; align-items:center;",
              selectInput(ns("analytics_cycle_filter"), label = NULL,
                choices = c(
                  "All Semesters (Sem 1-8)" = "all",
                  "July–Nov (Odd Sems 1,3,5,7)" = "odd",
                  "Dec–April (Even Sems 2,4,6,8)" = "even"
                ), width = "210px"),
              selectInput(ns("analytics_metric_type"), label = NULL,
                choices = c("Positive Sentiment %" = "pos_pct", "Average Rating (1-5)" = "avg_rating"),
                width = "180px")
            )
          ),
          plotlyOutput(ns("chart_dept_multi_semester"), height = "360px")
        ),

        # FACULTY IMPROVEMENT TRACKER
        div(class = "gw-card",
          p(class = "gw-card-title", "Faculty Performance Trajectory"),
          p(class = "gw-card-sub", "Tracking individual faculty rating evolution across consecutive semesters"),
          div(style = "display:grid; grid-template-columns: 1fr 1.2fr; gap:20px;",
            div(
              p(style = "font-weight:600; font-size:0.84rem; color:#0f172a; margin-bottom:8px;", "Faculty Progress Summary"),
              uiOutput(ns("teacher_improvement_leaderboard_ui"))
            ),
            div(
              div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; margin-bottom:8px;",
                p(style = "font-weight:600; font-size:0.84rem; color:#0f172a; margin:0;", "Individual Trajectory Inspector"),
                div(style = "display:flex; gap:6px; align-items:center;",
                  selectInput(ns("inspector_dept_filter"), label = NULL, choices = c("All Departments" = "all"), width = "150px"),
                  selectInput(ns("teacher_select_inspector"), label = NULL, choices = c("Select Faculty" = ""), width = "170px")
                )
              ),
              uiOutput(ns("teacher_inspector_badge_ui")),
              plotlyOutput(ns("chart_teacher_trajectory"), height = "260px")
            )
          )
        ),

        # SUBJECT & ASPECT SATISFACTION TRAJECTORY
        div(class = "gw-card",
          p(class = "gw-card-title", "Feedback Dimension Improvement Trajectory"),
          p(class = "gw-card-sub", "Satisfaction trends across Teaching, Labs, Exams, Content, Library and Extracurriculars"),
          div(style = "display:grid; grid-template-columns: 1.4fr 1fr; gap:20px;",
            plotlyOutput(ns("chart_subject_trends"), height = "340px"),
            div(
              p(style = "font-weight:600; font-size:0.84rem; color:#0f172a; margin-bottom:8px;", "Dimension Delta Summary"),
              uiOutput(ns("subject_delta_summary_ui"))
            )
          )
        ),

        # Department Ranking Breakdown
        div(class = "gw-card",
          p(class = "gw-card-title", "Department Performance Breakdown"),
          p(class = "gw-card-sub", "Overall sentiment distribution and positivity rate by academic department"),
          div(style = "display:grid; grid-template-columns: 1.2fr 1fr; gap:20px;",
            uiOutput(ns("dept_rankings_list_ui")),
            plotlyOutput(ns("chart_dept_bar"), height = "340px")
          )
        ),

        # Faculty 4-Subject Allocation Registry
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;",
            p(class = "gw-card-title", style = "margin:0;", "Faculty 4-Subject Allocation & Performance Registry"),
            span(style = "font-size:0.75rem; color:#1e40af; font-weight:600; background:#eff6ff; padding:3px 8px; border-radius:4px; border:1px solid #bfdbfe;", "Institutional 4-Subject Allocation Rule")
          ),
          p(class = "gw-card-sub", "Verified academic subject allocations (4 subjects assigned per faculty instructor) and evaluation metrics"),
          DT::dataTableOutput(ns("faculty_allocations_table"))
        )
      )
    }

    # ── 3. EXPLORER TAB VIEW ──────────────────────────────────────────────────
    render_explorer_tab <- function() {
      tagList(
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;",
            p(class = "gw-card-title", style = "margin:0;", "Search Student Reviews"),
            uiOutput(ns("explorer_pill_filters_ui"))
          ),
          textInput(ns("exp_search"), label = NULL, placeholder = "Search department, faculty member, aspect or keyword...", width = "100%"),
          fluidRow(
            column(5,
              div(style = "max-height:480px; overflow-y:auto; border:1px solid #e2e8f0; border-radius:6px; background:#fff;",
                uiOutput(ns("explorer_items_list_ui"))
              )
            ),
            column(7,
              div(class = "gw-card", style = "background:#fafbfc; min-height:480px; margin-bottom:0;",
                uiOutput(ns("explorer_item_detail_ui"))
              )
            )
          )
        )
      )
    }

    # ── 4. SUBMISSIONS DATASET TAB VIEW [NEW] ─────────────────────────────────
    raw_dataset_df <- reactive({
      dataset_refresh()
      get_all_feedback_dataset()
    })

    render_dataset_tab <- function() {
      df <- raw_dataset_df()
      n_total <- nrow(df)
      n_pos <- sum(df$rating == 1, na.rm = TRUE)
      n_neu <- sum(df$rating == 0, na.rm = TRUE)
      n_neg <- sum(df$rating == -1, na.rm = TRUE)
      avg_sent <- if (n_total > 0) mean(df$sentiment_score, na.rm = TRUE) else 0.0

      tagList(
        # Dataset Summary Metrics Bar
        div(class = "gw-kpi-grid",
          div(class = "gw-kpi-card tot",
            span(class = "gw-kpi-label", "Dataset Record Count"),
            div(class = "gw-kpi-value", formatC(n_total, format = "d", big.mark = ",")),
            span(class = "gw-kpi-sub", "complete submission records")
          ),
          div(class = "gw-kpi-card pos",
            span(class = "gw-kpi-label", "Avg Sentiment Polarity"),
            div(class = "gw-kpi-value", style = "color:#1e40af;", sprintf("%+.2f", avg_sent)),
            span(class = "gw-kpi-sub", "range: -1.00 to +1.00")
          ),
          div(class = "gw-kpi-card pos",
            span(class = "gw-kpi-label", "Positive Evaluations"),
            div(class = "gw-kpi-value", style = "color:#059669;", formatC(n_pos, format = "d", big.mark = ",")),
            span(class = "gw-kpi-sub", sprintf("%.1f%% of raw records", if(n_total>0) n_pos/n_total*100 else 0))
          ),
          div(class = "gw-kpi-card neg",
            span(class = "gw-kpi-label", "Needs Attention / Critical"),
            div(class = "gw-kpi-value", style = "color:#dc2626;", formatC(n_neg, format = "d", big.mark = ",")),
            span(class = "gw-kpi-sub", sprintf("%.1f%% of raw records", if(n_total>0) n_neg/n_total*100 else 0))
          )
        ),

        # Live Dataset Table Card
        div(class = "gw-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:14px; flex-wrap:wrap; gap:10px;",
            div(
              p(class = "gw-card-title", style = "margin:0;", "All Recorded Student Feedback & Sentiment Records"),
              p(class = "gw-card-sub", style = "margin:2px 0 0 0;", "Instant live database reflection of all completed evaluations with full metadata and sentiment scores")
            ),
            div(style = "display:flex; gap:8px;",
              downloadButton(ns("export_raw_csv"), "Download CSV",
                class = "btn btn-outline-secondary btn-sm", style = "font-weight:600; font-size:12px;"),
              actionButton(ns("btn_refresh_dataset"), "Refresh Live Table",
                class = "btn btn-primary btn-sm", style = "font-weight:600; font-size:12px;")
            )
          ),
          DT::dataTableOutput(ns("raw_submissions_table"))
        ),

        # Previous Sentiment Analysis Breakdown
        div(class = "gw-card",
          p(class = "gw-card-title", "Historical Sentiment Analysis & Previous Submissions Breakdown"),
          p(class = "gw-card-sub", "Distribution of computed sentiment polarity and evaluation scores across all cycles"),
          plotlyOutput(ns("chart_dataset_sentiment_dist"), height = "300px")
        )
      )
    }

    # ── 5. SETTINGS & GOVERNANCE TAB VIEW ────────────────────────────────────
    active_window_data <- reactive({
      dataset_refresh()
      get_active_feedback_window()
    })

    render_settings_tab <- function() {
      win <- active_window_data()
      tagList(
        # Broadcast Institutional Notice & Deadline Manager Card
        div(class = "gw-settings-group", style = "border-left:4px solid #1e40af;",
          div(class = "gw-settings-title", style = "font-size:1rem; color:#1e40af;",
            "Institutional Feedback Notice & Submission Deadline Broadcast"),
          div(class = "gw-settings-desc",
            "Set the official evaluation term name, deadline date, and announcement text. When published, this notification will be broadcast prominently to all student and faculty portals."),
          
          fluidRow(
            column(6,
              textInput(ns("admin_notice_term"), "Evaluation Term / Academic Cycle",
                value = win$term_name, width = "100%")
            ),
            column(6,
              dateInput(ns("admin_notice_deadline"), "Submission Deadline Date",
                value = as.Date(win$deadline_date), min = Sys.Date(), width = "100%")
            )
          ),
          textAreaInput(ns("admin_notice_desc"), "Official Notice Circular / Broadcast Instructions",
            value = win$description, rows = 3, width = "100%"),
          
          div(style = "margin-top:8px;",
            actionButton(ns("btn_broadcast_notice"), "Broadcast Notice & Deadline to All Portals",
              class = "btn btn-primary",
              style = "font-weight:600; font-size:13px; padding:8px 20px;"),
            uiOutput(ns("broadcast_notice_msg"))
          )
        ),

        div(class = "gw-settings-group",
          div(class = "gw-settings-title", "Negative Alert Threshold"),
          div(class = "gw-settings-desc", "Trigger warning badges when an aspect's negative feedback exceeds this percentage."),
          sliderInput(ns("set_threshold"), label = NULL, min = 10, max = 50, value = 20, post = "%", width = "350px")
        ),
        div(class = "gw-settings-group",
          div(class = "gw-settings-title", "Automated Insights Configuration"),
          div(class = "gw-settings-desc", "Enable background NLP text processing and automatic summary generation."),
          checkboxInput(ns("set_auto_ai"), label = "Auto-generate qualitative insights on filter update", value = TRUE),
          checkboxInput(ns("set_extract_keywords"), label = "Extract positive and complaint keyword themes", value = TRUE)
        ),
        div(class = "gw-settings-group",
          div(class = "gw-settings-title", "Administrator Notification Preferences"),
          div(class = "gw-settings-desc", "Receive automated summaries and critical alert digests."),
          checkboxInput(ns("set_email_digest"), label = "Send weekly sentiment summary digest email", value = TRUE),
          checkboxInput(ns("set_critical_alert"), label = "Send instant notification on critical aspect alerts (>30% negative)", value = TRUE)
        ),
        div(class = "gw-settings-group",
          actionButton(ns("btn_save_settings"), "Save General Settings",
            style = "background:#1e40af; color:#fff; font-weight:600; border:none; padding:8px 20px; border-radius:6px; cursor:pointer;"),
          uiOutput(ns("settings_saved_msg"))
        )
      )
    }

    # Broadcast notice handler
    observeEvent(input$btn_broadcast_notice, {
      req(input$admin_notice_term, input$admin_notice_deadline)
      t_name <- trimws(input$admin_notice_term)
      d_date <- as.character(input$admin_notice_deadline)
      desc   <- trimws(input$admin_notice_desc %||% "")
      
      update_feedback_window(t_name, d_date, desc)
      dataset_refresh(dataset_refresh() + 1)

      output$broadcast_notice_msg <- renderUI({
        div(style = "margin-top:10px; color:#059669; font-weight:700; font-size:0.875rem;",
          sprintf("✓ Notice and deadline (%s) broadcast successfully to all student and faculty portals!", d_date))
      })
      showNotification("Evaluation notice & deadline broadcasted successfully.", type = "message", duration = 4)
    })

    # Top notice strip in overview
    output$admin_notice_strip_ui <- renderUI({
      win <- active_window_data()
      div(style = "background:#ffffff; border:1px solid #e2e8f0; border-left:4px solid #1e40af; border-radius:8px; padding:12px 18px; margin-bottom:16px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;",
        div(
          strong(style = "color:#0f172a; font-size:0.88rem;", sprintf("Active Evaluation Window: %s", win$term_name)),
          span(style = "color:#64748b; font-size:0.8rem; margin-left:8px;", sprintf("Deadline: %s (%d days remaining)", format(as.Date(win$deadline_date), "%b %d, %Y"), win$days_left))
        ),
        actionButton(ns("btn_goto_settings_notice"), "Manage Notice & Deadline",
          class = "btn btn-outline-secondary btn-sm", style = "font-size:12px; padding:3px 10px;")
      )
    })

    observeEvent(input$btn_goto_settings_notice, {
      active_tab("settings")
    })

    observeEvent(input$btn_save_settings, {
      output$settings_saved_msg <- renderUI({
        div(style = "margin-top:10px; color:#1e40af; font-weight:600; font-size:0.84rem;",
          "Settings saved successfully.")
      })
    })

    # ── RAW SUBMISSIONS DATASET TABLE ─────────────────────────────────────────
    observeEvent(input$btn_refresh_dataset, {
      dataset_refresh(dataset_refresh() + 1)
    })

    output$raw_submissions_table <- DT::renderDataTable({
      df <- raw_dataset_df()
      if (nrow(df) == 0) return(data.frame(Message = "No submissions recorded yet."))

      df$formatted_date <- format(as.POSIXct(df$timestamp), "%b %d, %Y %H:%M")
      df$Dimension_Title <- tools::toTitleCase(gsub("_", " ", df$dimension))
      df$Score_Formatted <- sprintf("%+.2f", df$sentiment_score)

      out <- df[, c("submission_id", "formatted_date", "student_identity", "department", "semester", "course_code", "course_title", "faculty_instructor", "Dimension_Title", "rating_label", "Score_Formatted", "raw_comment")]
      names(out) <- c("ID", "Date", "Student", "Department", "Semester", "Course", "Subject", "Instructor", "Dimension", "Rating", "Score", "Feedback Comments")

      DT::datatable(
        out,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          order = list(list(0, 'desc'))
        ),
        rownames = FALSE
      )
    })

    # CSV Download Handler
    output$export_raw_csv <- downloadHandler(
      filename = function() {
        paste0("Campus_Listen_Raw_Submissions_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        df <- raw_dataset_df()
        write.csv(df, file, row.names = FALSE)
      }
    )

    # Historical Sentiment Distribution Chart
    output$chart_dataset_sentiment_dist <- renderPlotly({
      df <- raw_dataset_df()
      if (nrow(df) == 0) return(plot_ly())

      agg <- aggregate(submission_id ~ semester + rating_label, data = df, FUN = length)
      names(agg)[3] <- "count"

      plot_ly(agg, x = ~semester, y = ~count, color = ~rating_label,
              colors = c("Negative (1-2)" = "#dc2626", "Neutral (3)" = "#d97706", "Positive (4-5)" = "#059669"),
              type = "bar") %>%
        layout(
          barmode = "group",
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(title = "Semester Batch", color = "#64748b", categoryorder = "array", categoryarray = SEMESTER_ORDER),
          yaxis = list(title = "Submission Count", color = "#64748b", gridcolor = "rgba(0,0,0,0.05)"),
          margin = list(l = 40, r = 10, t = 10, b = 40),
          legend = list(orientation = "h", x = 0.1, y = 1.15, font = list(color = "#475569"))
        )
    })

    # ── OVERVIEW: HIGHLIGHT CARDS ─────────────────────────────────────────────
    output$highlight_top_ui <- renderUI({
      ds <- dept_summary()
      if (is.null(ds) || nrow(ds) == 0) return(NULL)
      td <- ds[1, ]
      
      df <- filtered_df()
      top_fac <- df[!is.na(df$teacher_dept) & df$teacher_dept == td$department & !is.na(df$teacher_name), ]
      teacher_name_val <- if (nrow(top_fac) > 0) top_fac$teacher_name[1] else NULL

      div(class = "gw-highlight-card top",
        div(style = "display:flex; justify-content:space-between; align-items:center;",
          span(style = "font-size:0.75rem; font-weight:700; color:#059669; text-transform:uppercase;", "Top Performing Department"),
          span(style = "background:#ecfdf5; color:#065f46; font-size:0.72rem; font-weight:600; padding:2px 8px; border-radius:4px; border:1px solid #a7f3d0;", "Leading")
        ),
        h3(style = "margin:6px 0 4px; color:#0f172a; font-weight:700; font-size:1.1rem;", td$department),
        div(style = "margin-bottom:8px;", format_teacher_badge(teacher_name_val)),
        p(style = "font-size:0.8125rem; color:#64748b; margin:0 0 10px;", sprintf("%d%% positive sentiment across %d responses", td$pos_pct, td$total)),
        div(style = "display:grid; grid-template-columns:repeat(3,1fr); gap:8px; border-top:1px solid #e2e8f0; padding-top:8px; font-size:0.8rem;",
          div(span(style="color:#64748b;display:block;font-size:0.7rem;","Avg Rating"), span(style="font-weight:700;", sprintf("%.2f", td$avg_rating))),
          div(span(style="color:#64748b;display:block;font-size:0.7rem;","Positive"), span(style="font-weight:700;color:#059669;", td$pos)),
          div(span(style="color:#64748b;display:block;font-size:0.7rem;","Negative"), span(style="font-weight:700;color:#dc2626;", td$neg))
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
          span(style = "font-size:0.75rem; font-weight:700; color:#dc2626; text-transform:uppercase;", "Areas Requiring Attention"),
          span(style = "background:#fef2f2; color:#991b1b; font-size:0.72rem; font-weight:600; padding:2px 8px; border-radius:4px; border:1px solid #fecaca;", "Lowest Positivity")
        ),
        h3(style = "margin:6px 0 4px; color:#0f172a; font-weight:700; font-size:1.1rem;", bd$department),
        div(style = "margin-bottom:8px;", format_teacher_badge(teacher_name_val)),
        p(style = "font-size:0.8125rem; color:#64748b; margin:0 0 10px;", sprintf("%d%% negative sentiment across %d responses", bd$neg_pct, bd$total)),
        div(style = "background:#fef2f2; border:1px solid #fecaca; border-radius:4px; padding:6px 10px; font-size:0.78rem; color:#991b1b;",
          span(style = "font-weight:700; display:block; font-size:0.68rem; text-transform:uppercase;", "Primary Issue:"),
          primary_issue(bd$department)
        )
      )
    })

    # ── OVERVIEW: AREAS TO IMPROVE (HORIZONTAL LIST) ──────────────────────────
    output$improve_areas_ui <- renderUI({
      df <- filtered_df()
      ds <- dept_summary()
      if (is.null(ds) || nrow(df) == 0) return(p("No data available."))

      thresh <- if (!is.null(input$set_threshold)) input$set_threshold else 20

      cards <- lapply(ds$department, function(dept) {
        sub <- df[!is.na(df$teacher_dept) & df$teacher_dept == dept, ]
        if (nrow(sub) == 0) return(NULL)

        dp_row <- ds[ds$department == dept, ]
        pos_pct_lbl <- if (nrow(dp_row) > 0) sprintf("%d%% positive", dp_row$pos_pct[1]) else ""
        total_lbl <- sprintf("%d responses", nrow(sub))

        tags_html <- lapply(names(ASPECT_LABELS), function(asp) {
          asp_sub <- sub[!is.na(sub$aspect) & sub$aspect == asp, ]
          n <- nrow(asp_sub)
          if (n < 3) return(NULL)
          neg_pct <- round(sum(asp_sub$rating == -1, na.rm = TRUE) / n * 100)

          if (neg_pct >= (thresh + 10)) {
            span(class = "gw-tag critical", sprintf("%s %d%% neg", ASPECT_LABELS[asp], neg_pct))
          } else if (neg_pct >= thresh) {
            span(class = "gw-tag moderate", sprintf("%s %d%% neg", ASPECT_LABELS[asp], neg_pct))
          } else {
            span(class = "gw-tag good", sprintf("%s OK", ASPECT_LABELS[asp]))
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
      if (nrow(df) == 0) return(p("No data available."))

      pos_texts <- df$text[df$rating == 1  & !is.na(df$text) & nchar(df$text) > 8]
      neg_texts <- df$text[df$rating == -1 & !is.na(df$text) & nchar(df$text) > 8]

      pos_words <- tryCatch(get_word_frequencies(pos_texts, top_n = 5)$word, error = function(e) character(0))
      neg_words <- tryCatch(get_word_frequencies(neg_texts, top_n = 5)$word, error = function(e) character(0))

      pos_badges <- if (length(pos_words) > 0) lapply(pos_words, function(w) span(class = "gw-tag good", w)) else list(span("N/A"))
      neg_badges <- if (length(neg_words) > 0) lapply(neg_words, function(w) span(class = "gw-tag critical", w)) else list(span("N/A"))

      actions <- c()
      if (any(c("lab", "equipment", "hardware", "software") %in% neg_words)) {
        actions <- c(actions, "Lab Facilities: Modernize laboratory systems, verify hardware maintenance logs, and ensure equal access.")
      }
      if (any(c("exam", "schedule", "clashes", "grading", "marks") %in% neg_words)) {
        actions <- c(actions, "Examinations: Coordinate assessment schedules to avoid conflicts and maintain transparent grading rubrics.")
      }
      if (any(c("library", "books", "seating", "wifi") %in% neg_words)) {
        actions <- c(actions, "Library & Resources: Expand available academic textbooks and strengthen campus digital repository connectivity.")
      }
      if (any(c("teaching", "professor", "lectures", "slides") %in% neg_words)) {
        actions <- c(actions, "Teaching Quality: Facilitate faculty pedagogical development workshops and structured peer-feedback sessions.")
      }
      if (length(actions) == 0) {
        actions <- c(
          "Conduct curriculum delivery reviews and establish departmental student advisory groups.",
          "Perform quarterly checks on laboratory workstations and teaching infrastructure.",
          "Encourage inter-departmental knowledge sharing of highly rated instructional methods."
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
          div(class = "gw-ai-title", "Executive Summary"),
          p(style = "margin:0; font-size:0.84rem; color:#334155;",
            sprintf("Evaluated %s responses for %s across %s: %d%% positive, %d%% negative.",
                    formatC(nrow(df), format="d", big.mark=","),
                    if (is.null(input$admin_dept_filter) || input$admin_dept_filter == "all") "All Departments" else input$admin_dept_filter,
                    if (is.null(input$admin_semester_filter) || input$admin_semester_filter == "all") "All Semesters" else input$admin_semester_filter,
                    round(sum(df$rating == 1) / nrow(df) * 100),
                    round(sum(df$rating == -1) / nrow(df) * 100)))
        ),
        div(style = "display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-bottom:10px;",
          div(class = "gw-ai-box",
            div(class = "gw-ai-title", "Positive Themes"),
            div(pos_badges)
          ),
          div(class = "gw-ai-box",
            div(class = "gw-ai-title", "Concern Themes"),
            div(neg_badges)
          )
        ),
        div(class = "gw-ai-box",
          div(class = "gw-ai-title", "Recommended Institutional Actions"),
          div(action_lis)
        )
      )
    })

    # ── OVERVIEW: MOST POSITIVE / NEGATIVE ────────────────────────────────────
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

        div(style="border:1px solid #e2e8f0;border-radius:6px;padding:12px;margin-bottom:8px;background:#fff;",
          p(style="margin:0 0 8px;color:#0f172a;font-size:0.84rem;line-height:1.45;", r$text),
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
      tagList(render_feedback_cards(sub, "No positive feedback found in this scope."))
    })

    output$most_negative_ui <- renderUI({
      df <- filtered_df()
      sub <- df[df$rating == -1 & !is.na(df$text) & nchar(df$text) > 5, ]
      tagList(render_feedback_cards(sub, "No negative feedback found in this scope."))
    })

    # ── ANALYTICS: CHARTS ─────────────────────────────────────────────────────
    output$chart_pie <- renderPlotly({
      kv <- kpi_vals()
      if (kv$n == 0) return(plot_ly())
      df <- data.frame(
        Sentiment = c("Positive", "Neutral", "Negative"),
        Count     = c(kv$pos, kv$neu, kv$neg),
        Color     = c("#059669", "#d97706", "#dc2626")
      )
      plot_ly(df, labels = ~Sentiment, values = ~Count, type = "pie", hole = 0.6,
              marker = list(colors = ~Color), textinfo = "percent",
              textfont = list(color = "#ffffff", size = 12)) %>%
        layout(
          annotations = list(list(
            text = sprintf("<b>%s</b><br><span style='color:#64748b;font-size:10px'>responses</span>", formatC(kv$n, format="d", big.mark=",")),
            x=0.5, y=0.5, showarrow=FALSE, font=list(size=14, color="#0f172a")
          )),
          paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
          margin = list(l=10,r=10,t=10,b=10), showlegend = TRUE,
          legend = list(orientation = "h", x = 0.1, y = -0.1, font = list(color="#475569"))
        )
    })

    # ── CRITICAL TIME-SERIES FIX: Sentiment Over Time (Strict Chronological Ordering)
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
        add_trace(y = ~neu, name = "Neutral", line = list(color = "#d97706", width = 2.5), marker = list(color = "#d97706", size = 6)) %>%
        add_trace(y = ~neg, name = "Negative", line = list(color = "#dc2626", width = 2.5), marker = list(color = "#dc2626", size = 6)) %>%
        layout(
          paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
          xaxis = list(
            title = "",
            tickangle = -25,
            color = "#64748b",
            categoryorder = "array",
            categoryarray = months_df$yr_mon,
            gridcolor = "rgba(0,0,0,0.05)"
          ),
          yaxis = list(title = "Responses", color = "#64748b", gridcolor = "rgba(0,0,0,0.05)"),
          margin = list(l=40,r=10,t=10,b=45), showlegend = TRUE,
          legend = list(orientation = "h", x = 0.1, y = 1.15, font = list(color="#475569"))
        )
    })

    output$dept_rankings_list_ui <- renderUI({
      ds <- dept_summary()
      if (is.null(ds)) return(p("No data available."))
      n_depts <- nrow(ds)

      rows <- lapply(seq_len(n_depts), function(i) {
        d <- ds[i, ]
        rank_cls <- if (i == 1) "gold" else if (i == n_depts) "bottom" else "other"
        rank_lbl <- if (i == 1) "1st" else if (i == 2) "2nd" else if (i == 3) "3rd" else if (i == n_depts) "—" else sprintf("%d", i)

        div(class = "gw-dept-row",
          div(class = sprintf("gw-dept-rank %s", rank_cls), rank_lbl),
          div(style = "font-weight:600; font-size:0.84rem; flex:1;", d$department),
          div(style = "width:120px; font-size:0.75rem;",
            div(style = "color:#059669; font-weight:600;", sprintf("%d%% pos", d$pos_pct)),
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
        add_trace(x = ~neu, name = "Neutral", marker = list(color = "#d97706")) %>%
        add_trace(x = ~neg, name = "Negative", marker = list(color = "#dc2626")) %>%
        layout(
          barmode = "stack", paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
          xaxis = list(title = "Responses", color = "#64748b", gridcolor = "rgba(0,0,0,0.05)"),
          yaxis = list(title = "", color = "#64748b"),
          margin = list(l=10,r=10,t=10,b=30),
          legend = list(orientation = "h", x = 0, y = 1.15, font = list(color="#475569"))
        )
    })

    # ── OVERVIEW: TIMELY RESPONSES & DATE TIMELINE ───────────────────────────
    output$chart_overview_timeline <- renderPlotly({
      df <- get_timely_response_timeline()
      if (nrow(df) == 0) return(plot_ly())

      sem_summary <- aggregate(cbind(response_count, positive_count, neutral_count, negative_count) ~ semester, data = df, FUN = sum)
      sem_summary$sem_num <- as.integer(gsub("[^0-9]", "", sem_summary$semester))
      sem_summary <- sem_summary[order(sem_summary$sem_num), ]

      plot_ly(sem_summary, x = ~semester, y = ~positive_count, name = "Positive Feedback", type = "bar", marker = list(color = "#059669")) %>%
        add_trace(y = ~neutral_count, name = "Neutral Feedback", marker = list(color = "#d97706")) %>%
        add_trace(y = ~negative_count, name = "Negative Feedback", marker = list(color = "#dc2626")) %>%
        layout(
          barmode = "stack",
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(
            title = "Academic Semester Cycle",
            color = "#64748b",
            categoryorder = "array",
            categoryarray = sem_summary$semester,
            tickangle = -15,
            gridcolor = "rgba(0,0,0,0.05)"
          ),
          yaxis = list(title = "Total Student Responses", color = "#64748b", gridcolor = "rgba(0,0,0,0.05)"),
          margin = list(l = 40, r = 10, t = 10, b = 40),
          legend = list(orientation = "h", x = 0, y = -0.25, font = list(color="#475569"))
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
      colors <- c("#1e40af", "#059669", "#d97706", "#7c3aed", "#db2777", "#0891b2", "#ea580c", "#475569")

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
          line = list(width = 2.5, color = col),
          marker = list(size = 7, color = col)
        )
      }

      y_title <- if (metric == "avg_rating") "Average Rating (1 to 5)" else "Positive Sentiment %"
      p %>% layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        xaxis = list(
          title = "Academic Semester",
          color = "#64748b",
          categoryorder = "array",
          categoryarray = SEMESTER_ORDER,
          tickangle = -15,
          gridcolor = "rgba(0,0,0,0.05)"
        ),
        yaxis = list(title = y_title, color = "#64748b", gridcolor = "rgba(0,0,0,0.05)"),
        margin = list(l = 40, r = 10, t = 10, b = 40),
        legend = list(orientation = "h", x = 0, y = -0.25, font = list(color="#475569"))
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
        delta_str <- sprintf("%s%.1f%%", if (r$delta >= 0) "+" else "", r$delta)
        badge_cls <- if (r$delta > 5) "gw-tag good" else if (r$delta < -5) "gw-tag critical" else "gw-tag moderate"

        div(style = "padding:9px 12px; border:1px solid #e2e8f0; border-radius:6px; margin-bottom:6px; background:#fff; display:flex; justify-content:space-between; align-items:center;",
          div(
            div(style = "font-weight:600; font-size:0.84rem; color:#0f172a;", r$teacher_name),
            div(style = "font-size:0.75rem; color:#64748b;", sprintf("%s · %d sems", r$teacher_dept, r$sems_covered))
          ),
          div(style = "text-align:right;",
            span(class = badge_cls, delta_str),
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

      status_msg <- if (delta >= 10) "Significant Positive Gain"
                    else if (delta >= 0) "Consistent Performance"
                    else "Needs Targeted Support"

      div(style = "background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; padding:10px 14px; margin-bottom:12px; font-size:0.8rem;",
        div(style = "display:flex; justify-content:space-between; align-items:center;",
          span(style = "font-weight:700; color:#0f172a; font-size:0.875rem;", sel_t),
          span(style = "font-weight:600; color:#1e40af;", status_msg)
        ),
        div(style = "display:grid; grid-template-columns:repeat(3,1fr); gap:8px; margin-top:6px; color:#475569;",
          div(span("Sem 1 Positivity: "), tags$b(sprintf("%.1f%%", first_pos))),
          div(span("Latest Positivity: "), tags$b(sprintf("%.1f%%", last_pos))),
          div(span("Net Delta: "), tags$b(style = if (delta >= 0) "color:#059669;" else "color:#dc2626;", sprintf("%s%.1f%%", if (delta>=0) "+" else "", delta)))
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
              name = "Positivity %", line = list(color = "#1e40af", width = 2.5),
              marker = list(color = "#1e40af", size = 7)) %>%
        add_trace(y = ~avg_rating * 20, name = "Avg Rating (x20)", line = list(color = "#059669", width = 2, dash = "dash"),
                  marker = list(color = "#059669", size = 5)) %>%
        layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(
            title = "",
            color = "#64748b",
            categoryorder = "array",
            categoryarray = sub$semester,
            gridcolor = "rgba(0,0,0,0.05)"
          ),
          yaxis = list(title = "Percentage (%)", range = c(0, 100), color = "#64748b", gridcolor = "rgba(0,0,0,0.05)"),
          margin = list(l = 35, r = 10, t = 10, b = 35),
          showlegend = TRUE,
          legend = list(orientation = "h", x = 0, y = 1.15, font = list(color="#475569"))
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
      colors <- c("#1e40af", "#059669", "#d97706", "#7c3aed", "#db2777", "#0891b2")

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
          marker = list(size = 6, color = col)
        )
      }

      p %>% layout(
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
        xaxis = list(
          title = "Semester",
          color = "#64748b",
          categoryorder = "array",
          categoryarray = SEMESTER_ORDER,
          tickangle = -15,
          gridcolor = "rgba(0,0,0,0.05)"
        ),
        yaxis = list(title = "Positive Sentiment %", range = c(0, 100), color = "#64748b", gridcolor = "rgba(0,0,0,0.05)"),
        margin = list(l = 40, r = 10, t = 10, b = 40),
        legend = list(orientation = "h", x = 0, y = -0.25, font = list(color="#475569"))
      )
    })

    output$subject_delta_summary_ui <- renderUI({
      sub_df <- get_subject_satisfaction_trends()
      if (nrow(sub_df) == 0) return(p("No dimension trend data available."))

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

        badge_cls <- if (delta > 3) "gw-tag good" else if (delta < -3) "gw-tag critical" else "gw-tag moderate"
        status_txt <- if (delta > 3) sprintf("+%.1f%% Net Gain", delta)
                      else if (delta < -3) sprintf("%.1f%% Decline", delta)
                      else "Stable"

        div(style = "padding:8px 12px; border:1px solid #e2e8f0; border-radius:6px; margin-bottom:6px; background:#fff; display:flex; justify-content:space-between; align-items:center;",
          div(
            span(style = "font-weight:600; font-size:0.83rem; color:#0f172a;", lbl),
            div(style = "font-size:0.72rem; color:#64748b;", sprintf("Latest Rating: %.2f / 5", a_sub$avg_rating[n]))
          ),
          span(class = badge_cls, status_txt)
        )
      })
      tagList(Filter(Negate(is.null), cards))
    })

    # ── EXPLORER TAB ──────────────────────────────────────────────────────────
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
        bg <- if (!is.null(sel) && sel == r$id) "#eff6ff" else "#fff"
        badge_cls <- if (r$rating == 1) "gw-tag good" else if (r$rating == -1) "gw-tag critical" else "gw-tag"
        badge_lbl <- if (r$rating == 1) "Positive" else if (r$rating == -1) "Negative" else "Neutral"

        div(style = sprintf("padding:10px 12px; border-bottom:1px solid #f1f5f9; cursor:pointer; background:%s;", bg),
          onclick = sprintf("Shiny.setInputValue('%s',%d,{priority:'event'})", session$ns("exp_item_click"), r$id),
          div(style = "display:flex; justify-content:space-between; align-items:center;",
            span(style = "font-weight:600; font-size:0.83rem; color:#0f172a;", get_course_name(r$teacher_dept, r$aspect)),
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

      div(style = "display:flex; flex-direction:column; gap:12px;",
        div(style = "display:flex; justify-content:space-between; align-items:flex-start;",
          div(
            span(style = "font-size:0.7rem; color:#94a3b8; font-family:monospace;", sprintf("FB-%04d", item$id)),
            h4(style = "margin:2px 0; color:#0f172a; font-weight:700; font-size:1.05rem;", course),
            div(style = "margin-top:4px; display:flex; align-items:center; gap:8px;",
              span(style = "font-size:0.8125rem; color:#64748b;", dept),
              format_teacher_badge(item$teacher_name)
            )
          ),
          span(class = if (item$rating == 1) "gw-tag good" else if (item$rating == -1) "gw-tag critical" else "gw-tag",
            if (item$rating == 1) "Positive" else if (item$rating == -1) "Negative" else "Neutral")
        ),
        div(style = "display:grid; grid-template-columns:repeat(3,1fr); gap:8px; padding:10px 0; border-top:1px solid #e2e8f0; border-bottom:1px solid #e2e8f0;",
          div(span(style="font-size:0.67rem;color:#94a3b8;display:block;","Sentiment Score"), span(style="font-weight:700;font-family:monospace;color:#0f172a;", sent_score)),
          div(span(style="font-size:0.67rem;color:#94a3b8;display:block;","Semester"), span(style="font-weight:600;color:#0f172a;", item$semester %||% "N/A")),
          div(span(style="font-size:0.67rem;color:#94a3b8;display:block;","Received Date"), span(style="font-weight:500;color:#64748b;", format(as.POSIXct(item$created_at), "%b %d, %Y")))
        ),
        div(
          span(style="font-size:0.7rem;color:#64748b;text-transform:uppercase;font-weight:700;display:block;margin-bottom:4px;","Student Feedback"),
          tags$blockquote(style="margin:0; padding:10px 14px; border-left:3px solid #1e40af; font-size:0.84rem; color:#0f172a; line-height:1.5; font-style:italic; background:#fff; border-radius:0 6px 6px 0; border-top:1px solid #e2e8f0; border-right:1px solid #e2e8f0; border-bottom:1px solid #e2e8f0;", item$text)
        ),
        div(style="background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; padding:12px 14px;",
          span(style="font-size:0.7rem; color:#64748b; text-transform:uppercase; font-weight:700; display:block; margin-bottom:4px;","Assessment & Recommended Action"),
          p(style="margin:0; font-size:0.8125rem; color:#334155; line-height:1.45;",
            switch(as.character(item$rating),
              "1"  = "Positive evaluation. Teaching and resource delivery meet quality expectations.",
              "0"  = "Neutral evaluation. Continual monitoring recommended over the academic cycle.",
              "-1" = sprintf("Action recommended. Recommend departmental follow-up with %s regarding %s.", item$teacher_name %||% "faculty", course)
            ))
        )
      )
    })

    # `%||%` helper
    `%||%` <- function(a, b) if (!is.null(a) && !is.na(a) && a != "") a else b

    # ── READINESS TRACKER TABLE ──────────────────────────────────────────────
    output$dept_readiness_table <- DT::renderDataTable({
      df <- get_department_readiness_tracker()
      if (is.null(df) || nrow(df) == 0) return(data.frame(Message = "No readiness records found."))

      df$Progress <- sprintf("%d / %d (%s%%)", df$submitted_count, df$target_quota, df$completion_pct)
      
      out <- df[, c("department", "target_quota", "submitted_count", "pending_count", "completion_pct", "status")]
      names(out) <- c("Department", "Target Quota", "Collected Responses", "Pending Responses", "Completion %", "Readiness Status")
      
      DT::datatable(
        out,
        options = list(
          pageLength = 8,
          dom = 't',
          ordering = FALSE
        ),
        rownames = FALSE
      )
    })

    # ── FACULTY 4-SUBJECT ALLOCATION TABLE ────────────────────────────────────
    output$faculty_allocations_table <- DT::renderDataTable({
      df <- get_all_faculty_subject_allocations()
      if (is.null(df) || nrow(df) == 0) return(data.frame(Message = "No faculty allocation records found."))

      df$pos_pct_fmt <- ifelse(is.na(df$pos_pct), "Pending", sprintf("%.1f%%", df$pos_pct))
      df$avg_rat_fmt <- ifelse(is.na(df$avg_rating), "N/A", sprintf("%.2f / 5", df$avg_rating))

      out <- df[, c("faculty_name", "department", "course_code", "course_name", "semester", "credits", "total_feedback", "avg_rat_fmt", "pos_pct_fmt")]
      names(out) <- c("Faculty Instructor", "Department", "Course Code", "Course Title", "Semester", "Credits", "Responses", "Avg Rating", "Positive %")

      DT::datatable(
        out,
        options = list(
          pageLength = 8,
          scrollX = TRUE,
          dom = 'frtip'
        ),
        rownames = FALSE
      )
    })

    # Export PDF & Logout
    output$export_pdf <- pdf_report_handler(filtered_df, "Campus Listen Report")
    observeEvent(input$btn_logout, { logout_trigger(logout_trigger() + 1) })
  })
}
