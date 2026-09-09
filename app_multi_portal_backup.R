# app.R — Campus Listen | College Feedback Sentiment Tool
# Login router dispatching to Student, Faculty, or Admin portal

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

# ── SHARED CSS ────────────────────────────────────────────────────────────────
SHARED_CSS <- "

  /* ================================================================
     GLOBAL RESET & FONT STYLING — Inter Institutional Theme
  ================================================================ */
  html {
    font-size: 100% !important;
  }
  *, *::before, *::after { box-sizing: border-box; }
  body {
    margin: 0; padding: 0;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    font-size: 0.95rem !important;
    line-height: 1.5;
    background-color: #f1f5f9;
    color: #0f172a;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }

  /* ================================================================
     ENTRANCE ANIMATIONS — matching Framer
  ================================================================ */
  @keyframes cl-fadeSlideUp {
    from { opacity: 0; transform: translateY(16px); }
    to   { opacity: 1; transform: translateY(0); }
  }
  @keyframes cl-fadeIn {
    from { opacity: 0; }
    to   { opacity: 1; }
  }

  /* ================================================================
     SPLIT-SCREEN WRAPPER
  ================================================================ */
  .login-page {
    display: flex;
    min-height: 100vh;
    width: 100%;
    overflow: hidden;
  }

  /* ================================================================
     LEFT PANEL — deep forest green  #4272d7
  ================================================================ */
  .login-left {
    width: 40%;
    min-width: 340px;
    background: linear-gradient(160deg, #1e3a8a 0%, #1e40af 60%, #2563eb 100%);
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: 40px 48px;
    position: relative;
    overflow: hidden;
    flex-shrink: 0;
  }

  /* Brand row */
  .cl-brand {
    display: flex;
    align-items: center;
    gap: 14px;
    animation: cl-fadeSlideUp 0.55s cubic-bezier(0.22,1,0.36,1) 0.05s both;
  }
  .cl-brand-icon {
    width: 40px; height: 40px;
    border: 1.5px solid rgba(255,255,255,0.28);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .cl-brand-text { display: flex; flex-direction: column; gap: 2px; }
  .cl-brand-name {
    color: #fff;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    line-height: 1;
  }
  .cl-brand-sub {
    color: rgba(255,255,255,0.35);
    font-size: 10px;
    letter-spacing: 0.02em;
    line-height: 1;
  }

  /* Headline block */
  .cl-headline-block {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    padding: 48px 0;
  }
  .cl-overline {
    color: rgba(255,255,255,0.35);
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    margin-bottom: 20px;
    animation: cl-fadeSlideUp 0.6s cubic-bezier(0.22,1,0.36,1) 0.15s both;
  }
  .cl-headline {
    font-family: 'Inter', -apple-system, sans-serif;
    font-size: clamp(1.8rem, 3vw, 2.6rem);
    font-weight: 700;
    font-style: normal;
    color: #fff;
    line-height: 1.18;
    margin: 0 0 20px 0;
    letter-spacing: -0.03em;
    animation: cl-fadeSlideUp 0.65s cubic-bezier(0.22,1,0.36,1) 0.22s both;
  }
  .cl-subtext {
    color: rgba(255,255,255,0.42);
    font-size: 14px;
    line-height: 1.65;
    max-width: 295px;
    animation: cl-fadeSlideUp 0.65s cubic-bezier(0.22,1,0.36,1) 0.3s both;
  }

  /* Left footer */
  .cl-left-footer {
    border-top: 1px solid rgba(255,255,255,0.08);
    padding-top: 20px;
    color: rgba(255,255,255,0.26);
    font-size: 11.5px;
    line-height: 1.5;
    animation: cl-fadeIn 0.8s ease 0.5s both;
  }

  /* ================================================================
     RIGHT PANEL — warm ivory  #ffffff
  ================================================================ */
  .login-right {
    flex: 1;
    background-color: #ffffff;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: center;
    padding: 60px 80px;
    min-height: 100vh;
  }

  /* ================================================================
     LOGIN CARD — floats on ivory, left-aligned, barely visible border
  ================================================================ */
  .login-card {
    background: #ffffff;
    border: 1px solid #e5e5e5;
    border-radius: 18px;
    padding: 36px 36px;
    width: 100%;
    max-width: 470px;
    box-shadow: 0 2px 20px -4px rgba(13,43,31,0.07), 0 1px 3px rgba(13,43,31,0.04);
    animation: cl-fadeSlideUp 0.65s cubic-bezier(0.22,1,0.36,1) 0.1s both;
  }

  /* Overline */
  .login-card-overline {
    display: block;
    color: #4272d7;
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    margin-bottom: 10px;
  }

  /* Title */
  .login-card-title {
    font-family: 'Inter', sans-serif;
    font-size: 1.75rem;
    font-weight: 700;
    color: #0f172a;
    margin: 0 0 8px 0;
    line-height: 1.2;
    letter-spacing: -0.02em;
  }

  /* Description */
  .login-card-desc {
    color: #7c7973;
    font-size: 13.5px;
    line-height: 1.6;
    margin-bottom: 22px;
    max-width: 380px;
  }

  /* Labels */
  .login-card label,
  .login-card .control-label {
    display: block;
    color: #374151;
    font-size: 13px;
    font-weight: 600;
    margin-bottom: 6px;
    letter-spacing: 0;
    text-transform: none !important;
  }

  /* Inputs — match reference cream tone */
  .login-card .form-control,
  .login-card input[type=text],
  .login-card input[type=email],
  .login-card input[type=password],
  .login-card select {
    background: #f8fafc !important;
    border: 1px solid #e2e8f0 !important;
    border-radius: 8px !important;
    color: #0f172a !important;
    font-size: 14px !important;
    font-family: 'Inter', sans-serif !important;
    padding: 11px 14px !important;
    width: 100% !important;
    box-shadow: none !important;
    transition: border-color 0.18s ease, background 0.18s ease !important;
    outline: none !important;
    -webkit-appearance: none !important;
  }
  .login-card .form-control::placeholder,
  .login-card input::placeholder {
    color: #ada9a0 !important;
    font-size: 14px !important;
  }
  .login-card .form-control:hover {
    border-color: #b8b4ab !important;
  }
  .login-card .form-control:focus,
  .login-card input:focus {
    border-color: #4272d7 !important;
    box-shadow: none !important;
    background: #ffffff !important;
    outline: none !important;
  }
  .login-card .form-group { margin-bottom: 16px; }

  /* Sign in button */
  .btn-login {
    width: 100% !important;
    background: #1e40af !important;
    color: #fff !important;
    border: none !important;
    border-radius: 8px !important;
    padding: 13px 20px !important;
    font-size: 14px !important;
    font-weight: 600 !important;
    font-family: 'Inter', sans-serif !important;
    letter-spacing: 0.01em !important;
    cursor: pointer !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    gap: 8px !important;
    margin-top: 10px !important;
    transition: background-color 0.18s ease !important;
    box-shadow: none !important;
    line-height: 1 !important;
  }
  .btn-login:hover {
    background: #1d4ed8 !important;
    box-shadow: none !important;
    transform: none !important;
  }
  .btn-login:active {
    background: #1e3a8a !important;
    transform: none !important;
  }
  .btn-login:focus {
    outline: none !important;
    box-shadow: none !important;
  }

  /* Forgot password text */
  .login-forgot {
    margin-top: 15px;
    color: #9a9790;
    font-size: 12.5px;
    line-height: 1.55;
    text-align: left;
  }

  /* Privacy banner — soft green tint */
  .login-privacy {
    margin-top: 20px;
    background: #f3f5f9;
    color: #4272d7;
    font-size: 12px;
    font-weight: 500;
    padding: 11px 15px;
    border-radius: 8px;
    text-align: center;
    border: none;
    line-height: 1.4;
  }

  /* Demo credentials */
  .demo-creds {
    margin-top: 14px;
    padding: 11px 15px;
    background: rgba(13,43,31,0.05);
    border-radius: 10px;
    border: 1px solid rgba(13,43,31,0.08);
    width: 100%;
    max-width: 440px;
    animation: cl-fadeIn 0.8s ease 0.4s both;
  }
  .demo-creds p { margin: 0; color: #6b6964; font-size: 11.5px; line-height: 1.8; }
  .demo-creds strong { color: #2e2e2b; }

  /* Secure workspace footer */
  .login-secure-footer {
    margin-top: 13px;
    display: flex;
    align-items: center;
    gap: 5px;
    color: #b0aca4;
    font-size: 11.5px;
    animation: cl-fadeIn 0.8s ease 0.5s both;
  }

  /* Login error box */
  .login-error-box {
    margin-top: 10px;
    padding: 10px 14px;
    background: rgba(200,50,50,0.07);
    border: 1px solid rgba(200,50,50,0.18);
    border-radius: 8px;
    color: #b83232;
    font-size: 13px;
    text-align: center;
    line-height: 1.4;
  }

  /* Login success box */
  .login-success-box {
    margin-top: 10px;
    padding: 10px 14px;
    background: #edf7ed;
    border: 1px solid #c8e6c9;
    border-radius: 8px;
    color: #1e6b24;
    font-size: 13px;
    text-align: center;
    line-height: 1.4;
  }

  /* Auth Mode Tab Bar */
  .auth-mode-bar {
    display: flex;
    background: #f1f3f7;
    border-radius: 10px;
    padding: 4px;
    margin-bottom: 22px;
    border: 1px solid #e2e5eb;
    width: 100%;
  }
  .auth-tab-btn {
    flex: 1;
    padding: 9px 12px;
    text-align: center;
    border-radius: 7px;
    font-size: 13px;
    font-weight: 600;
    color: #64748b;
    background: transparent;
    border: none;
    cursor: pointer;
    transition: all 0.18s ease;
    font-family: 'Inter', sans-serif;
  }
  .auth-tab-btn:hover {
    color: #1e293b;
  }
  .auth-tab-btn.active {
    background: #ffffff;
    color: #4272d7;
    font-weight: 700;
    box-shadow: 0 2px 6px rgba(0,0,0,0.07);
  }

  /* Auth switcher bottom prompt */
  .auth-switch-prompt {
    margin-top: 18px;
    text-align: center;
    font-size: 13px;
    color: #64748b;
  }
  .auth-switch-action {
    color: #1e40af;
    font-weight: 600;
    cursor: pointer;
    background: none;
    border: none;
    padding: 0 4px;
    font-size: 13px;
    text-decoration: underline;
    font-family: 'Inter', sans-serif;
  }
  .auth-switch-action:hover {
    color: #2b55b3;
  }

  /* ================================================================
     PORTAL BODY — warm ivory light theme (matches login)
  ================================================================ */
  .portal-body {
    background-color: #f1f5f9;
    background-image: none;
    min-height: 100vh;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    color: #0f172a;
  }

  /* Top nav bar */
  .portal-body .portal-topbar {
    background: #ffffff !important;
    border: 1px solid #e5e5e5 !important;
    border-radius: 12px !important;
  }
  .portal-body .portal-topbar-brand { color: #4272d7 !important; }
  .portal-body .portal-topbar-user  { color: #000000 !important; font-weight: 700 !important; }

  /* Glass cards → light cards */
  .portal-body .glass-card {
    background: #ffffff !important;
    border: 1px solid #e5e5e5 !important;
    border-radius: 14px !important;
    backdrop-filter: none !important;
    box-shadow: 0 2px 16px -4px rgba(13,43,31,0.07), 0 1px 3px rgba(13,43,31,0.04) !important;
    transition: border-color 0.18s, box-shadow 0.18s !important;
  }
  .portal-body .glass-card:hover {
    border-color: #c8c3b8 !important;
    box-shadow: 0 4px 22px -6px rgba(13,43,31,0.1), 0 1px 4px rgba(13,43,31,0.05) !important;
  }

  /* Headings inside portal */
  .portal-body h2, .portal-body h3, .portal-body h4, .portal-body h5, .portal-body h6 {
    color: #4272d7 !important;
    background: none !important;
    -webkit-text-fill-color: unset !important;
  }
  .portal-body p, .portal-body span, .portal-body label { color: #4a4845 !important; }

  /* Subtitle / muted text */
  .portal-body [style*='color:#94a3b8'],
  .portal-body [style*='color: #94a3b8'],
  .portal-body [style*='color:#64748b'],
  .portal-body [style*='color: #64748b'] {
    color: #7c7973 !important;
  }

  /* White / near-white text → dark */
  .portal-body [style*='color:#f8fafc'],
  .portal-body [style*='color: #f8fafc'],
  .portal-body [style*='color:#cbd5e1'],
  .portal-body [style*='color: #cbd5e1'] {
    color: #4272d7 !important;
  }

  /* Role badges */
  .portal-body .badge-student { background:rgba(59,130,246,0.1); color:#2563eb; border:1px solid rgba(59,130,246,0.25); }
  .portal-body .badge-faculty { background:rgba(16,185,129,0.1); color:#047857; border:1px solid rgba(66,114,215,0.25); }
  .portal-body .badge-admin   { background:rgba(180,130,0,0.1);  color:#92400e; border:1px solid rgba(180,130,0,0.25); }

  /* Tab panels */
  .portal-body .nav-tabs { border-bottom: 2px solid #e5e5e5 !important; }
  .portal-body .nav-tabs .nav-link {
    color: #7c7973 !important;
    background: transparent !important;
    border: none !important;
    border-bottom: 2px solid transparent !important;
    border-radius: 0 !important;
    font-weight: 500 !important;
    padding: 10px 18px !important;
    margin-bottom: -2px !important;
    transition: color 0.15s, border-color 0.15s !important;
  }
  .portal-body .nav-tabs .nav-link:hover { color: #4272d7 !important; }
  .portal-body .nav-tabs .nav-link.active {
    color: #4272d7 !important;
    border-bottom-color: #4272d7 !important;
    font-weight: 700 !important;
    background: transparent !important;
  }
  .portal-body .tab-content { background: transparent !important; }

  /* Inputs, selects, textareas in portal */
  .portal-body .form-control,
  .portal-body input[type=text],
  .portal-body input[type=number],
  .portal-body textarea,
  .portal-body select {
    background: #ffffff !important;
    border: 1px solid #e5e5e5 !important;
    border-radius: 8px !important;
    color: #333333 !important;
    box-shadow: none !important;
  }
  .portal-body .form-control:focus,
  .portal-body input:focus,
  .portal-body textarea:focus,
  .portal-body select:focus {
    border-color: #4272d7 !important;
    box-shadow: none !important;
    background: #ffffff !important;
    outline: none !important;
  }

  /* Selectize (custom dropdowns) */
  .portal-body .selectize-input {
    background: #ffffff !important;
    border: 1px solid #e5e5e5 !important;
    color: #333333 !important;
    border-radius: 8px !important;
    box-shadow: none !important;
  }
  .portal-body .selectize-dropdown {
    background: #ffffff !important;
    border: 1px solid #e5e5e5 !important;
    color: #333333 !important;
    box-shadow: 0 4px 20px rgba(13,43,31,0.1) !important;
  }
  .portal-body .selectize-dropdown .option:hover,
  .portal-body .selectize-dropdown .option.active {
    background: #f3f5f9 !important;
    color: #4272d7 !important;
  }

  /* Sliders */
  .portal-body .irs--shiny .irs-bar { background: #4272d7 !important; border-color: #4272d7 !important; }
  .portal-body .irs--shiny .irs-handle { border-color: #4272d7 !important; }
  .portal-body .irs--shiny .irs-from,
  .portal-body .irs--shiny .irs-to,
  .portal-body .irs--shiny .irs-single { background: #4272d7 !important; }
  .portal-body .irs--shiny .irs-line { background: #e0dbd1 !important; }
  .portal-body .irs-min, .portal-body .irs-max { color: #7c7973 !important; }
  .portal-body .irs-grid-text { color: #7c7973 !important; }

  /* Buttons */
  .portal-body .btn-primary {
    background: #4272d7 !important;
    border-color: #4272d7 !important;
    color: #fff !important;
    border-radius: 8px !important;
    box-shadow: none !important;
  }
  .portal-body .btn-primary:hover { background: #3868cd !important; border-color: #3868cd !important; }

  .portal-body .btn-warning {
    background: #92400e !important;
    border-color: #92400e !important;
    color: #fff !important;
    border-radius: 8px !important;
  }
  .portal-body .btn-warning:hover { background: #78350f !important; }

  .portal-body .btn-outline-secondary {
    background: transparent !important;
    border-color: #e5e5e5 !important;
    color: #4a4845 !important;
    border-radius: 8px !important;
  }
  .portal-body .btn-outline-secondary:hover {
    background: #e0dbd1 !important;
    color: #4272d7 !important;
  }

  /* Download buttons */
  .portal-body .btn[style*='color:#3b82f6'] {
    background: rgba(37,99,235,0.08) !important;
    border-color: #2563eb !important;
    color: #2563eb !important;
    border-radius: 8px !important;
  }
  .portal-body .btn[style*='color:#dc2626'] {
    background: rgba(220,38,38,0.08) !important;
    border-color: #dc2626 !important;
    color: #dc2626 !important;
    border-radius: 8px !important;
  }

  /* DataTables */
  .portal-body .dataTable,
  .portal-body .dataTable th,
  .portal-body .dataTable td {
    background: transparent !important;
    color: #333333 !important;
    border-color: #e0dbd1 !important;
  }
  .portal-body .dataTable th {
    background: #f5f5f5 !important;
    color: #4272d7 !important;
    font-weight: 600 !important;
  }
  .portal-body .dataTable tbody tr:hover td { background: #f3f5f9 !important; }
  .portal-body .dataTables_wrapper .dataTables_filter input,
  .portal-body .dataTables_wrapper select {
    background: #ffffff !important;
    border: 1px solid #e5e5e5 !important;
    color: #333333 !important;
    border-radius: 8px !important;
  }
  .portal-body .dataTables_info,
  .portal-body .dataTables_length label,
  .portal-body .dataTables_filter label { color: #7c7973 !important; }
  .portal-body .paginate_button { color: #4272d7 !important; }
  .portal-body .paginate_button.current { background: #4272d7 !important; color: #fff !important; border-radius: 6px !important; }

  /* Alert / success / error banners */
  .portal-body [style*='background:rgba(16,185,129'] { background: rgba(5,150,105,0.08) !important; }
  .portal-body [style*='background:rgba(239,68,68']  { background: rgba(220,38,38,0.08) !important; }
  .portal-body [style*='color:#4272d7'] { color: #047857 !important; }
  .portal-body [style*='color:#ef4444'] { color: #b91c1c !important; }
  .portal-body [style*='color:#f59e0b'] { color: #b45309 !important; }

  /* NLP highlight cards */
  .portal-body [style*='background:rgba(59,130,246,0.07)'] {
    background: rgba(13,43,31,0.05) !important;
    border-left-color: #4272d7 !important;
  }
  .portal-body [style*='color:#cbd5e1'] { color: #333333 !important; }

  /* Checkbox */
  .portal-body input[type=checkbox]:checked { accent-color: #4272d7; }

  /* Plotly charts — override transparent bg for light mode */
  .portal-body .js-plotly-plot .plotly { background: transparent !important; }

  /* Plotly charts — override transparent bg for light mode */
  .portal-body .js-plotly-plot .plotly { background: transparent !important; }

  /* ================================================================
     STUDENT PORTAL — WARM IVORY & DEEP FOREST GREEN (matches Admin)
  ================================================================ */
  .student-portal-wrapper {
    max-width: 960px;
    margin: 0 auto;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  }

  /* Cards */
  .student-portal-wrapper .glass-card {
    background: #ffffff !important;
    border: 1px solid #e2e8f0 !important;
    border-radius: 12px !important;
    box-shadow: 0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04) !important;
    padding: 24px 28px !important;
    transition: border-color 0.18s ease, box-shadow 0.18s ease !important;
  }
  .student-portal-wrapper .glass-card:hover {
    border-color: #cbd5e1 !important;
    box-shadow: 0 4px 12px rgba(0,0,0,0.08) !important;
  }

  /* ── MAIN PORTAL TITLE */
  .student-portal-wrapper .student-main-title {
    font-family: 'Inter', sans-serif !important;
    font-size: 1.6rem !important;
    font-weight: 700 !important;
    font-style: normal !important;
    color: #0f172a !important;
    margin: 0 0 6px 0 !important;
    letter-spacing: -0.025em !important;
    line-height: 1.2 !important;
    padding-left: 14px !important;
    border-left: 3px solid #1e40af !important;
  }
  .student-portal-wrapper .student-main-sub {
    font-size: 0.85rem !important;
    color: #64748b !important;
    margin: 0 !important;
    padding-left: 18px !important;
  }

  /* ── SECTION TITLES */
  .student-portal-wrapper .student-section-title {
    font-family: 'Inter', sans-serif !important;
    font-size: 1.05rem !important;
    font-weight: 700 !important;
    color: #0f172a !important;
    margin-bottom: 16px !important;
    padding-bottom: 12px !important;
    display: flex !important;
    align-items: center !important;
    gap: 10px !important;
    position: relative !important;
    border-bottom: none !important;
  }
  /* Double-rule decorative underline */
  .student-portal-wrapper .student-section-title::after {
    content: '' !important;
    position: absolute !important;
    bottom: 0 !important;
    left: 0 !important;
    width: 100% !important;
    height: 1px !important;
    background: linear-gradient(90deg, #4272d7 0%, #4272d7 40%, transparent 100%) !important;
  }

  /* ── SUB-LABELS — olive green uppercase badge style */
  .student-portal-wrapper .student-sub-title {
    font-size: 0.78rem !important;
    font-weight: 800 !important;
    color: #4272d7 !important;
    text-transform: uppercase !important;
    letter-spacing: 0.1em !important;
    margin-bottom: 12px !important;
    display: flex !important;
    align-items: center !important;
    gap: 6px !important;
    background: #f3f5f9 !important;
    border-radius: 6px !important;
    padding: 5px 10px !important;
    width: fit-content !important;
  }

  /* Input Labels */
  .student-portal-wrapper .control-label,
  .student-portal-wrapper label {
    color: #374151 !important;
    font-weight: 600 !important;
    font-size: 0.88rem !important;
    margin-bottom: 5px !important;
  }

  /* Inputs & Textareas — exact match to admin portal */
  .student-portal-wrapper textarea,
  .student-portal-wrapper input[type=text],
  .student-portal-wrapper select,
  .student-portal-wrapper .form-control {
    background: #ffffff !important;
    color: #333333 !important;
    border: 1px solid #e5e5e5 !important;
    border-radius: 8px !important;
    font-size: 0.93rem !important;
    line-height: 1.5 !important;
    padding: 11px 14px !important;
    outline: none !important;
    transition: all 0.18s ease !important;
    box-shadow: none !important;
  }
  .student-portal-wrapper textarea::placeholder,
  .student-portal-wrapper input::placeholder {
    color: #ada9a0 !important;
    font-style: italic !important;
  }
  .student-portal-wrapper textarea:focus,
  .student-portal-wrapper input:focus,
  .student-portal-wrapper select:focus,
  .student-portal-wrapper .form-control:focus {
    background: #ffffff !important;
    border-color: #4272d7 !important;
    box-shadow: 0 0 0 3px rgba(13,43,31,0.12) !important;
    outline: none !important;
  }

  /* Sliders — matching admin deep forest green */
  .student-portal-wrapper .irs--shiny .irs-line {
    background: #e0dbd1 !important;
    height: 7px !important;
    border-radius: 4px !important;
  }
  .student-portal-wrapper .irs--shiny .irs-bar {
    background: #4272d7 !important;
    border: none !important;
    height: 7px !important;
    border-radius: 4px !important;
  }
  .student-portal-wrapper .irs--shiny .irs-handle {
    background: #4272d7 !important;
    border: 2.5px solid #ffffff !important;
    width: 20px !important;
    height: 20px !important;
    top: 22px !important;
    box-shadow: 0 2px 8px rgba(13,43,31,0.25) !important;
    cursor: pointer !important;
  }
  .student-portal-wrapper .irs--shiny .irs-single {
    background: #4272d7 !important;
    color: #ffffff !important;
    font-weight: 700 !important;
    font-size: 12px !important;
    border-radius: 6px !important;
    padding: 3px 8px !important;
    box-shadow: 0 2px 8px rgba(13,43,31,0.2) !important;
  }
  .student-portal-wrapper .irs-min,
  .student-portal-wrapper .irs-max,
  .student-portal-wrapper .irs-grid-text {
    color: #7c7973 !important;
    font-weight: 600 !important;
    font-size: 11px !important;
  }

  /* Sticky Progress Header — ivory matching admin card */
  .student-sticky-header {
    position: sticky;
    top: 12px;
    z-index: 100;
    background: #ffffff;
    border: 1px solid #e5e5e5;
    border-left: 4px solid #4272d7;
    border-radius: 12px;
    padding: 14px 22px;
    box-shadow: 0px 2px 5px 0px rgba(0, 0, 0, 0.1);
    margin-bottom: 22px;
  }

  /* Step Indicator Pills — ivory + forest green */
  .student-step-pill {
    background: #ffffff;
    color: #4272d7;
    border: 1px solid #e5e5e5;
    border-radius: 9999px;
    padding: 6px 14px;
    font-size: 0.8rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.18s ease;
    display: inline-flex;
    align-items: center;
    gap: 5px;
  }
  .student-step-pill:hover {
    background: #f3f5f9;
    color: #4272d7;
    border-color: #e5e5e5;
  }
  .student-step-pill.active {
    background: #4272d7 !important;
    color: #ffffff !important;
    font-weight: 800 !important;
    border-color: #4272d7 !important;
    box-shadow: 0 3px 12px rgba(13,43,31,0.22) !important;
  }
  .student-step-pill.completed {
    background: #f3f5f9;
    color: #4272d7;
    border-color: #e5e5e5;
    font-weight: 700;
  }

  /* Responsive Adjustments */
  @media (max-width: 900px) {
    .login-page  { flex-direction: column; }
    .login-left  { width: 100%; min-width: unset; min-height: 260px; padding: 36px 32px; }
    .login-right { width: 100%; padding: 40px 24px; align-items: center; }
    .login-card  { padding: 36px 28px; }
    .demo-creds  { max-width: 440px; }
    .cl-headline { font-size: 2rem; }
  }
"

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "preconnect", href = "https://fonts.gstatic.com", crossorigin = NA),
    tags$link(
      href = "https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap",
      rel = "stylesheet"
    ),
    tags$style(HTML(SHARED_CSS)),
    tags$title("Campus Listen — College Feedback Sentiment Tool")
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

      # ── LOGIN / SIGNUP PAGE — pixel-perfect Campus Listen reference ─────────
      div(class = "login-page",

        # ── LEFT PANEL ──────────────────────────────────────────────────
        div(class = "login-left",

          # Brand / logo
          div(class = "cl-brand",
            div(class = "cl-brand-icon",
              tags$svg(
                xmlns = "http://www.w3.org/2000/svg", viewBox = "0 0 24 24",
                style = "width:18px;height:18px;fill:none;stroke:rgba(255,255,255,0.85);stroke-width:2;stroke-linecap:round;stroke-linejoin:round;",
                tags$path(d = "M22 10v6M2 10l10-5 10 5-10 5z"),
                tags$path(d = "M6 12v5c3 3 9 3 12 0v-5")
              )
            ),
            div(class = "cl-brand-text",
              div(class = "cl-brand-name", "Campus Listen"),
              div(class = "cl-brand-sub",  "College Feedback Sentiment Tool")
            )
          ),

          # Headline block
          div(class = "cl-headline-block",
            div(class = "cl-overline", "Student Feedback Platform"),
            tags$h1(class = "cl-headline", "Insight for a stronger campus."),
            div(class = "cl-subtext",
              "A secure workspace to gather student feedback and understand campus sentiment."
            )
          ),

          # Footer
          div(class = "cl-left-footer",
            "Your identity is protected. Your perspective matters."
          )
        ),

        # ── RIGHT PANEL ─────────────────────────────────────────────────
        div(class = "login-right",

          # Login / Signup Card
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
                tags$span(class = "login-card-overline", "Secure Campus Access"),
                tags$h2(class = "login-card-title", "Welcome back."),
                div(class = "login-card-desc",
                  "Sign in with your college email to continue to the feedback workspace."
                ),

                textInput("login_email", "College email",
                  placeholder = "you@college.edu", width = "100%"),
                passwordInput("login_password", "Password",
                  placeholder = "Enter your password", width = "100%"),

                actionButton("btn_login",
                  label = HTML("Sign in securely &nbsp;<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' style='width:14px;height:14px;fill:none;stroke:rgba(255,255,255,0.75);stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle;'><rect x='3' y='11' width='18' height='11' rx='2' ry='2'/><path d='M7 11V7a5 5 0 0 1 10 0v4'/></svg>"),
                  class = "btn-login"
                ),

                uiOutput("login_error"),

                div(class = "auth-switch-prompt",
                  "Don't have an account? ",
                  tags$button(
                    class = "auth-switch-action",
                    onclick = "Shiny.setInputValue('switch_auth', 'signup', {priority:'event'})",
                    "Sign up here"
                  )
                ),

                div(class = "login-forgot",
                  "Forgot your password? Contact your college administrator."
                ),

                div(class = "login-privacy",
                  "Private by design — feedback is handled with care."
                )
              )
            } else {
              # ── SIGN UP FORM ───────────────────────────────────────────────
              tagList(
                tags$span(class = "login-card-overline", "Student Registration"),
                tags$h2(class = "login-card-title", "Create Account."),
                div(class = "login-card-desc",
                  "Register with your email, department, and current semester."
                ),

                textInput("signup_name", "Full Name",
                  placeholder = "e.g. Alex Kumar", width = "100%"),

                textInput("signup_email", "College Email",
                  placeholder = "you@college.edu", width = "100%"),

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
                  placeholder = "Choose a password (min. 4 chars)", width = "100%"),

                passwordInput("signup_password_confirm", "Confirm Password",
                  placeholder = "Confirm your password", width = "100%"),

                actionButton("btn_signup",
                  label = HTML("Create Student Account &nbsp;<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' style='width:14px;height:14px;fill:none;stroke:rgba(255,255,255,0.75);stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle;'><path d='M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2'/><circle cx='8.5' cy='7' r='4'/><line x1='20' y1='8' x2='20' y2='14'/><line x1='23' y1='11' x2='17' y2='11'/></svg>"),
                  class = "btn-login"
                ),

                uiOutput("signup_error"),

                div(class = "auth-switch-prompt",
                  "Already have an account? ",
                  tags$button(
                    class = "auth-switch-action",
                    onclick = "Shiny.setInputValue('switch_auth', 'login', {priority:'event'})",
                    "Sign in here"
                  )
                ),

                div(class = "login-privacy",
                  "Your account is registered as Student for academic course reviews."
                )
              )
            }
          ),

          # Demo credentials — shown on login view
          if (auth_mode() == "login") {
            div(class = "demo-creds",
              p(style = "font-size:0.78rem; font-weight:700; color:#7c7973; text-transform:uppercase; letter-spacing:0.08em; margin-bottom:10px;",
                "Quick Login — Click to fill"),
              div(style = "display:flex; gap:8px; flex-wrap:wrap;",
                tags$button(
                  onclick = "Shiny.setInputValue('fill_demo', 'student', {priority:'event'})",
                  style = "flex:1; padding:8px 12px; border-radius:8px; border:1px solid #e5e5e5; background:#ffffff; color:#4272d7; font-size:0.82rem; font-weight:700; cursor:pointer;",
                  "🎓 Student"
                ),
                tags$button(
                  onclick = "Shiny.setInputValue('fill_demo', 'faculty', {priority:'event'})",
                  style = "flex:1; padding:8px 12px; border-radius:8px; border:1px solid #e5e5e5; background:#ffffff; color:#4272d7; font-size:0.82rem; font-weight:700; cursor:pointer;",
                  "🧑‍🏫 Faculty"
                ),
                tags$button(
                  onclick = "Shiny.setInputValue('fill_demo', 'admin', {priority:'event'})",
                  style = "flex:1; padding:8px 12px; border-radius:8px; border:1px solid #e5e5e5; background:#ffffff; color:#4272d7; font-size:0.82rem; font-weight:700; cursor:pointer;",
                  "🏛 Admin"
                )
              )
            )
          },

          # Secure footer
          div(class = "login-secure-footer",
            tags$svg(
              xmlns = "http://www.w3.org/2000/svg", viewBox = "0 0 24 24",
              style = "width:12px;height:12px;fill:none;stroke:#b0aca4;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;",
              tags$path(d = "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z")
            ),
            tags$span("Secure feedback workspace")
          )
        )
      )

    } else {
      # ── PORTAL DISPATCH ───────────────────────────────────────────────
      u <- user_session$user
      role_badge <- switch(u$role,
        student = tags$span(class = "role-badge badge-student", "\U0001F393 Student"),
        faculty = tags$span(class = "role-badge badge-faculty", "\U0001F9D1\u200D\U0001F3EB Faculty"),
        admin   = tags$span(class = "role-badge badge-admin",   "\U0001F3DB\uFE0F Admin")
      )

      max_width <- if (u$role == "admin") "100%" else "1200px"
      padding_val <- if (u$role == "admin") "28px 32px" else "28px 18px"
      
      div(class = "portal-body",
        div(style = sprintf("max-width:%s; margin:0 auto; padding:%s;", max_width, padding_val),
          div(class = "portal-topbar",
            style = "display:flex; align-items:center; gap:12px; margin-bottom:24px; padding:10px 18px;",
            div(class = "portal-topbar-brand",
              style = "font-weight:800; font-size:1.05rem; display:flex; align-items:center; gap:8px;",
              tags$svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 24 24",
                style="width:18px;height:18px;fill:none;stroke:#4272d7;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;",
                tags$path(d="M22 10v6M2 10l10-5 10 5-10 5z"),
                tags$path(d="M6 12v5c3 3 9 3 12 0v-5")
              ),
              "Campus Listen"
            ),
            div(style = "width:1px; height:18px; background:#e5e5e5;"),
            role_badge,
            div(style = "flex:1;"),
            div(class = "portal-topbar-user",
              style = "font-size:0.85rem;", paste0("Welcome, ", u$name))
          ),
          switch(u$role,
            student = studentPortalUI("student_mod"),
            faculty = facultyPortalUI("faculty_mod"),
            admin   = adminPortalUI("admin_mod")
          )
        )
      )
    }
  })

  # ── DEMO QUICK-FILL HANDLER ──────────────────────────────────────────────
  observeEvent(input$fill_demo, {
    creds <- switch(input$fill_demo,
      student = list(email = "alex@college.edu",    password = "student123"),
      faculty = list(email = "sunita@college.edu",  password = "faculty123"),
      admin   = list(email = "admin@college.edu",   password = "admin123"),
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
          "❌ Invalid email or password. Please try again.")
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
        div(class = "login-error-box", "❌ Please enter your full name.")
      })
      return()
    }
    if (email == "") {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "❌ Please enter your college email address.")
      })
      return()
    }
    if (!grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", email)) {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "❌ Please enter a valid email format (e.g., you@college.edu).")
      })
      return()
    }
    if (pwd == "") {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "❌ Please choose a password.")
      })
      return()
    }
    if (nchar(pwd) < 4) {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "❌ Password must be at least 4 characters long.")
      })
      return()
    }
    if (pwd != pwd_c) {
      output$signup_error <- renderUI({
        div(class = "login-error-box", "❌ Passwords do not match. Please verify.")
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
        div(class = "login-error-box", paste0("❌ ", res$message))
      })
    } else {
      output$signup_error <- renderUI(NULL)
      showNotification(sprintf("Welcome, %s! Your student account has been created.", name), type = "message", duration = 5)
      user_session$user <- res$user
      studentPortalServer("student_mod", res$user, logout_trigger)
    }
  })
}

shinyApp(ui, server)
