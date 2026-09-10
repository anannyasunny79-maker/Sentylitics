# app.R — Campus Listen | Institutional College Feedback & Sentiment Analytics Platform
# Unified Institutional Design System: Deep Blue (#4d6b1e, #3d5516), Slate (#f8fafc, #0f172a), Inter Typography

library(shiny)
library(shinyjs)
library(bslib)
library(plotly)
library(DBI)
library(RSQLite)
library(DT)

# Source all modules and helpers
source("helpers/db.R",               local = FALSE)
source("helpers/nlp.R",              local = FALSE)
source("helpers/export.R",           local = FALSE)
source("modules/student_portal.R",   local = FALSE)
source("modules/faculty_portal.R",   local = FALSE)
source("modules/admin_portal.R",     local = FALSE)

assets_path <- "C:/Users/Student/.gemini/antigravity-ide/brain/2eb42f98-d304-4733-b057-93d7608316c4"
if (dir.exists(assets_path)) addResourcePath("assets", assets_path)
addResourcePath("www", "www")

# Load machine learning model bundle
MODEL_BUNDLE <- NULL
if (file.exists("data/model_center.rds")) {
  MODEL_BUNDLE <- readRDS("data/model_center.rds")
  message("Successfully loaded R model center bundle!")
} else {
  message("Warning: data/model_center.rds not found. Fallbacks will be used.")
}

# College departments list
COLLEGE_DEPARTMENTS <- c(
  "Computer Science & Engineering",
  "Electronics & Biomedical Engineering",
  "Electrical & Electronics Engineering",
  "Electronics & Communication Engineering",
  "Mechanical Engineering",
  "Civil Engineering",
  "Artificial Intelligence and Data Science",
  "Robotics and Automation"
)

