# modules/faculty_portal.R — Faculty Personal Insights Shiny Module

facultyPortalUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(style = "margin-bottom:28px;",
      div(style = "display:flex; justify-content:space-between; align-items:center;",
        div(
          h2(style = "font-weight:800; margin:0; background:linear-gradient(135deg,#f8fafc,#86efac); -webkit-background-clip:text; -webkit-text-fill-color:transparent;",
            "\U0001F9D1\u200D\U0001F3EB Faculty Insights"),
          uiOutput(ns("faculty_subtitle"))
        ),
        actionButton(ns("btn_logout"), "Logout", class = "btn-sm btn-outline-secondary",
          style = "border-radius:8px; color:#94a3b8; border-color:#334155;")
      )
    ),

    # KPI Row
    fluidRow(
      column(3, uiOutput(ns("kpi_total"))),
      column(3, uiOutput(ns("kpi_positive"))),
      column(3, uiOutput(ns("kpi_neutral"))),
      column(3, uiOutput(ns("kpi_negative")))
    ),

    fluidRow(
      # Longitudinal Line Chart
      column(7,
        div(class = "glass-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:5px;",
            h5(style = "color:#f8fafc; font-weight:700; margin:0;", "\U0001F4C8 Sentiment Over Time"),
            selectInput(ns("aspect_filter"), NULL,
              choices = c("Teaching" = "teaching", "Course Content" = "coursecontent"),
              width = "150px")
          ),
          p(style = "color:#94a3b8; font-size:0.8rem; margin-bottom:12px;", "Monthly average sentiment scores for your courses"),
          plotlyOutput(ns("longitudinal_chart"), height = "260px")
        )
      ),
      # NLP Highlights
      column(5,
        div(class = "glass-card", style = "height:355px; overflow-y:auto;",
          h5(style = "color:#f8fafc; font-weight:700; margin-bottom:5px;", "\U0001F4AC Constructive Student Comments"),
          p(style = "color:#94a3b8; font-size:0.8rem; margin-bottom:14px;", "Top actionable, non-sarcastic feedback from students"),
          uiOutput(ns("nlp_highlights"))
        )
      )
    ),

    fluidRow(
      # Word Cloud — Positive
      column(6,
        div(class = "glass-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;",
            h5(style = "color:#10b981; font-weight:700; margin:0;", "\u2B50 Positive Themes"),
            tags$small(style = "color:#64748b;", "Most frequent positive words")
          ),
          uiOutput(ns("wc_positive"))
        )
      ),
      # Word Cloud — Negative
      column(6,
        div(class = "glass-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;",
            h5(style = "color:#ef4444; font-weight:700; margin:0;", "\u26A0\uFE0F Areas to Improve"),
            tags$small(style = "color:#64748b;", "Most frequent negative words")
          ),
          uiOutput(ns("wc_negative"))
        )
      )
    )
  )
}

