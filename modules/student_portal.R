# modules/student_portal.R — Student Input Portal Shiny Module

studentPortalUI <- function(id) {
  ns <- NS(id)
  tagList(
    # Header
    div(style = "margin-bottom:28px;",
      div(style = "display:flex; justify-content:space-between; align-items:center;",
        div(
          h2(style = "font-weight:800; margin:0; background:linear-gradient(135deg,#f8fafc,#a5b4fc); -webkit-background-clip:text; -webkit-text-fill-color:transparent;",
            "\U0001F393 Student Feedback Portal"),
          p(style = "color:#94a3b8; margin:4px 0 0;", "Submit your honest feedback for the current semester")
        ),
        actionButton(ns("btn_logout"), "Logout", class = "btn-sm btn-outline-secondary",
          style = "border-radius:8px; color:#94a3b8; border-color:#334155;")
      )
    ),

    tabsetPanel(id = ns("student_tabs"),
      # ── TAB 1: Submit Feedback ──────────────────────────────────────────
      tabPanel("Submit Feedback",
        br(),
        div(style = "max-width:850px; margin:0 auto;",
          # Anonymity Toggle Card
          div(class = "glass-card", style = "margin-bottom:18px; display:flex; align-items:center; gap:18px; padding:16px 22px;",
            div(style = "flex:1;",
              strong(style = "color:#f8fafc;", "\U0001F510 Anonymous Submission"),
              p(style = "color:#94a3b8; font-size:0.85rem; margin:4px 0 0;",
                "When enabled, your identity is not stored. Encourages honest, unfiltered responses.")
            ),
            checkboxInput(ns("anon_toggle"), label = NULL, value = FALSE)
          ),

          # Department & Teacher Selection Card
          div(class = "glass-card", style = "margin-bottom:18px; padding:20px 22px;",
            h5(style = "color:#f8fafc; font-weight:700; margin-bottom:14px;", "\U0001F9D1\u200D\U0001F3EB Select Department & Teacher"),
            fluidRow(
              column(6,
                selectInput(ns("feedback_dept"), "Academic Department",
                  choices = NULL, width = "100%")
              ),
              column(6,
                selectInput(ns("feedback_faculty"), "Faculty Member / Teacher",
                  choices = NULL, width = "100%")
              )
            )
          ),

          # Aspect Forms
          lapply(list(
            list(id = "teaching",           label = "\U0001F4DA Teaching Quality",        icon = "\U0001F393",
                 subs = list(list("sub1", "Explanation Clarity"), list("sub2", "Approachability"), list("sub3", "Punctuality"))),
            list(id = "coursecontent",       label = "\U0001F4D6 Course Content",          icon = "\U0001F4D8",
                 subs = list(list("sub1", "Syllabus Relevance"), list("sub2", "Material Quality"), list("sub3", "Practical Use"))),
            list(id = "examination",         label = "\U0001F4DD Examination",             icon = "\U270F\UFE0F",
                 subs = list(list("sub1", "Paper Fairness"), list("sub2", "Grading Transparency"), list("sub3", "Exam Schedule"))),
            list(id = "labwork",             label = "\U0001F52C Lab Work",                icon = "\U0001F9EA",
                 subs = list(list("sub1", "Equipment Status"), list("sub2", "Lab Manual Clarity"), list("sub3", "Instructor Support"))),
            list(id = "library_facilities",  label = "\U0001F4DA Library Facilities",      icon = "\U0001F4DA",
                 subs = list(list("sub1", "Book Availability"), list("sub2", "Seating Capacity"), list("sub3", "Digital Catalog"))),
            list(id = "extracurricular",     label = "\U0001F3C6 Extracurricular",         icon = "\U0001F3AE",
                 subs = list(list("sub1", "Sports Facilities"), list("sub2", "Cultural Events"), list("sub3", "Club Support")))
          ), function(asp) {
            div(class = "glass-card", style = "margin-bottom:14px; padding: 18px;",
              h5(style = "font-weight:700; color:#f8fafc; margin-bottom:14px;", asp$label),
              fluidRow(
                column(6,
                  p(style = "color:#94a3b8; font-size:0.8rem; margin-bottom:6px; text-transform:uppercase; letter-spacing:0.05em;", "Sub-Attribute Ratings"),
                  lapply(asp$subs, function(sub) {
                    sliderInput(ns(paste0(asp$id, "_", sub[[1]])), label = sub[[2]],
                      min = 1, max = 5, value = 3, step = 1, width = "100%")
                  })
                ),
                column(6,
                  p(style = "color:#94a3b8; font-size:0.8rem; margin-bottom:6px; text-transform:uppercase; letter-spacing:0.05em;", "Comments (optional)"),
                  textAreaInput(ns(paste0(asp$id, "_text")), label = NULL,
                    placeholder = paste("Share your thoughts on", tolower(asp$label), "..."),
                    rows = 8, width = "100%")
                )
              )
            )
          }),

          # Submit Button
          div(style = "text-align:center; margin-top:10px;",
            actionButton(ns("btn_submit"), "\U0001F4E4 Submit All Feedback",
              class = "btn-primary btn-lg",
              style = "border-radius:12px; font-weight:700; padding:12px 40px; box-shadow:0 4px 20px rgba(59,130,246,0.35);")
          ),
          uiOutput(ns("submit_result"))
        )
      ),

      # ── TAB 2: My Submission History ───────────────────────────────────
      tabPanel("Submission History",
        br(),
        div(class = "glass-card",
          div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;",
            h5(style = "color:#f8fafc; font-weight:700; margin:0;", "\U0001F4CB My Feedback History"),
            uiOutput(ns("history_count"))
          ),
          DT::dataTableOutput(ns("history_table"))
        )
      )
    )
  )
}

