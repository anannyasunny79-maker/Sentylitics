# modules/student_portal.R — Student Input Portal Shiny Module with Dark Theme & Vibrant Headings

studentPortalUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "student-portal-wrapper",
      # Header Row
      div(style = "margin-bottom:24px;",
        div(style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px;",
          div(
            tags$h1(class = "student-main-title", "🎓 Student Feedback Portal"),
            tags$p(class = "student-main-sub", "Share your academic experience across course teaching, curriculum, exams, and campus facilities.")
          ),
          actionButton(ns("btn_logout"), "Logout", class = "btn-sm btn-outline-secondary",
            style = "border-radius:8px; color:#ffffff; border-color:rgba(255,255,255,0.3); background:rgba(255,255,255,0.08); font-weight:600; padding:6px 16px;")
        )
      ),

      tabsetPanel(id = ns("student_tabs"),
        # ── TAB 1: Submit Feedback ──────────────────────────────────────────
        tabPanel("Submit Feedback",
          br(),
          # Anonymity Toggle Card
          div(class = "glass-card", style = "margin-bottom:18px; display:flex; align-items:center; gap:18px; padding:18px 24px;",
            div(style = "flex:1;",
              strong(style = "color:#ffffff; font-size:1rem; display:flex; align-items:center; gap:8px;", "🔒 Anonymous Submission"),
              p(style = "color:#cbd5e1; font-size:0.85rem; margin:4px 0 0;",
                "When enabled, your identity is not stored. Encourages 100% honest, unfiltered responses.")
            ),
            checkboxInput(ns("anon_toggle"), label = NULL, value = FALSE)
          ),

          # Department, Teacher & Semester Selection Card (3 EQUAL COLUMNS)
          div(class = "glass-card", style = "margin-bottom:20px; padding:22px 24px;",
            tags$h3(class = "student-section-title", style = "margin-top:0; border-bottom:none; padding-bottom:0;", "🧑‍🏫 Select Department, Teacher & Semester"),
            p(style = "color:#cbd5e1; font-size:0.84rem; margin-bottom:16px;", "Select your academic department, instructor, and current course term"),
            fluidRow(
              column(4,
                selectInput(ns("feedback_dept"), "Academic Department",
                  choices = NULL, width = "100%")
              ),
              column(4,
                selectInput(ns("feedback_faculty"), "Faculty Member / Teacher",
                  choices = NULL, width = "100%")
              ),
              column(4,
                selectInput(ns("feedback_semester"), "Academic Semester",
                  choices = paste("Semester", 1:8), selected = "Semester 1", width = "100%")
              )
            )
          ),

          # Sticky Progress Header (e.g. "3 of 5 Sections Completed")
          uiOutput(ns("sticky_progress_header")),

          # Step Wizard Active Panel Body
          uiOutput(ns("wizard_step_content")),

          # Navigation Footer (Previous / Next / Submit All)
          div(class = "glass-card", style = "margin-top:20px; padding:18px 24px; display:flex; justify-content:space-between; align-items:center;",
            uiOutput(ns("wizard_nav_left")),
            uiOutput(ns("wizard_nav_right"))
          ),

          uiOutput(ns("submit_result"))
        ),

        # ── TAB 2: My Submission History ───────────────────────────────────
        tabPanel("Submission History",
          br(),
          div(class = "glass-card",
            div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;",
              tags$h3(class = "student-section-title", style = "margin:0; border:none; padding:0;", "📋 My Feedback History"),
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

    # 5 Logical Wizard Steps Definition with High-Elegance Titles
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

    # Navigation Event Handlers
    observeEvent(input$btn_next, {
      current_step(min(5, current_step() + 1))
    })

    observeEvent(input$btn_prev, {
      current_step(max(1, current_step() - 1))
    })

    # Allow direct clicking on step pills
    lapply(1:5, function(s) {
      observeEvent(input[[paste0("goto_step_", s)]], {
        current_step(s)
      })
    })

    # ── STICKY PROGRESS HEADER ────────────────────────────────────────────────
    output$sticky_progress_header <- renderUI({
      step_num <- current_step()
      step_data <- step_info[[step_num]]
      pct <- round((step_num / 5) * 100)
      
      pills <- lapply(1:5, function(s) {
        st <- step_info[[s]]
        cls <- if (s == step_num) "student-step-pill active"
               else if (s < step_num) "student-step-pill completed"
               else "student-step-pill"
        icon_prefix <- if (s < step_num) "✓ " else paste0(st$icon, " ")
        
        tags$button(
          class = cls,
          onclick = sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})", ns(paste0("goto_step_", s)), s),
          paste0(icon_prefix, "Step ", s)
        )
      })

      div(class = "student-sticky-header",
        div(style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;",
          div(
            span(style = "font-size:0.75rem; font-weight:800; color:#34d399; text-transform:uppercase; letter-spacing:0.08em;",
                 sprintf("SECTION %d OF 5", step_num)),
            tags$h3(style = "margin:2px 0 0 0; font-family:'Playfair Display', Georgia, serif; font-weight:700; font-size:1.4rem; background:linear-gradient(135deg, #ffffff, #a7f3d0); -webkit-background-clip:text; -webkit-text-fill-color:transparent;",
               sprintf("%s %s", step_data$icon, step_data$title))
          ),
          span(style = "font-weight:800; color:#06b6d4; font-size:0.92rem; background:rgba(6,182,212,0.14); padding:6px 14px; border-radius:9999px; border:1px solid rgba(6,182,212,0.3);",
               sprintf("%d of 5 Sections Completed (%d%%)", step_num, pct))
        ),
        
        # Sticky Progress Bar Track
        div(style = "width:100%; height:8px; background:rgba(255,255,255,0.12); border-radius:9999px; overflow:hidden; margin:10px 0 14px 0;",
          div(style = sprintf("width:%d%%; height:100%%; background:linear-gradient(90deg, #10b981, #06b6d4); transition:width 0.4s ease; border-radius:9999px;", pct))
        ),

        # Step Navigation Pills
        div(style = "display:flex; gap:8px; flex-wrap:wrap;", pills)
      )
    })

    # ── WIZARD STEP CONTENT (VIBRANT HEADINGS & HIGH CONTRAST) ────────────────
    output$wizard_step_content <- renderUI({
      step_num <- current_step()
      step_data <- step_info[[step_num]]

      cards <- lapply(step_data$aspects, function(asp) {
        div(class = "glass-card", style = "margin-bottom:20px;",
          tags$h3(class = "student-section-title", asp$label),
          fluidRow(
            column(6,
              div(class = "student-sub-title", "⚡ Sub-Attribute Rating Scale (1 to 5)"),
              lapply(asp$subs, function(sub) {
                sliderInput(ns(paste0(asp$id, "_", sub[[1]])), label = sub[[2]],
                  min = 1, max = 5, value = 3, step = 1, width = "100%")
              })
            ),
            column(6,
              div(class = "student-sub-title", "✍️ Constructive Feedback & Comments"),
              textAreaInput(ns(paste0(asp$id, "_text")), label = NULL,
                placeholder = paste("Share detailed comments or suggestions on", tolower(asp$label), "..."),
                rows = 7, width = "100%")
            )
          )
        )
      })

      tagList(cards)
    })

    # ── WIZARD NAVIGATION FOOTER ──────────────────────────────────────────────
    output$wizard_nav_left <- renderUI({
      step_num <- current_step()
      if (step_num > 1) {
        actionButton(ns("btn_prev"), "← Previous Step", class = "btn-outline-secondary",
          style = "border-radius:10px; font-weight:700; color:#ffffff; border-color:rgba(255,255,255,0.3); background:rgba(255,255,255,0.08); padding:10px 22px;")
      } else {
        tags$span(style = "color:#cbd5e1; font-size:0.85rem; font-weight:600;", "Step 1 of 5 — Begin Form")
      }
    })

    output$wizard_nav_right <- renderUI({
      step_num <- current_step()
      if (step_num < 5) {
        actionButton(ns("btn_next"), "Next Step →", class = "btn-primary",
          style = "border-radius:10px; font-weight:700; background:linear-gradient(135deg, #10b981, #059669) !important; border:none; padding:10px 28px; box-shadow:0 4px 15px rgba(16,185,129,0.4);")
      } else {
        actionButton(ns("btn_submit"), "🚀 Submit All Feedback", class = "btn-success btn-lg",
          style = "border-radius:10px; font-weight:800; background:linear-gradient(135deg, #06b6d4, #10b981) !important; border:none; padding:12px 36px; box-shadow:0 4px 20px rgba(6,182,212,0.4); color:#ffffff;")
      }
    })

    # Rating average mapping to database: < 2.5 -> -1, < 3.5 -> 0, >= 3.5 -> 1
    rating_map <- function(r) { if (r < 2.5) -1L else if (r < 3.5) 0L else 1L }

    aspects_all <- c("teaching","coursecontent","examination","labwork","library_facilities","extracurricular")

    # Logout
    observeEvent(input$btn_logout, { logout_trigger(logout_trigger() + 1) })

    # Submit all aspects
    observeEvent(input$btn_submit, {
      anon <- as.integer(input$anon_toggle)
      sid  <- user$id
      fid  <- as.integer(input$feedback_faculty)
      semester <- if (!is.null(input$feedback_semester) && input$feedback_semester != "") input$feedback_semester else "Semester 1"

      req(fid) # Ensure teacher is selected

      tryCatch({
        bundle <- get0("MODEL_BUNDLE", envir = .GlobalEnv, ifnotfound = NULL)
        
        for (asp in aspects_all) {
          sub1_val <- input[[paste0(asp, "_sub1")]] %||% 3
          sub2_val <- input[[paste0(asp, "_sub2")]] %||% 3
          sub3_val <- input[[paste0(asp, "_sub3")]] %||% 3
          
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
          div(style = "margin-top:20px; padding:18px 24px; background:rgba(16,185,129,0.15); border:1px solid #10b981; border-radius:14px; color:#34d399; text-align:center; font-weight:700;",
            tags$h4(style = "margin:0 0 6px 0; color:#10b981; font-weight:800; font-family:'Playfair Display', serif;", "✅ Feedback Submitted Successfully!"),
            p(style = "margin:0; color:#a7f3d0; font-size:0.9rem;", sprintf("Recorded for %s under %s. Thank you for your contribution!", semester, user$name))
          )
        })

        # Reset wizard to step 1
        current_step(1)

        # Reset sliders & text
        for (asp in aspects_all) {
          updateSliderInput(session, paste0(asp, "_sub1"), value = 3)
          updateSliderInput(session, paste0(asp, "_sub2"), value = 3)
          updateSliderInput(session, paste0(asp, "_sub3"), value = 3)
          updateTextAreaInput(session, paste0(asp, "_text"), value = "")
        }
      }, error = function(e) {
        output$submit_result <- renderUI({
          div(style = "margin-top:20px; padding:18px 24px; background:rgba(239,68,68,0.15); border:1px solid #ef4444; border-radius:14px; color:#f87171; text-align:center;",
            paste("❌ Submission Error:", e$message))
        })
      })
    })

    # `%||%` helper
    `%||%` <- function(a, b) if (!is.null(a) && !is.na(a)) a else b

    # History tab
    history_data <- reactive({
      input$btn_submit # refresh after submit
      df <- get_student_feedback(user$id)
      if (nrow(df) == 0) return(df)
      df$Sentiment <- ifelse(df$rating == 1, "🟢 Positive", ifelse(df$rating == 0, "🟡 Neutral", "🔴 Negative"))
      df$Aspect    <- tools::toTitleCase(gsub("_", " ", df$aspect))
      df$Date      <- substr(df$created_at, 1, 16)
      df$Text      <- ifelse(is.na(df$text) | df$text == "", "(no comment)", df$text)
      df$Teacher   <- paste0(df$teacher_name, " (", df$teacher_dept, ")")
      df[, c("Teacher", "Aspect","Sentiment","Text","semester","Date")]
    })

    output$history_count <- renderUI({
      n <- nrow(history_data())
      tags$span(style = "color:#cbd5e1; font-size:0.85rem; font-weight:600;", sprintf("%d total entries recorded", n))
    })

    output$history_table <- DT::renderDataTable({
      df <- history_data()
      if (nrow(df) == 0) return(data.frame(Message = "No submissions found under your account yet."))
      df
    }, options = list(pageLength = 8, dom = "frtip", scrollX = TRUE),
       rownames = FALSE, class = "table-dark")
  })
}
