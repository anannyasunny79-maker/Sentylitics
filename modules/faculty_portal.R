# modules/faculty_portal.R — Faculty Insights Dashboard
# Matches admin portal design: White & Olive Green sidebar + KPI cards + Charts + Comments + Profile

library(shiny)
library(plotly)
library(DT)

# ── Constants ──────────────────────────────────────────────────────────────────
FACULTY_ASPECT_LABELS <- c(
  teaching           = "Teaching Quality",
  coursecontent      = "Course Content",
  examination        = "Examination",
  labwork            = "Lab Facilities",
  library_facilities = "Library & Resources",
  extracurricular    = "Extracurricular"
)
FACULTY_ASPECT_ICONS <- c(
  teaching = "🎓",
  coursecontent = "📚",
  examination = "📝",
  labwork = "🔬",
  library_facilities = "📖",
  extracurricular = "🏆"
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
        /* ── FACULTY PORTAL — WHITE & OLIVE GREEN THEME ─────────────────────── */
        .fc-app {
          display: flex;
          min-height: 100vh;
          font-family: 'Poppins', sans-serif;
          background-color: #e5e5e5;
          color: #333333;
          font-size: 0.95rem;
        }

        /* ── SIDEBAR ─────────────────────────────────────────────────────────── */
        .fc-sidebar {
          width: 260px;
          background: #ffffff;
          color: #333333;
          display: flex;
          flex-direction: column;
          flex-shrink: 0;
          position: fixed;
          top: 0; bottom: 0; left: 0;
          z-index: 100;
          border-right: 1px solid #e5e5e5;
          box-shadow: 0px 2px 5px 0px rgba(0, 0, 0, 0.1);
        }
        .fc-sidebar-brand {
          padding: 22px 20px;
          display: flex;
          align-items: center;
          gap: 12px;
          border-bottom: 1px solid #e5e5e5;
          background: #ffffff;
        }
        .fc-brand-icon {
          width: 40px; height: 40px;
          background: linear-gradient(135deg, #4272d7 0%, #3868cd 100%);
          border-radius: 10px;
          display: flex; align-items: center; justify-content: center;
          color: #ffffff;
          font-size: 1.2rem;
          box-shadow: 0px 2px 5px 0px rgba(0, 0, 0, 0.1);
        }
        .fc-brand-name {
          font-weight: 800;
          font-size: 1.05rem;
          color: #333333;
          letter-spacing: -0.02em;
        }
        .fc-brand-sub { font-size: 0.7rem; color: #557544; }

        /* Nav */
        .fc-nav {
          padding: 16px 12px;
          display: flex;
          flex-direction: column;
          gap: 4px;
          flex: 1;
        }
        .fc-nav-section-title {
          font-size: 0.67rem;
          font-weight: 700;
          color: #6b8e58;
          text-transform: uppercase;
          letter-spacing: 0.1em;
          padding: 12px 14px 4px 14px;
        }
        .fc-nav-btn {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 10px 14px;
          border-radius: 8px;
          color: #333333;
          font-size: 0.87rem;
          font-weight: 600;
          background: transparent;
          border: none;
          cursor: pointer;
          width: 100%;
          text-align: left;
          transition: all 0.15s ease;
        }
        .fc-nav-btn:hover { background: #f3f5f9; color: #333333; }
        .fc-nav-btn.active {
          background: #f3f5f9 !important;
          color: #4272d7 !important;
          font-weight: 800;
          border-left: 4px solid #4272d7;
          box-shadow: 0 4px 12px rgba(16,185,129,0.2);
        }
        .fc-nav-btn.active span { color: #ffffff !important; }

        /* Sidebar footer */
        .fc-sidebar-user {
          padding: 16px 20px;
          border-top: 1px solid #e5e5e5;
          display: flex;
          align-items: center;
          justify-content: space-between;
          background: #ffffff;
        }
        .fc-user-info { display: flex; flex-direction: column; gap: 1px; }
        .fc-user-name { font-weight: 800; font-size: 0.88rem; color: #000000; }
        .fc-user-role { font-size: 0.72rem; color: #4272d7; font-weight: 600; }

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
        .fc-header-title {
          font-size: 1.4rem;
          font-weight: 800;
          color: #333333;
          margin: 0;
          letter-spacing: -0.02em;
        }
        .fc-header-sub { font-size: 0.82rem; color: #64748b; margin: 2px 0 0 0; }

        /* Filter bar */
        .fc-filter-bar { display: flex; align-items: center; gap: 12px; }
        .fc-filter-item {
          display: flex;
          align-items: center;
          gap: 8px;
          background: #ffffff;
          border: 1px solid #d4e3ca;
          border-radius: 8px;
          padding: 4px 10px;
        }
        .fc-filter-item label, .fc-filter-item .control-label {
          margin: 0 !important;
          font-size: 0.75rem !important;
          font-weight: 700 !important;
          color: #3b572a !important;
          text-transform: uppercase !important;
          letter-spacing: 0.04em !important;
        }
        .fc-filter-item select {
          border: none !important;
          background: transparent !important;
          font-size: 0.85rem !important;
          color: #333333 !important;
          font-weight: 700 !important;
          outline: none !important;
          cursor: pointer !important;
          padding: 2px 4px !important;
        }

        .fc-body { padding: 24px 32px 48px 32px; flex: 1; }

        /* ── CARDS ────────────────────────────────────────────────────────────── */
        .fc-card {
          background: #ffffff;
          border: 1px solid #e2ebd8;
          border-radius: 14px;
          padding: 22px 24px;
          margin-bottom: 22px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.03);
          transition: all 0.2s ease;
        }
        .fc-card:hover { box-shadow: 0 6px 18px rgba(61,90,43,0.06); }
        .fc-card-title {
          font-size: 1rem;
          font-weight: 800;
          color: #333333;
          margin: 0 0 4px 0;
          display: flex; align-items: center; gap: 8px;
        }
        .fc-card-sub { font-size: 0.8rem; color: #64748b; margin: 0 0 16px 0; }

        /* KPI Grid */
        .fc-kpi-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 18px;
          margin-bottom: 24px;
        }
        .fc-kpi-card {
          background: #ffffff;
          border: 1px solid #e2ebd8;
          border-radius: 14px;
          padding: 20px;
          display: flex;
          flex-direction: column;
          gap: 8px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.02);
          border-top: 4px solid #4272d7;
          transition: transform 0.2s;
        }
        .fc-kpi-card:hover { transform: translateY(-2px); }
        .fc-kpi-card.tot { border-top-color: #333333; }
        .fc-kpi-card.pos { border-top-color: #059669; }
        .fc-kpi-card.neg { border-top-color: #ef4444; }
        .fc-kpi-card.neu { border-top-color: #f59e0b; }
        .fc-kpi-label {
          font-size: 0.75rem; font-weight: 700;
          text-transform: uppercase; letter-spacing: 0.06em; color: #64748b;
        }
        .fc-kpi-value { font-size: 2.2rem; font-weight: 800; color: #333333; line-height: 1; }
        .fc-kpi-sub { font-size: 0.78rem; color: #64748b; }
        .fc-progress {
          width: 100%; height: 6px;
          background: #f1f5f9;
          border-radius: 9999px;
          overflow: hidden;
          margin-top: 2px;
        }
        .fc-progress-bar { height: 100%; border-radius: 9999px; }

        /* Aspect row bars */
        .fc-aspect-row {
          display: flex; align-items: center; gap: 14px;
          padding: 10px 14px;
          border-radius: 10px;
          border: 1px solid #f1f5f9;
          margin-bottom: 8px;
          background: #ffffff;
          transition: all 0.15s;
        }
        .fc-aspect-row:hover { background: #f8faf6; border-color: #e5e5e5; }
        .fc-aspect-icon { font-size: 1.2rem; width: 28px; text-align:center; flex-shrink:0; }
        .fc-aspect-label { font-weight: 700; font-size: 0.88rem; color: #333333; min-width: 150px; }
        .fc-aspect-bar-wrap { flex: 1; height: 8px; background: #f1f5f9; border-radius: 9999px; overflow: hidden; }
        .fc-aspect-bar-fill { height: 100%; border-radius: 9999px; }
        .fc-aspect-pct { font-size: 0.82rem; font-weight: 700; color: #4272d7; min-width: 40px; text-align: right; }
        .fc-aspect-count { font-size: 0.75rem; color: #94a3b8; min-width: 60px; text-align: right; }

        /* Comment cards */
        .fc-comment-card {
          padding: 14px 16px;
          background: #f8fafc;
          border: 1px solid #e2ebd8;
          border-left: 4px solid #4272d7;
          border-radius: 0 10px 10px 0;
          margin-bottom: 10px;
        }
        .fc-comment-text {
          color: #333333; font-size: 0.87rem;
          font-style: italic; margin: 0 0 6px 0; line-height: 1.5;
        }
        .fc-comment-meta { font-size: 0.74rem; color: #94a3b8; margin: 0; }
        .fc-comment-card.negative {
          border-left-color: #ef4444;
          background: #fff8f8;
        }

        /* Profile section */
        .fc-profile-avatar {
          width: 72px; height: 72px;
          background: linear-gradient(135deg, #4272d7, #3868cd);
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          font-size: 2rem; color: #ffffff;
          flex-shrink: 0;
        }
        .fc-profile-badge {
          display: inline-flex; align-items: center;
          background: #eef6ea; color: #333333;
          font-size: 0.78rem; font-weight: 700;
          padding: 3px 10px; border-radius: 9999px;
          border: 1px solid #cce0bf;
          gap: 4px;
        }
        .fc-stat-box {
          background: #ffffff;
          border: 1px solid #e5e5e5;
          border-radius: 10px;
          padding: 14px 18px;
          text-align: center;
        }
        .fc-stat-val { font-size: 1.8rem; font-weight: 800; color: #333333; }
        .fc-stat-lbl { font-size: 0.75rem; color: #64748b; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; }

        /* Responsive */
        @media (max-width: 900px) {
          .fc-sidebar { width: 70px; }
          .fc-brand-name, .fc-brand-sub, .fc-nav-btn span, .fc-nav-section-title, .fc-user-info { display: none; }
          .fc-main { margin-left: 70px; }
          .fc-kpi-grid { grid-template-columns: repeat(2,1fr); }
          .fc-body { padding: 16px; }
        }
      "))
    ),

    div(class = "fc-app",

      # ── SIDEBAR ──────────────────────────────────────────────────────────────
      div(class = "fc-sidebar",

        div(class = "fc-sidebar-brand",
          div(class = "fc-brand-icon", "🧑‍🏫"),
          div(
            div(class = "fc-brand-name", "Campus Listen"),
            div(class = "fc-brand-sub", "Faculty Dashboard")
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
            style = "background:transparent;border:none;color:#3b572a;font-size:1.1rem;cursor:pointer;",
            title = "Logout")
        )
      ),

      # ── MAIN CANVAS ──────────────────────────────────────────────────────────
      div(class = "fc-main",

        div(class = "fc-header",
          div(uiOutput(ns("fc_header_title_ui"))),
          div(class = "fc-filter-bar",
            div(class = "fc-filter-item",
              tags$span("📅"),
              selectInput(ns("fc_semester_filter"), label = "Semester",
                choices = c("All Semesters" = "all"), width = "150px")
            ),
            div(class = "fc-filter-item",
              tags$span("📂"),
              selectInput(ns("fc_aspect_filter"), label = "Aspect",
                choices = c("All Aspects" = "all",
                  "Teaching"    = "teaching",
                  "Course Content" = "coursecontent",
                  "Examination" = "examination",
                  "Lab Work"    = "labwork",
                  "Library"     = "library_facilities",
                  "Extracurricular" = "extracurricular"),
                width = "160px")
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
        list(id = "overview",  icon = "📊", label = "Overview"),
        list(id = "trends",    icon = "📈", label = "Sentiment Trends"),
        list(id = "comments",  icon = "💬", label = "Student Comments"),
        list(id = "profile",   icon = "👤", label = "My Profile")
      )
      lapply(tabs, function(t) {
        cls <- if (cur == t$id) "fc-nav-btn active" else "fc-nav-btn"
        tags$button(class = cls,
          onclick = sprintf("Shiny.setInputValue('%s','%s',{priority:'event'})",
                            ns("fc_nav_click"), t$id),
          span(t$icon), span(t$label)
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
        overview = "My Feedback Overview",
        trends   = "Sentiment Trends & Analysis",
        comments = "Student Comments",
        profile  = "My Profile & Stats"
      )
      sub_txt <- switch(t,
        overview = paste0("Feedback summary for ", user$name %||% "you", " — ", user$department %||% "your department"),
        trends   = "Time-series and per-aspect breakdown of your student ratings",
        comments = "Constructive, actionable comments written by students",
        profile  = "Your teaching profile, contact info and summary statistics"
      )
      tagList(
        h1(class = "fc-header-title", title_txt),
        p(class = "fc-header-sub", sub_txt)
      )
    })

    # ── Null-coalescing helper ─────────────────────────────────────────────────
    `%||%` <- function(a, b) if (!is.null(a) && !is.na(a) && a != "") a else b

    # ── Raw Data ──────────────────────────────────────────────────────────────
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

    # Filtered data (by semester + aspect)
    filtered_df <- reactive({
      df  <- all_faculty_df()
      sem <- input$fc_semester_filter
      asp <- input$fc_aspect_filter
      if (!is.null(sem) && sem != "all") df <- df[!is.na(df$semester) & df$semester == sem, ]
      if (!is.null(asp) && asp != "all") df <- df[!is.na(df$aspect)   & df$aspect   == asp, ]
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
      df <- all_faculty_df()  # always all aspects for the bars
      sem <- input$fc_semester_filter
      if (!is.null(sem) && sem != "all") df <- df[!is.na(df$semester) & df$semester == sem, ]
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
      tagList(

        # KPI Grid
        div(class = "fc-kpi-grid",
          div(class = "fc-kpi-card tot",
            span(class = "fc-kpi-label", "Total Reviews"),
            div(class = "fc-kpi-value", formatC(kv$n, format = "d", big.mark = ",")),
            span(class = "fc-kpi-sub", "student entries")
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
            div(class = "fc-kpi-value", style = "color:#ef4444;", sprintf("%d%%", kv$neg_pct)),
            div(class = "fc-progress",
              div(class = "fc-progress-bar",
                style = sprintf("width:%d%%;background:#ef4444;", kv$neg_pct))),
            span(class = "fc-kpi-sub", sprintf("%d responses", kv$neg))
          ),
          div(class = "fc-kpi-card neu",
            span(class = "fc-kpi-label", "Neutral"),
            div(class = "fc-kpi-value", style = "color:#d97706;", sprintf("%d%%", kv$neu_pct)),
            div(class = "fc-progress",
              div(class = "fc-progress-bar",
                style = sprintf("width:%d%%;background:#f59e0b;", kv$neu_pct))),
            span(class = "fc-kpi-sub", sprintf("%d responses", kv$neu))
          )
        ),

        # Top row: Donut + Aspect bars
        div(style = "display:grid; grid-template-columns:1fr 1.6fr; gap:20px; margin-bottom:22px;",
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", "🥧 Sentiment Distribution"),
            p(class = "fc-card-sub", "Share of positive, neutral & negative"),
            plotlyOutput(ns("chart_donut"), height = "260px")
          ),
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", "📋 Feedback by Aspect"),
            p(class = "fc-card-sub", "Positivity rate across all 6 feedback dimensions"),
            uiOutput(ns("aspect_bars_ui"))
          )
        ),

        # Bottom row: Timeline + Word Clouds
        div(class = "fc-card",
          p(class = "fc-card-title", "📅 Sentiment Over Time"),
          p(class = "fc-card-sub", "Monthly/semester average score across selected filters"),
          plotlyOutput(ns("chart_timeline"), height = "260px")
        ),

        div(style = "display:grid; grid-template-columns:1fr 1fr; gap:20px;",
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", style = "color:#059669;", "⭐ Positive Themes"),
            p(class = "fc-card-sub", "Most frequent positive words from student comments"),
            uiOutput(ns("wc_positive"))
          ),
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", style = "color:#ef4444;", "⚠️ Areas to Improve"),
            p(class = "fc-card-sub", "Most frequent negative words from student comments"),
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
              p(class = "fc-card-title", style = "margin:0;", "📈 Semester-wise Sentiment Trend"),
              p(class = "fc-card-sub", style = "margin:4px 0 0;",
                "Average sentiment across semesters — filter by aspect above")
            )
          ),
          plotlyOutput(ns("chart_semester_trend"), height = "300px")
        ),

        # Per-aspect grouped bar
        div(class = "fc-card",
          p(class = "fc-card-title", "📊 Aspect Comparison — Positive vs Negative"),
          p(class = "fc-card-sub", "Side-by-side count of positives and negatives for each feedback category"),
          plotlyOutput(ns("chart_aspect_bar"), height = "300px")
        ),

        # Radar chart
        div(class = "fc-card",
          p(class = "fc-card-title", "🕸️ Performance Radar"),
          p(class = "fc-card-sub", "Visual overview of positivity across all 6 teaching dimensions"),
          plotlyOutput(ns("chart_radar"), height = "340px")
        )
      )
    }

    # ── 3. COMMENTS TAB ───────────────────────────────────────────────────────
    render_comments_tab <- function() {
      tagList(
        div(style = "display:grid; grid-template-columns:1fr 1fr; gap:20px;",
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", style = "color:#059669;", "👍 Top Constructive Feedback"),
            p(class = "fc-card-sub", "Best and most detailed student comments worth acting on"),
            uiOutput(ns("comments_positive"))
          ),
          div(class = "fc-card", style = "margin-bottom:0;",
            p(class = "fc-card-title", style = "color:#ef4444;", "⚠️ Concerns Raised"),
            p(class = "fc-card-sub", "Negative feedback highlighting areas for improvement"),
            uiOutput(ns("comments_negative"))
          )
        ),

        br(),

        div(class = "fc-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;",
            div(
              p(class = "fc-card-title", style = "margin:0;", "📋 All Student Comments"),
              p(class = "fc-card-sub", style = "margin:4px 0 0;", "Full searchable table of written feedback")
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
            div(class = "fc-profile-avatar", "🧑‍🏫"),
            div(
              tags$h2(style = "margin:0; font-size:1.4rem; font-weight:800; color:#333333;",
                user$name %||% "Faculty Member"),
              p(style = "margin:4px 0 8px; color:#64748b; font-size:0.88rem;",
                paste0("📧 ", user$email %||% "N/A", "  •  🏫 ", user$department %||% "N/A")),
              span(class = "fc-profile-badge", "🏷️ Faculty Member"),
              tags$span(" "),
              span(class = "fc-profile-badge", style = "background:#e0e7ff;color:#3730a3;border-color:#c7d2fe;",
                paste0("🏫 ", user$department %||% "Department"))
            )
          )
        ),

        # Stats row
        div(style = "display:grid; grid-template-columns:repeat(4,1fr); gap:18px; margin-bottom:22px;",
          uiOutput(ns("profile_stat_total")),
          uiOutput(ns("profile_stat_pos")),
          uiOutput(ns("profile_stat_neg")),
          uiOutput(ns("profile_stat_avg"))
        ),

        # Aspect breakdown for profile
        div(class = "fc-card",
          p(class = "fc-card-title", "📋 My Teaching Dimension Breakdown"),
          p(class = "fc-card-sub", "Positive feedback rate for each aspect students rated you on"),
          uiOutput(ns("profile_aspect_detail"))
        ),

        # Best semester card
        div(class = "fc-card",
          p(class = "fc-card-title", "🏆 Best & Worst Semester"),
          p(class = "fc-card-sub", "Your highest and lowest rated semesters based on average sentiment"),
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
        hole   = 0.55,
        marker = list(colors = c("#059669", "#f59e0b", "#ef4444"),
                      line = list(color = "#ffffff", width = 2)),
        textfont = list(color = "#ffffff", size = 12)
      ) %>%
        layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          showlegend = TRUE,
          legend = list(orientation = "h", x = 0.1, y = -0.1, font = list(color="#333333")),
          margin = list(l=10, r=10, t=10, b=40),
          annotations = list(list(
            text = paste0("<b>", kv$pos_pct, "%</b><br>Positive"),
            x = 0.5, y = 0.5, showarrow = FALSE,
            font = list(size = 14, color = "#333333")
          ))
        )
    })

    # Aspect bars UI
    output$aspect_bars_ui <- renderUI({
      df <- aspect_summary()
      lapply(seq_len(nrow(df)), function(i) {
        row <- df[i, ]
        bar_color <- if (row$pos_pct >= 60) "#059669"
                     else if (row$pos_pct >= 40) "#f59e0b"
                     else "#ef4444"
        div(class = "fc-aspect-row",
          span(class = "fc-aspect-icon", row$icon),
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

    # Timeline chart
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
          line   = list(color = "#4272d7", width = 3, shape = "spline"),
          marker = list(color = "#059669", size = 9,
                        line = list(color = "#ffffff", width = 2)),
          text = ~paste0(semester, "<br>Avg: ", rating),
          hoverinfo = "text"
        ) %>% layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(title = "Semester", color = "#64748b",
                       gridcolor = "rgba(0,0,0,0.05)"),
          yaxis = list(title = "Avg Score (1-5)", color = "#64748b",
                       range = c(1, 5.2), gridcolor = "rgba(0,0,0,0.05)"),
          margin = list(l=50, r=20, t=10, b=50)
        )
      } else {
        df$dt  <- as.POSIXct(df$created_at, format = "%Y-%m-%d %H:%M:%S")
        df$mon <- format(df$dt, "%Y-%m")
        monthly <- aggregate(rating ~ mon, data = df, FUN = mean)
        monthly <- monthly[order(monthly$mon), ]
        plot_ly(monthly, x = ~mon, y = ~round(rating, 2),
          type = "scatter", mode = "lines+markers",
          line = list(color = "#4272d7", width = 3, shape = "spline"),
          marker = list(color = "#059669", size = 9, line = list(color="#fff", width=2))
        ) %>% layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(title="", color="#64748b", tickangle=-30,
                       gridcolor="rgba(0,0,0,0.05)"),
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
        line   = list(color="#4272d7", width=3, shape="spline"),
        marker = list(color="#059669", size=10, line=list(color="#fff",width=2))
      ) %>% layout(
        paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
        xaxis = list(title="Semester", color="#64748b", gridcolor="rgba(0,0,0,0.05)"),
        yaxis = list(title="Avg Score (1–5)", color="#64748b",
                     range=c(0.8,5.5), gridcolor="rgba(0,0,0,0.05)"),
        margin = list(l=50, r=20, t=20, b=50)
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
          marker = list(color = "#ef4444", line = list(color="#fff", width=1))) %>%
        layout(
          barmode = "group",
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(title = "", color = "#64748b", gridcolor="rgba(0,0,0,0.04)",
                       tickangle = -20),
          yaxis = list(title = "Responses", color = "#64748b", gridcolor="rgba(0,0,0,0.04)"),
          legend = list(orientation = "h", x = 0, y = 1.1, font=list(color="#333333")),
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
        fillcolor = "rgba(74,107,53,0.2)",
        line  = list(color = "#4272d7", width = 2),
        marker = list(color = "#059669", size = 7)
      ) %>% layout(
        polar = list(
          radialaxis = list(visible=TRUE, range=c(0,100), color="#64748b",
                            gridcolor="rgba(0,0,0,0.08)"),
          angularaxis = list(color="#333333", gridcolor="rgba(0,0,0,0.06)")
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
        return(p(style="color:#94a3b8;text-align:center;padding:20px;", "No negative comments found."))
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
      df$Sentiment <- ifelse(df$rating == 1, "🟢 Positive",
                      ifelse(df$rating == 0, "🟡 Neutral", "🔴 Negative"))
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
      make_stat_box(sprintf("%.1f/5", avg), "Avg Score")
    })

    # Profile aspect detail
    output$profile_aspect_detail <- renderUI({
      df <- aspect_summary()
      lapply(seq_len(nrow(df)), function(i) {
        row <- df[i, ]
        bar_color <- if (row$pos_pct >= 60) "#059669"
                     else if (row$pos_pct >= 40) "#f59e0b"
                     else "#ef4444"
        sentiment_label <- if (row$pos_pct >= 60) "Good" else if (row$pos_pct >= 40) "Fair" else "Needs Work"
        div(class = "fc-aspect-row",
          span(class = "fc-aspect-icon", row$icon),
          span(class = "fc-aspect-label", row$label),
          div(class = "fc-aspect-bar-wrap",
            div(class = "fc-aspect-bar-fill",
              style = sprintf("width:%d%%;background:%s;", row$pos_pct, bar_color))),
          span(class = "fc-aspect-pct", sprintf("%d%%", row$pos_pct)),
          span(class = "fc-aspect-count", sprintf("(%d rev.)", row$n)),
          span(style = sprintf("font-size:0.74rem;font-weight:700;color:%s;min-width:80px;text-align:right;",
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

      div(style = "display:grid; grid-template-columns:1fr 1fr; gap:18px;",
        div(style = "background:#f0fdf4; border:1px solid #86efac; border-left:4px solid #059669; border-radius:10px; padding:16px 20px;",
          div(style = "font-size:0.75rem; font-weight:700; color:#059669; text-transform:uppercase; letter-spacing:0.06em; margin-bottom:4px;",
            "🏆 Best Semester"),
          div(style = "font-size:1.4rem; font-weight:800; color:#333333;", best$semester),
          div(style = "font-size:0.85rem; color:#64748b; margin-top:4px;",
            sprintf("Avg score: %.1f/5 • %d responses", best$avg, best$n))
        ),
        div(style = "background:#fff8f8; border:1px solid #fca5a5; border-left:4px solid #ef4444; border-radius:10px; padding:16px 20px;",
          div(style = "font-size:0.75rem; font-weight:700; color:#ef4444; text-transform:uppercase; letter-spacing:0.06em; margin-bottom:4px;",
            "📉 Needs Improvement"),
          div(style = "font-size:1.4rem; font-weight:800; color:#333333;", worst$semester),
          div(style = "font-size:0.85rem; color:#64748b; margin-top:4px;",
            sprintf("Avg score: %.1f/5 • %d responses", worst$avg, worst$n))
        )
      )
    })

    # ── LOGOUT ────────────────────────────────────────────────────────────────
    observeEvent(input$btn_logout, { logout_trigger(logout_trigger() + 1) })
  })
}
