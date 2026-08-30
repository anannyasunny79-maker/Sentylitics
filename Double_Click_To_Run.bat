@echo off
title Sentilytics Launcher
echo ===================================================
echo   Sentilytics College Feedback Sentiment Analyzer
echo ===================================================
echo.
echo Running app helper... This will automatically install 
echo any missing libraries and open the web browser.
echo.

set "RSCRIPT_CMD=Rscript"
where Rscript >nul 2>nul
if %errorlevel% neq 0 (
  if exist "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" (
    set "RSCRIPT_CMD="C:\Program Files\R\R-4.6.1\bin\Rscript.exe""
  ) else (
    for /d %%D in ("C:\Program Files\R\R-*") do (
      if exist "%%D\bin\Rscript.exe" set "RSCRIPT_CMD="%%D\bin\Rscript.exe""
    )
  )
)

%RSCRIPT_CMD% run_app.R
if %errorlevel% neq 0 (
  echo.
  echo ERROR: Failed to run app. Make sure R is installed 
  echo and added to your system PATH environment variables.
  echo.
)
pause

