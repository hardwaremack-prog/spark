@echo off
cd /d "%~dp0"
title Spark (close this window to quit)
set PYTHONIOENCODING=utf-8
if not exist ".venv\Scripts\python.exe" (
  echo Please run "Install Spark.bat" first.
  pause
  exit /b 1
)
rem Make sure Ollama is running
tasklist /fi "imagename eq ollama.exe" | find /i "ollama.exe" >nul || (
  if exist "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe" (
    start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"
  ) else (
    start "" /min ollama serve
  )
)
".venv\Scripts\python.exe" server.py %*
if errorlevel 1 if not exist "data\updating.flag" pause
