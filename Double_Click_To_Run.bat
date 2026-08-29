@echo off
title Sentilytics Launcher
echo ===================================================
echo   Sentilytics College Feedback Sentiment Analyzer
echo ===================================================
echo.
echo Running app helper... This will automatically install 
echo any missing libraries and open the web browser.
echo.
Rscript run_app.R
if %errorlevel% neq 0 (
  echo.
  echo ERROR: Failed to run app. Make sure R is installed 
  echo and added to your system PATH environment variables.
  echo.
)
pause
