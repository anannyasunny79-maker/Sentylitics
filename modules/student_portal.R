# modules/student_portal.R — Student Input Portal (Warm Ivory & Deep Forest Green palette matching Admin)

studentPortalUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "student-portal-wrapper",
      # Header Row
      div(style = "margin-bottom:24px;",
        div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px;",
          div(
            tags$h1(class = "student-main-title", "🎓 Student Feedback Portal"),
            tags$p(class = "student-main-sub", "Share your academic experience — teaching, curriculum, exams & campus life.")
          ),
          actionButton(ns("btn_logout"), "Logout",
            style = "border-radius:8px; color:#4272d7; border:1px solid #e5e5e5; background:#ffffff; font-weight:600; padding:6px 18px; font-size:0.87rem;")
        )
      ),

      tabsetPanel(id = ns("student_tabs"),
        # ── TAB 1: Submit Feedback ──────────────────────────────────────────
        tabPanel("Submit Feedback",
          br(),

          # Anonymity Toggle Card
          div(class = "glass-card", style = "margin-bottom:18px; display:flex; align-items:center; gap:18px; padding:16px 22px; background:#f3f5f9 !important; border-color:#e5e5e5 !important;",
            div(style = "flex:1;",
              strong(style = "color:#4272d7; font-size:0.97rem; display:flex; align-items:center; gap:8px;", "🔒 Anonymous Submission"),
              p(style = "color:#7c7973; font-size:0.84rem; margin:3px 0 0;",
                "When enabled, your identity is not stored. Encourages honest, unfiltered responses.")
            ),
            checkboxInput(ns("anon_toggle"), label = NULL, value = FALSE)
          ),

          # Dept, Teacher & Semester (3-column grid)
          div(class = "glass-card", style = "margin-bottom:20px; padding:22px 24px; background:#eef4ec !important; border-color:#c5d9be !important;",
            tags$h3(class = "student-section-title", style = "margin-top:0;", "🧑‍🏫 Select Department, Teacher & Semester"),
            p(style = "color:#7c7973; font-size:0.84rem; margin-bottom:16px;",
              "Choose your academic department, instructor, and current course term."),
            fluidRow(
              column(4, selectInput(ns("feedback_dept"), "Academic Department", choices = NULL, width = "100%")),
              column(4, selectInput(ns("feedback_faculty"), "Faculty Member / Teacher", choices = NULL, width = "100%")),
              column(4, selectInput(ns("feedback_semester"), "Academic Semester",
                choices = paste("Semester", 1:8), selected = "Semester 1", width = "100%"))
            )
          ),

          # Sticky Progress Header
          uiOutput(ns("sticky_progress_header")),

          # Active Step Content
          uiOutput(ns("wizard_step_content")),

          # Navigation Footer
          div(class = "glass-card", style = "margin-top:20px; padding:16px 24px; display:flex; justify-content:space-between; align-items:center;",
            uiOutput(ns("wizard_nav_left")),
            uiOutput(ns("wizard_nav_right"))
          ),

          uiOutput(ns("submit_result"))
        ),

        # ── TAB 2: Submission History ───────────────────────────────────────
        tabPanel("Submission History",
          br(),
          div(class = "glass-card",
            div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;",
              tags$h3(class = "student-section-title", style = "margin:0;", "📋 My Feedback History"),
              uiOutput(ns("history_count"))
            ),
            DT::dataTableOutput(ns("history_table"))
          )
        )
      )
    )
  )
}