# ── SHARED INSTITUTIONAL CSS ──────────────────────────────────────────────────
SHARED_CSS <- "
  /* ================================================================
     INSTITUTIONAL DESIGN SYSTEM — Modern Higher Ed Analytics
  ================================================================ */
  html {
    font-size: 100% !important;
  }
  *, *::before, *::after { box-sizing: border-box; }
  body {
    margin: 0; padding: 0;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 0.9375rem !important;
    line-height: 1.5;
    background-color: #f8fafc;
    color: #0f172a;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }

  /* Typography Scale */
  h1, .h1 { font-size: 1.75rem; font-weight: 700; color: #0f172a; letter-spacing: -0.025em; line-height: 1.25; margin: 0 0 0.5rem; }
  h2, .h2 { font-size: 1.25rem; font-weight: 600; color: #0f172a; letter-spacing: -0.02em; line-height: 1.3; margin: 0 0 0.5rem; }
  h3, .h3 { font-size: 1.0625rem; font-weight: 600; color: #0f172a; letter-spacing: -0.015em; line-height: 1.35; margin: 0 0 0.5rem; }
  h4, .h4 { font-size: 0.9375rem; font-weight: 600; color: #1e293b; margin: 0 0 0.25rem; }
  p { margin: 0 0 0.75rem; color: #334155; }
  .text-muted { color: #64748b !important; font-size: 0.8125rem; }

  /* Animations */
  @keyframes cl-fadeSlideUp {
    from { opacity: 0; transform: translateY(10px); }
    to   { opacity: 1; transform: translateY(0); }
  }
  @keyframes cl-fadeIn {
    from { opacity: 0; }
    to   { opacity: 1; }
  }

  /* ================================================================
     AUTHENTICATION VIEW — FULL PAGE GRADIENT WITH CENTERED PANEL
  ================================================================ */
  .login-page {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    width: 100%;
    position: relative;
    padding: 48px 24px;
    background: linear-gradient(135deg, rgba(77, 107, 30, 0.85), rgba(30, 43, 10, 0.90)), url('www/login_bg.png');
    background-position: center center;
    background-size: cover;
    background-repeat: no-repeat;
    background-attachment: fixed;
  }

  /* Top Left Branding Logo */
  .cl-brand-top-left {
    position: absolute;
    top: 32px;
    left: 40px;
    z-index: 10;
  }
  .cl-brand {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .cl-brand-icon {
    width: 36px; height: 36px;
    background: rgba(255, 255, 255, 0.18);
    border: 1px solid rgba(255, 255, 255, 0.35);
    border-radius: 8px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .cl-brand-text { display: flex; flex-direction: column; gap: 2px; }
  .cl-brand-name {
    color: #ffffff;
    font-size: 13px;
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    line-height: 1;
  }
  .cl-brand-sub {
    color: rgba(255, 255, 255, 0.82);
    font-size: 11px;
    letter-spacing: 0.02em;
    line-height: 1;
  }

  /* Bottom Left Confidential Footer */
  .cl-left-footer-bottom-left {
    position: absolute;
    bottom: 28px;
    left: 40px;
    color: rgba(255, 255, 255, 0.75);
    font-size: 12px;
    line-height: 1.5;
    z-index: 10;
  }

  /* Centered Login Container */
  .login-center-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 100%;
    max-width: 460px;
    z-index: 20;
    margin: auto;
  }

  .login-card {
    background: #ffffff;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 36px 40px;
    width: 100%;
    max-width: 460px;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2), 0 10px 10px -5px rgba(0, 0, 0, 0.1);
    animation: cl-fadeSlideUp 0.35s ease-out both;
  }
  .login-card-overline {
    display: block;
    color: #4d6b1e;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    margin-bottom: 6px;
  }
  .login-card-title {
    font-family: 'Inter', sans-serif;
    font-size: 1.5rem;
    font-weight: 700;
    color: #0f172a;
    margin: 0 0 6px 0;
    letter-spacing: -0.025em;
  }
  .login-card-desc {
    color: #64748b;
    font-size: 13px;
    line-height: 1.5;
    margin-bottom: 20px;
  }
  .login-card label,
  .login-card .control-label {
    display: block;
    color: #334155;
    font-size: 12.5px;
    font-weight: 600;
    margin-bottom: 5px;
    text-transform: none !important;
  }
  .login-card .form-control,
  .login-card input[type=text],
  .login-card input[type=email],
  .login-card input[type=password],
  .login-card select {
    background: #ffffff !important;
    border: 1px solid #cbd5e1 !important;
    border-radius: 6px !important;
    color: #0f172a !important;
    font-size: 13.5px !important;
    font-family: 'Inter', sans-serif !important;
    padding: 9px 12px !important;
    width: 100% !important;
    box-shadow: none !important;
    outline: none !important;
    transition: border-color 0.15s ease, box-shadow 0.15s ease !important;
  }
  .login-card .form-control:focus,
  .login-card input:focus,
  .login-card select:focus {
    border-color: #6b8c2a !important;
    box-shadow: 0 0 0 3px rgba(90, 112, 34, 0.12) !important;
  }
  .login-card .form-group { margin-bottom: 14px; }

  /* Mode Switcher Tabs */
  .auth-mode-bar {
    display: flex;
    background: #f1f5f9;
    border-radius: 6px;
    padding: 3px;
    margin-bottom: 20px;
    border: 1px solid #e2e8f0;
    width: 100%;
  }
  .auth-tab-btn {
    flex: 1;
    padding: 7px 12px;
    text-align: center;
    border-radius: 4px;
    font-size: 13px;
    font-weight: 600;
    color: #64748b;
    background: transparent;
    border: none;
    cursor: pointer;
    transition: all 0.15s ease;
    font-family: 'Inter', sans-serif;
  }
  .auth-tab-btn.active {
    background: #ffffff;
    color: #4d6b1e;
    font-weight: 600;
    box-shadow: 0 1px 2px rgba(0,0,0,0.06);
  }

  /* Primary Button */
  .btn-login {
    width: 100% !important;
    background: #4d6b1e !important;
    color: #ffffff !important;
    border: 1px solid #3d5516 !important;
    border-radius: 6px !important;
    padding: 10px 18px !important;
    font-size: 13.5px !important;
    font-weight: 600 !important;
    font-family: 'Inter', sans-serif !important;
    cursor: pointer !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    gap: 8px !important;
    margin-top: 14px !important;
    transition: background-color 0.15s ease !important;
  }
  .btn-login:hover {
    background: #5a7a22 !important;
  }

  /* Demo Credentials helper */
  .demo-creds {
    margin-top: 16px;
    padding: 12px 14px;
    background: #f8fafc;
    border-radius: 6px;
    border: 1px solid #e2e8f0;
    width: 100%;
    max-width: 460px;
  }
  .demo-btn {
    flex: 1;
    padding: 7px 10px;
    border-radius: 6px;
    border: 1px solid #cbd5e1;
    background: #ffffff;
    color: #4d6b1e;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.15s ease;
    text-align: center;
  }
  .demo-btn:hover {
    background: #f0f5e6;
    border-color: #9bbf60;
  }

  .login-error-box {
    margin-top: 12px;
    padding: 10px 12px;
    background: #fef2f2;
    border: 1px solid #fecaca;
    border-radius: 6px;
    color: #991b1b;
    font-size: 12.5px;
    line-height: 1.4;
  }
  .auth-switch-prompt {
    margin-top: 16px;
    text-align: center;
    font-size: 12.5px;
    color: #64748b;
  }
  .auth-switch-action {
    color: #4d6b1e;
    font-weight: 600;
    cursor: pointer;
    background: none;
    border: none;
    padding: 0 2px;
    font-size: 12.5px;
    text-decoration: underline;
    font-family: 'Inter', sans-serif;
  }

  /* ================================================================
     MAIN PORTAL CONTAINER & TOP NAVIGATION
  ================================================================ */
  .portal-body {
    background-color: #f8fafc;
    min-height: 100vh;
    font-family: 'Inter', sans-serif;
    color: #0f172a;
    display: flex;
    flex-direction: column;
  }
  .portal-topbar {
    background: #ffffff !important;
    border-bottom: 1px solid #e2e8f0 !important;
    padding: 12px 24px;
    display: flex;
    align-items: center;
    gap: 16px;
    position: sticky;
    top: 0;
    z-index: 1020;
    box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.03);
  }
  .portal-topbar-brand {
    font-weight: 700;
    font-size: 1.05rem;
    color: #0f172a;
    display: flex;
    align-items: center;
    gap: 8px;
    letter-spacing: -0.01em;
  }
  .portal-topbar-user {
    font-size: 13px;
    color: #334155;
    font-weight: 500;
  }
  .role-badge {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 11.5px;
    font-weight: 600;
    padding: 3px 8px;
    border-radius: 4px;
    letter-spacing: 0.02em;
    text-transform: uppercase;
  }
  .role-badge.badge-student { background: #f0f5e6; color: #4d6b1e; border: 1px solid #c8dba0; }
  .role-badge.badge-faculty { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0; }
  .role-badge.badge-admin   { background: #f8fafc; color: #334155; border: 1px solid #cbd5e1; }

  /* Standard Card System */
  .glass-card, .gw-card, .fc-card {
    background: #ffffff !important;
    border: 1px solid #e2e8f0 !important;
    border-radius: 8px !important;
    box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.03) !important;
    padding: 20px 24px !important;
    margin-bottom: 20px !important;
    transition: border-color 0.15s ease !important;
  }

  /* Form Controls */
  .form-control, input[type=text], input[type=email], input[type=password], input[type=number], select, textarea {
    background: #ffffff !important;
    border: 1px solid #cbd5e1 !important;
    border-radius: 6px !important;
    color: #0f172a !important;
    font-size: 13.5px !important;
    font-family: 'Inter', sans-serif !important;
    padding: 8px 12px !important;
    box-shadow: none !important;
    outline: none !important;
  }
  .form-control:focus, input:focus, select:focus, textarea:focus {
    border-color: #6b8c2a !important;
    box-shadow: 0 0 0 3px rgba(90, 112, 34, 0.12) !important;
  }

  /* Standard Buttons */
  .btn-primary {
    background: #4d6b1e !important;
    border-color: #3d5516 !important;
    color: #ffffff !important;
    font-weight: 600 !important;
    border-radius: 6px !important;
    font-size: 13px !important;
    padding: 7px 14px !important;
  }
  .btn-primary:hover { background: #5a7a22 !important; }
  .btn-outline-secondary {
    background: #ffffff !important;
    border: 1px solid #cbd5e1 !important;
    color: #334155 !important;
    font-weight: 500 !important;
    border-radius: 6px !important;
    font-size: 13px !important;
    padding: 7px 14px !important;
  }
  .btn-outline-secondary:hover { background: #f1f5f9 !important; color: #0f172a !important; }

  /* Navigation Tabs */
  .nav-tabs {
    border-bottom: 1px solid #e2e8f0 !important;
    gap: 4px;
  }
  .nav-tabs .nav-link {
    color: #64748b !important;
    font-weight: 500 !important;
    font-size: 13.5px !important;
    border: none !important;
    border-bottom: 2px solid transparent !important;
    padding: 9px 16px !important;
    background: transparent !important;
  }
  .nav-tabs .nav-link:hover {
    color: #0f172a !important;
  }
  .nav-tabs .nav-link.active {
    color: #4d6b1e !important;
    border-bottom: 2px solid #4d6b1e !important;
    font-weight: 600 !important;
    background: transparent !important;
  }

  /* Sliders — clean slate/blue */
  .irs--shiny .irs-bar { background: #4d6b1e !important; border-color: #4d6b1e !important; }
  .irs--shiny .irs-handle { border: 2px solid #4d6b1e !important; background: #ffffff !important; width: 18px !important; height: 18px !important; top: 22px !important; }
  .irs--shiny .irs-from, .irs--shiny .irs-to, .irs--shiny .irs-single { background: #4d6b1e !important; border-radius: 4px !important; font-size: 11px !important; }
  .irs--shiny .irs-line { background: #e2e8f0 !important; }
  .irs-min, .irs-max, .irs-grid-text { color: #64748b !important; font-size: 11px !important; }

  /* DataTables */
  table.dataTable {
    border-collapse: collapse !important;
    width: 100% !important;
    font-size: 13px !important;
  }
  table.dataTable thead th {
    background-color: #f8fafc !important;
    color: #334155 !important;
    font-weight: 600 !important;
    border-bottom: 1px solid #e2e8f0 !important;
    padding: 10px 12px !important;
  }
  table.dataTable tbody td {
    padding: 10px 12px !important;
    border-bottom: 1px solid #f1f5f9 !important;
    color: #0f172a !important;
  }
  table.dataTable tbody tr:hover {
    background-color: #f8fafc !important;
  }

  /* Responsive Rules */
  @media (max-width: 900px) {
    .login-page { flex-direction: column; }
    .login-left { width: 100%; min-width: 100%; padding: 32px 24px; min-height: 220px; }
    .login-right { width: 100%; padding: 32px 16px; min-height: unset; }
    .login-card { padding: 24px 20px; }
  }
"

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "preconnect", href = "https://fonts.gstatic.com", crossorigin = NA),
    tags$link(
      href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap",
      rel = "stylesheet"
    ),
    tags$style(HTML(SHARED_CSS)),
    tags$title("Campus Listen — College Feedback & Analytics")
  ),
  uiOutput("page_content")
)

# ── SERVER ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  user_session   <- reactiveValues(user = NULL)
  logout_trigger <- reactiveVal(0)
  auth_mode      <- reactiveVal("login")  # "login" or "signup"

  # Reset session on logout
  observeEvent(logout_trigger(), {
    if (logout_trigger() > 0) {
      user_session$user <- NULL
      auth_mode("login")
      updateTextInput(session, "login_email",    value = "")
      updateTextInput(session, "login_password", value = "")
    }
  })

  # Switch between login and signup
  observeEvent(input$switch_auth, {
    auth_mode(input$switch_auth)
    output$login_error  <- renderUI(NULL)
    output$signup_error <- renderUI(NULL)
  })

  # ── PAGE ROUTER ─────────────────────────────────────────────────────────
  output$page_content <- renderUI({
    if (is.null(user_session$user)) {

      # ── INSTITUTIONAL LOGIN / SIGNUP VIEW ─────────────────────────────────
      div(class = "login-page",

        # Top-Left Brand Header
        div(class = "cl-brand-top-left",
          div(class = "cl-brand",
            div(class = "cl-brand-icon",
              tags$svg(
                xmlns = "http://www.w3.org/2000/svg", viewBox = "0 0 24 24",
                style = "width:20px;height:20px;fill:none;stroke:#ffffff;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;",
                tags$path(d = "M22 10v6M2 10l10-5 10 5-10 5z"),
                tags$path(d = "M6 12v5c3 3 9 3 12 0v-5")
              )
            ),
            div(class = "cl-brand-text",
              div(class = "cl-brand-name", "Campus Listen"),
              div(class = "cl-brand-sub",  "Institutional Analytics Platform")
            )
          )
        ),


        # Centered Floating Form Container
        div(class = "login-center-container",

          # Authentication Card
          div(class = "login-card",

            # Mode Switcher Tabs
            div(class = "auth-mode-bar",
              tags$button(
                class = if (auth_mode() == "login") "auth-tab-btn active" else "auth-tab-btn",
                onclick = "Shiny.setInputValue('switch_auth', 'login', {priority:'event'})",
                "Sign In"
              ),
              tags$button(
                class = if (auth_mode() == "signup") "auth-tab-btn active" else "auth-tab-btn",
                onclick = "Shiny.setInputValue('switch_auth', 'signup', {priority:'event'})",
                "Create Account"
              )
            ),

            if (auth_mode() == "login") {
              # ── SIGN IN FORM ───────────────────────────────────────────────
              tagList(
                tags$span(class = "login-card-overline", "Portal Access"),
                tags$h2(class = "login-card-title", "Sign In"),
                div(class = "login-card-desc",
                  "Enter your university email credentials to access your portal."
                ),

                textInput("login_email", "University Email",
                  placeholder = "name@college.edu", width = "100%"),
                passwordInput("login_password", "Password",
                  placeholder = "Enter password", width = "100%"),

                actionButton("btn_login",
                  label = HTML("Sign In to Portal &nbsp;<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' style='width:14px;height:14px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle;'><polyline points='9 18 15 12 9 6'/></svg>"),
                  class = "btn-login"
                ),

                uiOutput("login_error"),

                div(class = "auth-switch-prompt",
                  "Need a student account? ",
                  tags$button(
                    class = "auth-switch-action",
                    onclick = "Shiny.setInputValue('switch_auth', 'signup', {priority:'event'})",
                    "Register here"
                  )
                )
              )
            } else {
              # ── SIGN UP FORM ───────────────────────────────────────────────
              tagList(
                tags$span(class = "login-card-overline", "Student Registration"),
                tags$h2(class = "login-card-title", "Create Student Account"),
                div(class = "login-card-desc",
                  "Register to submit end-of-semester course and teaching evaluations."
                ),

                textInput("signup_name", "Full Name",
                  placeholder = "e.g., Alex Johnson", width = "100%"),

                textInput("signup_email", "University Email",
                  placeholder = "student@college.edu", width = "100%"),

                fluidRow(
                  column(7,
                    selectInput("signup_dept", "Department",
                      choices = COLLEGE_DEPARTMENTS, width = "100%")
                  ),
                  column(5,
                    selectInput("signup_semester", "Semester",
                      choices = paste("Semester", 1:8), selected = "Semester 1", width = "100%")
                  )
                ),

                passwordInput("signup_password", "Password",
                  placeholder = "Choose password (min. 4 characters)", width = "100%"),

                passwordInput("signup_password_confirm", "Confirm Password",
                  placeholder = "Confirm chosen password", width = "100%"),

                actionButton("btn_signup",
                  label = HTML("Register Account &nbsp;<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' style='width:14px;height:14px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle;'><path d='M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2'/><circle cx='8.5' cy='7' r='4'/><line x1='20' y1='8' x2='20' y2='14'/><line x1='23' y1='11' x2='17' y2='11'/></svg>"),
                  class = "btn-login"
                ),

                uiOutput("signup_error"),

                div(class = "auth-switch-prompt",
                  "Already registered? ",
                  tags$button(
                    class = "auth-switch-action",
                    onclick = "Shiny.setInputValue('switch_auth', 'login', {priority:'event'})",
                    "Sign in here"
                  )
                )
              )
            }
          ),

          # Demo Credentials (Institutional Helper Chips)
          if (auth_mode() == "login") {
            div(class = "demo-creds",
              p(style = "font-size:11px; font-weight:700; color:#64748b; text-transform:uppercase; letter-spacing:0.08em; margin-bottom:8px;",
                "Institutional Demo Credentials"),
              div(style = "display:grid; grid-template-columns:1fr 1fr; gap:8px;",
                tags$button(
                  onclick = "Shiny.setInputValue('fill_demo', 'student_pending', {priority:'event'})",
                  class = "demo-btn",
                  "Student (Pending Demo)"
                ),
                tags$button(
                  onclick = "Shiny.setInputValue('fill_demo', 'student_submitted', {priority:'event'})",
                  class = "demo-btn",
                  "Student (Submitted)"
                ),
                tags$button(
                  onclick = "Shiny.setInputValue('fill_demo', 'faculty', {priority:'event'})",
                  class = "demo-btn",
                  "Faculty Portal"
                ),
                tags$button(
                  onclick = "Shiny.setInputValue('fill_demo', 'admin', {priority:'event'})",
                  class = "demo-btn",
                  "Executive Admin"
                )
              )
            )
          }
        )
      )

    } else {
      # ── ACTIVE PORTAL CONTAINER (UNIFIED VERTICAL SIDEBAR LAYOUT ACROSS ALL PORTALS) ──
      u <- user_session$user
      switch(u$role,
        student = studentPortalUI("student_mod"),
        faculty = facultyPortalUI("faculty_mod"),
        admin   = adminPortalUI("admin_mod")
      )
    }
  })

  # Global Topbar Sign Out
  observeEvent(input$btn_global_logout, {
    logout_trigger(logout_trigger() + 1)
  })

  # ── DEMO QUICK-FILL HANDLER ──────────────────────────────────────────────
  observeEvent(input$fill_demo, {
    creds <- switch(input$fill_demo,
      student_pending   = list(email = "priya@college.edu",  password = "student123"),
      student_submitted = list(email = "alex@college.edu",   password = "student123"),
      faculty           = list(email = "sunita@college.edu", password = "faculty123"),
      admin             = list(email = "admin@college.edu",  password = "admin123"),
      NULL
    )
    if (!is.null(creds)) {
      updateTextInput(session,     "login_email",    value = creds$email)
      updateTextInput(session,     "login_password", value = creds$password)
    }
  })

  # ── LOGIN HANDLER ────────────────────────────────────────────────────────
  observeEvent(input$btn_login, {
    req(input$login_email, input$login_password)
    user <- tryCatch(
      authenticate_user(trimws(input$login_email), trimws(input$login_password)),
      error = function(e) NULL
    )
    if (is.null(user)) {
      output$login_error <- renderUI({
        div(class = "login-error-box",
          "Invalid email or password. Please verify your credentials.")
      })
    } else {
      output$login_error <- renderUI(NULL)
      user_session$user  <- user
      switch(user$role,
        student = studentPortalServer("student_mod", user, logout_trigger),
        faculty = facultyPortalServer("faculty_mod", user, logout_trigger),
        admin   = adminPortalServer("admin_mod",    user, logout_trigger)
      )
    }
  })

  # ── SIGNUP HANDLER ───────────────────────────────────────────────────────
  observeEvent(input$btn_signup, {
    name  <- if (is.null(input$signup_name)) "" else trimws(input$signup_name)
    email <- if (is.null(input$signup_email)) "" else trimws(input$signup_email)
    dept  <- if (is.null(input$signup_dept)) "" else trimws(input$signup_dept)
    sem   <- if (is.null(input$signup_semester)) "" else trimws(input$signup_semester)
    pwd   <- if (is.null(input$signup_password)) "" else trimws(input$signup_password)
    pwd_c <- if (is.null(input$signup_password_confirm)) "" else trimws(input$signup_password_confirm)

    if (name == "") {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "Please enter your full name.")
      })
      return()
    }
    if (email == "") {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "Please enter your university email address.")
      })
      return()
    }
    if (!grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", email)) {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "Please enter a valid university email format.")
      })
      return()
    }
    if (pwd == "") {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "Please enter a secure password.")
      })
      return()
    }
    if (nchar(pwd) < 4) {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "Password must be at least 4 characters long.")
      })
      return()
    }
    if (pwd != pwd_c) {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "Passwords do not match. Please re-enter.")
      })
      return()
    }

    res <- register_user(
      name = name,
      email = email,
      password = pwd,
      department = dept,
      semester = sem,
      role = "student"
    )

    if (!isTRUE(res$success)) {
      output$signup_error <- renderUI({
        div(class = "login-error-box", res$message)
      })
    } else {
      output$signup_error <- renderUI(NULL)
      showNotification(sprintf("Account created successfully. Welcome, %s!", name), type = "message", duration = 4)
      user_session$user <- res$user
      studentPortalServer("student_mod", res$user, logout_trigger)
    }
  })
}

shinyApp(ui, server)
