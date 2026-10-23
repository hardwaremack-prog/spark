@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Spark - setup
set PYTHONIOENCODING=utf-8
echo.
echo  ===============================================
echo    SPARK  -  one-time setup
echo    Needs internet now. Runs offline afterwards.
echo  ===============================================
echo.

rem ---- 0. Graphics card check (the AI runs on the NVIDIA GPU) ----
where nvidia-smi >nul 2>nul
if errorlevel 1 (
  echo  NOTE: No NVIDIA driver found. Spark will still work, but slowly on the CPU.
  echo        Install the latest driver from nvidia.com/drivers for the RTX 3050,
  echo        then run this installer again.
  echo.
) else (
  for /f "delims=" %%G in ('nvidia-smi --query-gpu^=name^,memory.total --format^=csv^,noheader') do echo  Graphics card: %%G
  echo.
)

rem ---- 1. Python 3.11-3.13 ----
set "PY="
for %%V in (3.12 3.11 3.13) do (
  if not defined PY (
    py -%%V -c "import sys" >nul 2>nul && set "PY=py -%%V"
  )
)
if not defined PY (
  python -c "import sys; sys.exit(0 if (3,10)<=sys.version_info[:2]<=(3,13) else 1)" >nul 2>nul && set "PY=python"
)
if not defined PY (
  echo [1/5] Installing Python 3.12 ...
  winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
  set "PY=py -3.12"
  py -3.12 -c "import sys" >nul 2>nul || (
    echo.
    echo  Python was installed but this window can't see it yet.
    echo  Close this window and double-click the installer again.
    pause
    exit /b 1
  )
) else (
  echo [1/5] Python found: %PY%
)

rem ---- 2. Ollama (runs the AI model on the graphics card) ----
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Ollama"
where ollama >nul 2>nul
if errorlevel 1 (
  echo [2/5] Installing Ollama ...
  winget install -e --id Ollama.Ollama --accept-source-agreements --accept-package-agreements
) else (
  echo [2/5] Ollama found.
)
tasklist /fi "imagename eq ollama.exe" | find /i "ollama.exe" >nul || (
  if exist "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe" (
    start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"
  ) else (
    start "" /min ollama serve
  )
  timeout /t 5 >nul
)

rem ---- 3. Private Python environment ----
echo [3/5] Setting up Spark's Python environment ...
if not exist ".venv\Scripts\python.exe" %PY% -m venv .venv
if not exist ".venv\Scripts\python.exe" (
  echo  Could not create the Python environment.
  pause
  exit /b 1
)
".venv\Scripts\python.exe" -m pip install --upgrade pip --quiet
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 (
  echo  Installing the speech libraries failed - see the messages above.
  pause
  exit /b 1
)

rem ---- 4. Voices, speech recognizer and AI models ----
echo [4/5] Downloading voices, speech recognizer and AI models (about 8 GB) ...
".venv\Scripts\python.exe" setup_models.py

rem ---- 5. Shortcuts + remember this install for updates ----
echo [5/5] Adding desktop shortcuts ...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0shortcuts.ps1"
if not exist data mkdir data
".venv\Scripts\python.exe" -c "import hashlib,shutil;open('data/requirements.sha1','w').write(hashlib.sha1(open('requirements.txt','rb').read()).hexdigest());shutil.copy('config.json','data/config.defaults.json')"

echo.
echo  Done! Double-click "Spark" on the desktop to start.
echo  New versions: click "Update now" in Spark's gear menu, or the "Update Spark" icon.
echo.
pause
