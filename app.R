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

# ── SHARED CSS ────────────────────────────────────────────────────────────────
SHARED_CSS <- "

  /* ================================================================
     GLOBAL RESET & MEDIUM FONT STYLING — Green & White Theme
  ================================================================ */
  html {
    font-size: 100% !important;
  }
  *, *::before, *::after { box-sizing: border-box; }
  body {
    margin: 0; padding: 0;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    font-size: 0.95rem !important;
    line-height: 1.5;
    background-color: #f4f7f5;
    color: #1c2a23;
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
     LEFT PANEL — deep forest green  #0d2b1f
  ================================================================ */
  .login-left {
    width: 40%;
    min-width: 340px;
    background-color: #0d2b1f;
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
    font-family: 'Playfair Display', Georgia, 'Times New Roman', serif;
    font-size: clamp(2rem, 3.4vw, 3rem);
    font-weight: 700;
    font-style: italic;
    color: #fff;
    line-height: 1.12;
    margin: 0 0 20px 0;
    letter-spacing: -0.01em;
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
     RIGHT PANEL — warm ivory  #f0ece4
  ================================================================ */
  .login-right {
    flex: 1;
    background-color: #f0ece4;
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
    background: #ede9e1;
    border: 1px solid #ddd9d0;
    border-radius: 18px;
    padding: 44px 40px;
    width: 100%;
    max-width: 440px;
    box-shadow: 0 2px 20px -4px rgba(13,43,31,0.07), 0 1px 3px rgba(13,43,31,0.04);
    animation: cl-fadeSlideUp 0.65s cubic-bezier(0.22,1,0.36,1) 0.1s both;
  }

  /* Overline */
  .login-card-overline {
    display: block;
    color: #5f8a74;
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    margin-bottom: 10px;
  }

  /* Title */
  .login-card-title {
    font-family: 'Playfair Display', Georgia, serif;
    font-size: 2.3rem;
    font-weight: 700;
    color: #0d2b1f;
    margin: 0 0 8px 0;
    line-height: 1.1;
    letter-spacing: -0.01em;
  }

  /* Description */
  .login-card-desc {
    color: #7c7973;
    font-size: 13.5px;
    line-height: 1.6;
    margin-bottom: 26px;
    max-width: 320px;
  }

  /* Labels */
  .login-card label,
  .login-card .control-label {
    display: block;
    color: #2a2926;
    font-size: 13.5px;
    font-weight: 600;
    margin-bottom: 7px;
    letter-spacing: 0;
    text-transform: none !important;
  }

  /* Inputs — match reference cream tone */
  .login-card .form-control,
  .login-card input[type=text],
  .login-card input[type=email],
  .login-card input[type=password] {
    background: #f5f2ec !important;
    border: 1px solid #cdc9c0 !important;
    border-radius: 8px !important;
    color: #1a1917 !important;
    font-size: 14px !important;
    font-family: 'Inter', sans-serif !important;
    padding: 13px 14px !important;
    width: 100% !important;
    box-shadow: none !important;
    transition: border-color 0.18s ease !important;
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
    border-color: #0d2b1f !important;
    box-shadow: none !important;
    background: #f5f2ec !important;
    outline: none !important;
  }
  .login-card .form-group { margin-bottom: 16px; }

  /* Sign in button — dark green, no shadow, subtle hover */
  .btn-login {
    width: 100% !important;
    background: #0d2b1f !important;
    color: #fff !important;
    border: none !important;
    border-radius: 8px !important;
    padding: 14px 20px !important;
    font-size: 14px !important;
    font-weight: 600 !important;
    font-family: 'Inter', sans-serif !important;
    letter-spacing: 0.005em !important;
    cursor: pointer !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    gap: 8px !important;
    margin-top: 8px !important;
    transition: background-color 0.18s ease !important;
    box-shadow: none !important;
    line-height: 1 !important;
  }
  .btn-login:hover {
    background: #163d2c !important;
    box-shadow: none !important;
    transform: none !important;
  }
  .btn-login:active {
    background: #0a2018 !important;
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
    background: #d8e6de;
    color: #2d4d3e;
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

  /* ================================================================
     PORTAL BODY — warm ivory light theme (matches login)
  ================================================================ */
  .portal-body {
    background-color: #f0ece4;
    background-image: none;
    min-height: 100vh;
    font-family: 'Inter', sans-serif;
    color: #1a1917;
  }

  /* Top nav bar */
  .portal-body .portal-topbar {
    background: #ede9e1 !important;
    border: 1px solid #ddd9d0 !important;
    border-radius: 12px !important;
  }
  .portal-body .portal-topbar-brand { color: #0d2b1f !important; }
  .portal-body .portal-topbar-user  { color: #000000 !important; font-weight: 700 !important; }

  /* Glass cards → light cards */
  .portal-body .glass-card {
    background: #ede9e1 !important;
    border: 1px solid #ddd9d0 !important;
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
    color: #0d2b1f !important;
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
    color: #0d2b1f !important;
  }

  /* Role badges */
  .portal-body .badge-student { background:rgba(59,130,246,0.1); color:#2563eb; border:1px solid rgba(59,130,246,0.25); }
  .portal-body .badge-faculty { background:rgba(16,185,129,0.1); color:#047857; border:1px solid rgba(16,185,129,0.25); }
  .portal-body .badge-admin   { background:rgba(180,130,0,0.1);  color:#92400e; border:1px solid rgba(180,130,0,0.25); }

  /* Tab panels */
  .portal-body .nav-tabs { border-bottom: 2px solid #ddd9d0 !important; }
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
  .portal-body .nav-tabs .nav-link:hover { color: #0d2b1f !important; }
  .portal-body .nav-tabs .nav-link.active {
    color: #0d2b1f !important;
    border-bottom-color: #0d2b1f !important;
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
    background: #f5f2ec !important;
    border: 1px solid #cdc9c0 !important;
    border-radius: 8px !important;
    color: #1a1917 !important;
    box-shadow: none !important;
  }
  .portal-body .form-control:focus,
  .portal-body input:focus,
  .portal-body textarea:focus,
  .portal-body select:focus {
    border-color: #0d2b1f !important;
    box-shadow: none !important;
    background: #f5f2ec !important;
    outline: none !important;
  }

  /* Selectize (custom dropdowns) */
  .portal-body .selectize-input {
    background: #f5f2ec !important;
    border: 1px solid #cdc9c0 !important;
    color: #1a1917 !important;
    border-radius: 8px !important;
    box-shadow: none !important;
  }
  .portal-body .selectize-dropdown {
    background: #f5f2ec !important;
    border: 1px solid #cdc9c0 !important;
    color: #1a1917 !important;
    box-shadow: 0 4px 20px rgba(13,43,31,0.1) !important;
  }
  .portal-body .selectize-dropdown .option:hover,
  .portal-body .selectize-dropdown .option.active {
    background: #d8e6de !important;
    color: #0d2b1f !important;
  }

  /* Sliders */
  .portal-body .irs--shiny .irs-bar { background: #0d2b1f !important; border-color: #0d2b1f !important; }
  .portal-body .irs--shiny .irs-handle { border-color: #0d2b1f !important; }
  .portal-body .irs--shiny .irs-from,
  .portal-body .irs--shiny .irs-to,
  .portal-body .irs--shiny .irs-single { background: #0d2b1f !important; }
  .portal-body .irs--shiny .irs-line { background: #e0dbd1 !important; }
  .portal-body .irs-min, .portal-body .irs-max { color: #7c7973 !important; }
  .portal-body .irs-grid-text { color: #7c7973 !important; }

  /* Buttons */
  .portal-body .btn-primary {
    background: #0d2b1f !important;
    border-color: #0d2b1f !important;
    color: #fff !important;
    border-radius: 8px !important;
    box-shadow: none !important;
  }
  .portal-body .btn-primary:hover { background: #163d2c !important; border-color: #163d2c !important; }

  .portal-body .btn-warning {
    background: #92400e !important;
    border-color: #92400e !important;
    color: #fff !important;
    border-radius: 8px !important;
  }
  .portal-body .btn-warning:hover { background: #78350f !important; }

  .portal-body .btn-outline-secondary {
    background: transparent !important;
    border-color: #cdc9c0 !important;
    color: #4a4845 !important;
    border-radius: 8px !important;
  }
  .portal-body .btn-outline-secondary:hover {
    background: #e0dbd1 !important;
    color: #0d2b1f !important;
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
    color: #1a1917 !important;
    border-color: #e0dbd1 !important;
  }
  .portal-body .dataTable th {
    background: #e8e4dc !important;
    color: #0d2b1f !important;
    font-weight: 600 !important;
  }
  .portal-body .dataTable tbody tr:hover td { background: #d8e6de !important; }
  .portal-body .dataTables_wrapper .dataTables_filter input,
  .portal-body .dataTables_wrapper select {
    background: #f5f2ec !important;
    border: 1px solid #cdc9c0 !important;
    color: #1a1917 !important;
    border-radius: 8px !important;
  }
  .portal-body .dataTables_info,
  .portal-body .dataTables_length label,
  .portal-body .dataTables_filter label { color: #7c7973 !important; }
  .portal-body .paginate_button { color: #0d2b1f !important; }
  .portal-body .paginate_button.current { background: #0d2b1f !important; color: #fff !important; border-radius: 6px !important; }

  /* Alert / success / error banners */
  .portal-body [style*='background:rgba(16,185,129'] { background: rgba(5,150,105,0.08) !important; }
  .portal-body [style*='background:rgba(239,68,68']  { background: rgba(220,38,38,0.08) !important; }
  .portal-body [style*='color:#10b981'] { color: #047857 !important; }
  .portal-body [style*='color:#ef4444'] { color: #b91c1c !important; }
  .portal-body [style*='color:#f59e0b'] { color: #b45309 !important; }

  /* NLP highlight cards */
  .portal-body [style*='background:rgba(59,130,246,0.07)'] {
    background: rgba(13,43,31,0.05) !important;
    border-left-color: #0d2b1f !important;
  }
  .portal-body [style*='color:#cbd5e1'] { color: #2a2926 !important; }

  /* Checkbox */
  .portal-body input[type=checkbox]:checked { accent-color: #0d2b1f; }

  /* Plotly charts — override transparent bg for light mode */
  .portal-body .js-plotly-plot .plotly { background: transparent !important; }

  /* Plotly charts — override transparent bg for light mode */
  .portal-body .js-plotly-plot .plotly { background: transparent !important; }

  /* ================================================================
     STUDENT PORTAL — RICH DARK FOREST GREEN & VIBRANT GRADIENT THEME
  ================================================================ */
  .student-portal-wrapper {
    max-width: 960px;
    margin: 0 auto;
    font-family: 'Inter', -apple-system, sans-serif;
  }

  /* Dark Glass Cards */
  .student-portal-wrapper .glass-card {
    background: #0d2b1f !important;
    border: 1px solid rgba(255, 255, 255, 0.16) !important;
    border-radius: 16px !important;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.28), inset 0 1px 0 rgba(255, 255, 255, 0.1) !important;
    padding: 24px 28px !important;
    transition: all 0.2s ease !important;
  }
  .student-portal-wrapper .glass-card:hover {
    border-color: rgba(16, 185, 129, 0.35) !important;
    box-shadow: 0 12px 36px rgba(0, 0, 0, 0.35), 0 0 15px rgba(16, 185, 129, 0.15) !important;
  }

  /* Stunning Vibrant Headings & Typography */
  .student-portal-wrapper .student-main-title {
    font-family: 'Playfair Display', Georgia, serif !important;
    font-size: 2.3rem !important;
    font-weight: 700 !important;
    background: linear-gradient(135deg, #ffffff 0%, #a7f3d0 50%, #38bdf8 100%) !important;
    -webkit-background-clip: text !important;
    -webkit-text-fill-color: transparent !important;
    margin: 0 0 4px 0 !important;
    letter-spacing: -0.01em !important;
  }
  .student-portal-wrapper .student-main-sub {
    font-size: 0.9rem !important;
    color: #cbd5e1 !important;
    margin: 0 !important;
  }

  /* Attractive Step Card Section Titles */
  .student-portal-wrapper .student-section-title {
    font-family: 'Playfair Display', Georgia, serif !important;
    font-size: 1.55rem !important;
    font-weight: 700 !important;
    background: linear-gradient(135deg, #ffffff 0%, #6ee7b7 100%) !important;
    -webkit-background-clip: text !important;
    -webkit-text-fill-color: transparent !important;
    margin-bottom: 18px !important;
    display: flex !important;
    align-items: center !important;
    gap: 10px !important;
    border-bottom: 1.5px solid rgba(16, 185, 129, 0.3) !important;
    padding-bottom: 12px !important;
  }
  .student-portal-wrapper .student-sub-title {
    font-size: 0.84rem !important;
    font-weight: 800 !important;
    color: #38bdf8 !important;
    text-transform: uppercase !important;
    letter-spacing: 0.08em !important;
    margin-bottom: 12px !important;
    display: flex !important;
    align-items: center !important;
    gap: 6px !important;
  }

  /* Input Labels */
  .student-portal-wrapper .control-label,
  .student-portal-wrapper label {
    color: #f8fafc !important;
    font-weight: 700 !important;
    font-size: 0.95rem !important;
    margin-bottom: 6px !important;
  }

  /* Text Boxes — Dark Translucent #1A202C */
  .student-portal-wrapper textarea,
  .student-portal-wrapper input[type=text],
  .student-portal-wrapper select,
  .student-portal-wrapper .form-control {
    background: #1A202C !important;
    color: #f8fafc !important;
    border: 1px solid #334155 !important;
    border-radius: 10px !important;
    font-size: 0.95rem !important;
    line-height: 1.5 !important;
    padding: 12px 14px !important;
    outline: none !important;
    transition: all 0.2s ease !important;
    box-shadow: none !important;
  }
  .student-portal-wrapper textarea::placeholder,
  .student-portal-wrapper input::placeholder {
    color: #94a3b8 !important;
    font-style: italic !important;
  }
  .student-portal-wrapper textarea:focus,
  .student-portal-wrapper input:focus,
  .student-portal-wrapper select:focus,
  .student-portal-wrapper .form-control:focus {
    background: #2D3748 !important;
    border-color: #10b981 !important;
    box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.25) !important;
    outline: none !important;
  }

  /* Vibrant Cyan & Emerald Sliders */
  .student-portal-wrapper .irs--shiny .irs-line {
    background: #1e3a2b !important;
    height: 8px !important;
    border-radius: 4px !important;
  }
  .student-portal-wrapper .irs--shiny .irs-bar {
    background: linear-gradient(90deg, #10b981, #06b6d4) !important;
    border: none !important;
    height: 8px !important;
    border-radius: 4px !important;
  }
  .student-portal-wrapper .irs--shiny .irs-handle {
    background: #10b981 !important;
    border: 2.5px solid #ffffff !important;
    width: 22px !important;
    height: 22px !important;
    top: 21px !important;
    box-shadow: 0 0 12px rgba(16, 185, 129, 0.6) !important;
    cursor: pointer !important;
  }
  .student-portal-wrapper .irs--shiny .irs-single {
    background: #06b6d4 !important;
    color: #ffffff !important;
    font-weight: 800 !important;
    font-size: 13px !important;
    border-radius: 6px !important;
    padding: 3px 8px !important;
    box-shadow: 0 2px 8px rgba(6, 182, 212, 0.4) !important;
  }
  .student-portal-wrapper .irs-min, 
  .student-portal-wrapper .irs-max, 
  .student-portal-wrapper .irs-grid-text {
    color: #cbd5e1 !important;
    font-weight: 600 !important;
    font-size: 11px !important;
  }

  /* Sticky Progress Header — Dark Glass */
  .student-sticky-header {
    position: sticky;
    top: 12px;
    z-index: 100;
    background: #0d2b1f;
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: 16px;
    padding: 16px 24px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.35);
    backdrop-filter: blur(12px);
    margin-bottom: 22px;
  }

  /* Step Indicator Pills */
  .student-step-pill {
    background: rgba(255, 255, 255, 0.06);
    color: #cbd5e1;
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 9999px;
    padding: 7px 16px;
    font-size: 0.82rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }
  .student-step-pill:hover {
    background: rgba(255, 255, 255, 0.14);
    color: #ffffff;
  }
  .student-step-pill.active {
    background: #10b981 !important;
    color: #ffffff !important;
    font-weight: 800 !important;
    border-color: #34d399 !important;
    box-shadow: 0 0 14px rgba(16, 185, 129, 0.5) !important;
  }
  .student-step-pill.completed {
    background: rgba(16, 185, 129, 0.18);
    color: #34d399;
    border-color: rgba(16, 185, 129, 0.4);
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
      href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Playfair+Display:ital,wght@0,600;0,700;1,600;1,700&display=swap",
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

  # Reset session on logout
  observeEvent(logout_trigger(), {
    if (logout_trigger() > 0) {
      user_session$user <- NULL
      updateTextInput(session, "login_email",    value = "")
      updateTextInput(session, "login_password", value = "")
    }
  })

  # ── PAGE ROUTER ─────────────────────────────────────────────────────────
  output$page_content <- renderUI({
    if (is.null(user_session$user)) {

      # ── LOGIN PAGE — pixel-perfect Campus Listen reference ─────────────
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

          # Login card
          div(class = "login-card",
            tags$span(class = "login-card-overline", "Secure Student Access"),
            tags$h2(class = "login-card-title", "Welcome back."),
            div(class = "login-card-desc",
              "Sign in with your college email to continue to the feedback workspace."
            ),

            textInput("login_email", "College email",
              placeholder = "you@college.edu", width = "100%"),
            passwordInput("login_password", "Password",
              placeholder = "Enter your password", width = "100%"),

            # Sign in button — proper Shiny actionButton (keeps reactive binding)
            actionButton("btn_login",
              label = HTML("Sign in securely &nbsp;<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' style='width:14px;height:14px;fill:none;stroke:rgba(255,255,255,0.75);stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle;'><rect x='3' y='11' width='18' height='11' rx='2' ry='2'/><path d='M7 11V7a5 5 0 0 1 10 0v4'/></svg>"),
              class = "btn-login"
            ),

            uiOutput("login_error"),

            div(class = "login-forgot",
              "Forgot your password? Contact your college administrator."
            ),

            div(class = "login-privacy",
              "Private by design \u2014 feedback is handled with care."
            )
          ),

          # Demo credentials — below card
          div(class = "demo-creds",
            p(HTML("<strong>Demo Credentials:</strong><br>
              \U0001F393 Student: alex@college.edu / student123<br>
              \U0001F9D1&#x200D;\U0001F3EB Faculty: sunita@college.edu / faculty123<br>
              \U0001F3DB&#xFE0F; Admin: admin@college.edu / admin123"))
          ),

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
                style="width:18px;height:18px;fill:none;stroke:#0d2b1f;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;",
                tags$path(d="M22 10v6M2 10l10-5 10 5-10 5z"),
                tags$path(d="M6 12v5c3 3 9 3 12 0v-5")
              ),
              "Campus Listen"
            ),
            div(style = "width:1px; height:18px; background:#ddd9d0;"),
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

  # ── LOGIN HANDLER ────────────────────────────────────────────────────────
  observeEvent(input$btn_login, {
    req(input$login_email, input$login_password)
    user <- tryCatch(
      authenticate_user(trimws(input$login_email), input$login_password),
      error = function(e) NULL
    )
    if (is.null(user)) {
      output$login_error <- renderUI({
        div(class = "login-error-box",
          "\u274C Invalid email or password. Please try again.")
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
}

shinyApp(ui, server)