facultyPortalServer <- function(id, user, logout_trigger) {
  moduleServer(id, function(input, output, session) {
    source("helpers/db.R",  local = TRUE)
    source("helpers/nlp.R", local = TRUE)

    output$faculty_subtitle <- renderUI({
      p(style = "color:#94a3b8; margin:4px 0 0;",
        sprintf("Insights for %s | Department: %s", user$name, user$department))
    })

    # Load feedback for Teaching + Course Content for THIS faculty member
    faculty_df <- reactive({
      df <- get_faculty_feedback(user$id, aspects = c("teaching","coursecontent"))
      df
    })

    # Filtered by selected aspect
    filtered_df <- reactive({
      df <- faculty_df()
      asp <- input$aspect_filter
      df[df$aspect == asp, ]
    })

    # ── KPI Cards ────────────────────────────────────────────────────────
    make_kpi <- function(val, label, color, icon_char) {
      div(class = "glass-card",
        style = "text-align:center; padding:18px 12px;",
        div(style = sprintf("font-size:1.7rem; font-weight:800; color:%s;", color), val),
        div(style = "color:#94a3b8; font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; margin-top:4px;",
          paste(icon_char, label))
      )
    }

    output$kpi_total    <- renderUI({ df <- filtered_df(); make_kpi(nrow(df), "Total Reviews", "#f8fafc", "\U0001F4CB") })
    output$kpi_positive <- renderUI({ df <- filtered_df(); make_kpi(sum(df$rating == 1), "Positive", "#10b981", "\U0001F7E2") })
    output$kpi_neutral  <- renderUI({ df <- filtered_df(); make_kpi(sum(df$rating == 0), "Neutral", "#f59e0b", "\U0001F7E1") })
    output$kpi_negative <- renderUI({ df <- filtered_df(); make_kpi(sum(df$rating == -1), "Negative", "#ef4444", "\U0001F534") })

    # ── Longitudinal Chart ───────────────────────────────────────────────
    output$longitudinal_chart <- renderPlotly({
      df <- filtered_df()
      if (nrow(df) == 0) return(plot_ly() %>% layout(paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)'))

      if ("semester" %in% names(df) && any(!is.na(df$semester) & df$semester != "")) {
        sem_df <- aggregate(rating ~ semester, data = df, FUN = function(x) {
          round(mean(ifelse(x == 1, 5, ifelse(x == 0, 3, 1))), 2)
        })
        sem_df$sem_num <- as.integer(gsub("[^0-9]", "", sem_df$semester))
        sem_df <- sem_df[order(sem_df$sem_num), ]

        plot_ly(sem_df, x = ~semester, y = ~rating,
                type = "scatter", mode = "lines+markers",
                line   = list(color="#3b82f6", width=3, shape="spline"),
                marker = list(color="#10b981", size=9, line=list(color="#0c0e1a", width=2))) %>%
          layout(
            paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
            xaxis = list(title="Semester Cycle", color="#94a3b8", gridcolor="rgba(255,255,255,0.04)"),
            yaxis = list(title="Avg Rating (1-5)", color="#94a3b8", gridcolor="rgba(255,255,255,0.04)", range=c(1, 5)),
            margin = list(l=50, r=10, t=10, b=50)
          )
      } else {
        df$dt  <- as.POSIXct(df$created_at, format = "%Y-%m-%d %H:%M:%S")
        df$mon <- format(df$dt, "%Y-%m")
        monthly <- aggregate(rating ~ mon, data = df, FUN = mean)
        monthly <- monthly[order(monthly$mon), ]

        plot_ly(monthly, x = ~mon, y = ~round(rating, 2),
                type = "scatter", mode = "lines+markers",
                line   = list(color="#3b82f6", width=3, shape="spline"),
                marker = list(color="#06b6d4", size=9, line=list(color="#0c0e1a", width=2))) %>%
          layout(
            paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
            xaxis = list(title="", color="#94a3b8", gridcolor="rgba(255,255,255,0.04)", tickangle=-30),
            yaxis = list(title="Avg Sentiment", color="#94a3b8", gridcolor="rgba(255,255,255,0.04)",
                         range=c(-1.2, 1.2),
                         tickvals=c(-1,0,1), ticktext=c("Neg","Neutral","Pos")),
            margin = list(l=50, r=10, t=10, b=50)
          )
      }
    })

    # ── NLP Actionable Highlights ────────────────────────────────────────
    output$nlp_highlights <- renderUI({
      df <- filtered_df()
      comments <- get_actionable_comments(df, top_n = 5)
      if (length(comments) == 0) {
        return(p(style = "color:#64748b; text-align:center; padding:20px;",
          "No actionable comments found yet."))
      }
      lapply(seq_along(comments), function(i) {
        div(style = "padding:12px 14px; background:rgba(59,130,246,0.07); border-left:3px solid #3b82f6; border-radius:0 8px 8px 0; margin-bottom:10px;",
          p(style = "color:#cbd5e1; font-size:0.88rem; margin:0; font-style:italic;",
            paste0('\u201C', comments[i], '\u201D')),
          p(style = "color:#64748b; font-size:0.75rem; margin:6px 0 0;", paste("Comment", i))
        )
      })
    })

    # ── Word Clouds ──────────────────────────────────────────────────────
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

    # Logout
    observeEvent(input$btn_logout, { logout_trigger(logout_trigger() + 1) })
  })
}