studentPortalServer <- function(id, user, logout_trigger) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    source("helpers/db.R", local = TRUE)

    # Current wizard step: 1 to 5
    current_step <- reactiveVal(1)

    # 5-step wizard definition
    step_info <- list(
      list(step = 1, title = "Teaching Quality & Pedagogy", icon = "🎓", aspects = list(
        list(id = "teaching", label = "Teaching Quality & Pedagogy",
             subs = list(list("sub1", "Explanation Clarity"), list("sub2", "Teacher Approachability"), list("sub3", "Lecture Punctuality")))
      )),
      list(step = 2, title = "Course Content & Curriculum", icon = "📚", aspects = list(
        list(id = "coursecontent", label = "Course Content & Material Quality",
             subs = list(list("sub1", "Syllabus Relevance"), list("sub2", "Study Material Quality"), list("sub3", "Practical Industry Utility")))
      )),
      list(step = 3, title = "Assessment & Examinations", icon = "📝", aspects = list(
        list(id = "examination", label = "Examination & Internal Grading",
             subs = list(list("sub1", "Question Paper Fairness"), list("sub2", "Grading Transparency"), list("sub3", "Timetable & Exam Schedule")))
      )),
      list(step = 4, title = "Practical Labs & Library", icon = "🔬", aspects = list(
        list(id = "labwork", label = "Practical Laboratory Work & Equipment",
             subs = list(list("sub1", "Equipment Working Condition"), list("sub2", "Lab Manual Clarity"), list("sub3", "Lab Instructor Support"))),
        list(id = "library_facilities", label = "Library Facilities & Resource Center",
             subs = list(list("sub1", "Textbook Availability"), list("sub2", "Study Room Capacity"), list("sub3", "Digital Catalog & E-Books")))
      )),
      list(step = 5, title = "Extracurricular & Student Life", icon = "🏆", aspects = list(
        list(id = "extracurricular", label = "Extracurriculars, Sports & Campus Events",
             subs = list(list("sub1", "Sports Infrastructure"), list("sub2", "Cultural Fests & Events"), list("sub3", "Student Club Support")))
      ))
    )

    # Populate departments and teachers
    faculty_data <- get_faculty_list()
    depts <- unique(faculty_data$department)
    updateSelectInput(session, "feedback_dept", choices = depts)

    observeEvent(input$feedback_dept, {
      req(input$feedback_dept)
      dept_teachers <- faculty_data[faculty_data$department == input$feedback_dept, ]
      teacher_choices <- setNames(dept_teachers$id, dept_teachers$name)
      updateSelectInput(session, "feedback_faculty", choices = teacher_choices)
    })

    # Navigation events
    observeEvent(input$btn_next, { current_step(min(5, current_step() + 1)) })
    observeEvent(input$btn_prev, { current_step(max(1, current_step() - 1)) })

    lapply(1:5, function(s) {
      observeEvent(input[[paste0("goto_step_", s)]], { current_step(s) })
    })

    # ── STICKY PROGRESS HEADER ─────────────────────────────────────────────────
    output$sticky_progress_header <- renderUI({
      step_num <- current_step()
      step_data <- step_info[[step_num]]
      pct <- round((step_num / 5) * 100)

      pills <- lapply(1:5, function(s) {
        st <- step_info[[s]]
        cls <- if (s == step_num) "student-step-pill active"
               else if (s < step_num) "student-step-pill completed"
               else "student-step-pill"
        lbl <- if (s < step_num) paste0("✓ Step ", s) else paste0(st$icon, " Step ", s)
        tags$button(
          class = cls,
          onclick = sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})", ns(paste0("goto_step_", s)), s),
          lbl
        )
      })

      div(class = "student-sticky-header",
        div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:10px; flex-wrap:wrap; gap:8px;",
          div(
            span(style = "font-size:0.72rem; font-weight:800; color:#4272d7; text-transform:uppercase; letter-spacing:0.1em;",
                 sprintf("SECTION %d OF 5", step_num)),
            tags$h3(style = "margin:3px 0 0; font-family:'Poppins', sans-serif; font-weight:700; font-size:1.35rem; color:#4272d7;",
                    sprintf("%s %s", step_data$icon, step_data$title))
          ),
          span(style = "font-weight:700; color:#4272d7; font-size:0.87rem; background:#f3f5f9; padding:5px 14px; border-radius:9999px; border:1px solid #e5e5e5;",
               sprintf("%d of 5 Completed (%d%%)", step_num, pct))
        ),
        # Progress track
        div(style = "width:100%; height:6px; background:#e0dbd1; border-radius:9999px; overflow:hidden; margin:0 0 12px 0;",
          div(style = sprintf("width:%d%%; height:100%%; background:#4272d7; transition:width 0.4s ease; border-radius:9999px;", pct))
        ),
        div(style = "display:flex; gap:7px; flex-wrap:wrap;", pills)
      )
    })

    # ── WIZARD STEP CONTENT ────────────────────────────────────────────────────
    output$wizard_step_content <- renderUI({
      step_num <- current_step()
      step_data <- step_info[[step_num]]

      cards <- lapply(step_data$aspects, function(asp) {
        div(class = "glass-card", style = "margin-bottom:20px;",
          tags$h3(class = "student-section-title", asp$label),
          fluidRow(
            column(6,
              div(class = "student-sub-title", "⚡ Rating Scale (1 – 5)"),
              lapply(asp$subs, function(sub) {
                sliderInput(ns(paste0(asp$id, "_", sub[[1]])), label = sub[[2]],
                  min = 1, max = 5, value = 3, step = 1, width = "100%")
              })
            ),
            column(6,
              div(class = "student-sub-title", "✍️ Comments & Feedback"),
              textAreaInput(ns(paste0(asp$id, "_text")), label = NULL,
                placeholder = paste("Share your comments or suggestions on", tolower(asp$label), "..."),
                rows = 7, width = "100%")
            )
          )
        )
      })

      tagList(cards)
    })

    # ── NAV FOOTER ─────────────────────────────────────────────────────────────
    output$wizard_nav_left <- renderUI({
      step_num <- current_step()
      if (step_num > 1) {
        actionButton(ns("btn_prev"), "← Previous",
          style = "border-radius:8px; font-weight:600; color:#4272d7; border:1px solid #e5e5e5; background:#ffffff; padding:9px 22px;")
      } else {
        tags$span(style = "color:#7c7973; font-size:0.85rem;", "Step 1 of 5 — Begin your feedback")
      }
    })

    output$wizard_nav_right <- renderUI({
      step_num <- current_step()
      if (step_num < 5) {
        actionButton(ns("btn_next"), "Next Step →",
          style = "border-radius:8px; font-weight:700; background:#4272d7; color:#ffffff; border:none; padding:10px 28px; box-shadow:0 3px 10px rgba(13,43,31,0.2);")
      } else {
        actionButton(ns("btn_submit"), "🚀 Submit All Feedback",
          style = "border-radius:8px; font-weight:800; background:#4272d7; color:#ffffff; border:none; padding:11px 34px; box-shadow:0 4px 14px rgba(13,43,31,0.25); font-size:1rem;")
      }
    })

    # Rating mapping
    rating_map <- function(r) { if (r < 2.5) -1L else if (r < 3.5) 0L else 1L }
    aspects_all <- c("teaching","coursecontent","examination","labwork","library_facilities","extracurricular")
    `%||%` <- function(a, b) if (!is.null(a) && !is.na(a)) a else b

    # Logout
    observeEvent(input$btn_logout, { logout_trigger(logout_trigger() + 1) })

    # Submit
    observeEvent(input$btn_submit, {
      anon     <- as.integer(input$anon_toggle)
      sid      <- user$id
      fid      <- as.integer(input$feedback_faculty)
      semester <- if (!is.null(input$feedback_semester) && input$feedback_semester != "") input$feedback_semester else "Semester 1"
      req(fid)

      tryCatch({
        bundle <- get0("MODEL_BUNDLE", envir = .GlobalEnv, ifnotfound = NULL)

        for (asp in aspects_all) {
          sub1_val   <- input[[paste0(asp, "_sub1")]] %||% 3
          sub2_val   <- input[[paste0(asp, "_sub2")]] %||% 3
          sub3_val   <- input[[paste0(asp, "_sub3")]] %||% 3
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
          div(style = "margin-top:18px; padding:18px 22px; background:#f3f5f9; border:1px solid #e5e5e5; border-left:4px solid #4272d7; border-radius:12px; color:#4272d7; text-align:left;",
            tags$h4(style = "margin:0 0 5px; font-family:'Poppins', sans-serif; font-weight:700; color:#4272d7;", "✅ Feedback Submitted Successfully!"),
            p(style = "margin:0; color:#4272d7; font-size:0.89rem;",
              sprintf("Recorded for %s under %s. Thank you, %s!", semester, user$name %||% "Student", user$name %||% ""))
          )
        })

        current_step(1)
        for (asp in aspects_all) {
          updateSliderInput(session, paste0(asp, "_sub1"), value = 3)
          updateSliderInput(session, paste0(asp, "_sub2"), value = 3)
          updateSliderInput(session, paste0(asp, "_sub3"), value = 3)
          updateTextAreaInput(session, paste0(asp, "_text"), value = "")
        }
      }, error = function(e) {
        output$submit_result <- renderUI({
          div(style = "margin-top:18px; padding:16px 22px; background:rgba(180,30,30,0.07); border:1px solid rgba(180,30,30,0.2); border-radius:10px; color:#b91c1c;",
            paste("❌ Submission Error:", e$message))
        })
      })
    })

    # History tab
    history_data <- reactive({
      input$btn_submit
      df <- get_student_feedback(user$id)
      if (nrow(df) == 0) return(df)
      df$Sentiment <- ifelse(df$rating == 1, "🟢 Positive", ifelse(df$rating == 0, "🟡 Neutral", "🔴 Negative"))
      df$Aspect    <- tools::toTitleCase(gsub("_", " ", df$aspect))
      df$Date      <- substr(df$created_at, 1, 16)
      df$Text      <- ifelse(is.na(df$text) | df$text == "", "(no comment)", df$text)
      df$Teacher   <- paste0(df$teacher_name, " (", df$teacher_dept, ")")
      df[, c("Teacher","Aspect","Sentiment","Text","semester","Date")]
    })

    output$history_count <- renderUI({
      n <- nrow(history_data())
      tags$span(style = "color:#7c7973; font-size:0.84rem; font-weight:600;", sprintf("%d total entries", n))
    })

    output$history_table <- DT::renderDataTable({
      df <- history_data()
      if (nrow(df) == 0) return(data.frame(Message = "No submissions found yet."))
      df
    }, options = list(pageLength = 8, dom = "frtip", scrollX = TRUE), rownames = FALSE)
  })
}