studentPortalServer <- function(id, user, logout_trigger) {
  moduleServer(id, function(input, output, session) {
    source("helpers/db.R", local = TRUE)

    aspects <- c("teaching","coursecontent","examination","labwork","library_facilities","extracurricular")

    # Populate departments and teachers reactively
    faculty_data <- get_faculty_list()
    depts <- unique(faculty_data$department)
    updateSelectInput(session, "feedback_dept", choices = depts)

    observeEvent(input$feedback_dept, {
      req(input$feedback_dept)
      dept_teachers <- faculty_data[faculty_data$department == input$feedback_dept, ]
      teacher_choices <- setNames(dept_teachers$id, dept_teachers$name)
      updateSelectInput(session, "feedback_faculty", choices = teacher_choices)
    })

    # Rating average mapping to database: < 2.5 -> -1, < 3.5 -> 0, >= 3.5 -> 1
    rating_map <- function(r) { if (r < 2.5) -1L else if (r < 3.5) 0L else 1L }

    # Logout
    observeEvent(input$btn_logout, { logout_trigger(logout_trigger() + 1) })

    # Submit all aspects
    observeEvent(input$btn_submit, {
      anon <- as.integer(input$anon_toggle)
      sid  <- user$id
      fid  <- as.integer(input$feedback_faculty)
      semester <- "Semester 1"

      req(fid) # Ensure teacher is selected

      tryCatch({
        # Retrieve the global ML model bundle if loaded
        bundle <- get0("MODEL_BUNDLE", envir = .GlobalEnv, ifnotfound = NULL)
        
        for (asp in aspects) {
          sub1_val <- input[[paste0(asp, "_sub1")]]
          sub2_val <- input[[paste0(asp, "_sub2")]]
          sub3_val <- input[[paste0(asp, "_sub3")]]
          
          rating_raw <- (sub1_val + sub2_val + sub3_val) / 3
          sub_json   <- sprintf('{"sub1":%d,"sub2":%d,"sub3":%d}', sub1_val, sub2_val, sub3_val)
          text_raw   <- input[[paste0(asp, "_text")]]
          
          emotion_val <- "neutral"
          
          if (!is.null(bundle) && !is.null(text_raw) && text_raw != "") {
            preds <- predict_feedback(text_raw, bundle)
            emotion_val <- preds$emotion
          }
          
          insert_feedback(sid, anon, fid, asp, rating_map(rating_raw), text_raw, sub_json, emotion_val, semester)
        }
        output$submit_result <- renderUI({
          div(style = "margin-top:18px; padding:14px 20px; background:rgba(16,185,129,0.1); border:1px solid #10b981; border-radius:12px; color:#10b981; text-align:center; font-weight:600;",
            "\U2705 Feedback submitted successfully! Thank you for helping us improve.")
        })
        # Reset sliders to 3 and clear text
        for (asp in aspects) {
          updateSliderInput(session, paste0(asp, "_sub1"), value = 3)
          updateSliderInput(session, paste0(asp, "_sub2"), value = 3)
          updateSliderInput(session, paste0(asp, "_sub3"), value = 3)
          updateTextAreaInput(session, paste0(asp, "_text"), value = "")
        }
      }, error = function(e) {
        output$submit_result <- renderUI({
          div(style = "margin-top:18px; padding:14px 20px; background:rgba(239,68,68,0.1); border:1px solid #ef4444; border-radius:12px; color:#ef4444; text-align:center;",
            paste("\u274C Error:", e$message))
        })
      })
    })

    # History tab
    history_data <- reactive({
      input$btn_submit # refresh after submit
      df <- get_student_feedback(user$id)
      if (nrow(df) == 0) return(df)
      df$Sentiment <- ifelse(df$rating == 1, "\U0001F7E2 Positive", ifelse(df$rating == 0, "\U0001F7E1 Neutral", "\U0001F534 Negative"))
      df$Aspect    <- tools::toTitleCase(gsub("_", " ", df$aspect))
      df$Date      <- substr(df$created_at, 1, 16)
      df$Text      <- ifelse(is.na(df$text) | df$text == "", "(no comment)", df$text)
      df$Teacher   <- paste0(df$teacher_name, " (", df$teacher_dept, ")")
      df[, c("Teacher", "Aspect","Sentiment","Text","semester","Date")]
    })

    output$history_count <- renderUI({
      n <- nrow(history_data())
      tags$span(style = "color:#94a3b8; font-size:0.85rem;", sprintf("%d entries (non-anonymous)", n))
    })

    output$history_table <- DT::renderDataTable({
      df <- history_data()
      if (nrow(df) == 0) return(data.frame(Message = "No submissions found under your account yet."))
      df
    }, options = list(pageLength = 8, dom = "frtip", scrollX = TRUE),
       rownames = FALSE, class = "table-dark")
  })
}
