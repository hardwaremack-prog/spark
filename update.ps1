# Updates this app to the newest version on GitHub.
# Keeps the AI models, voices, settings, chats and any config.json changes.
#
#   update.ps1            update (restarts the app if it's running)
#   update.ps1 -Pause     same, then wait for Enter (used by the desktop shortcut)
#   update.ps1 -Restart   used by the app's own "Update now" button
param([switch]$Pause, [switch]$Restart, [string]$Repo = '')

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Dir = $PSScriptRoot
Set-Location $Dir

function Say([string]$m) { [Console]::Out.WriteLine("[update] $m"); [Console]::Out.Flush() }

$cfg = Get-Content (Join-Path $Dir 'config.json') -Raw | ConvertFrom-Json
$App = $cfg.app_name
if (-not $Repo) { $Repo = $cfg.update_repo }
if (-not $Repo) {
  # Older installs don't have update_repo yet
  $known = @{ 'Halo Converse' = 'hardwaremack-prog/halo-converse'; 'Spark' = 'hardwaremack-prog/spark'; 'Pip' = 'hardwaremack-prog/pip' }
  $Repo = $known[$App]
}
$flag = Join-Path $Dir 'data\updating.flag'
$tmp = $null
$code = 0

try {
  if (-not $Repo) { throw "Don't know where to get updates for '$App'" }
  New-Item -ItemType Directory -Force (Join-Path $Dir 'data') | Out-Null
  $old = '1.0.0'
  if (Test-Path (Join-Path $Dir 'VERSION')) { $old = (Get-Content (Join-Path $Dir 'VERSION') -Raw).Trim() }
  Say "$App $old in $Dir"

  # 1. Download and unpack the newest version (the app keeps running meanwhile)
  Say "Downloading the newest version from GitHub ..."
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("upd-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory $tmp | Out-Null
  $zip = Join-Path $tmp 'src.zip'
  Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/$Repo/archive/refs/heads/main.zip" -OutFile $zip
  Expand-Archive -Path $zip -DestinationPath (Join-Path $tmp 'x') -Force
  $src = Get-ChildItem (Join-Path $tmp 'x') -Directory | Select-Object -First 1
  if (-not $src -or -not (Test-Path (Join-Path $src.FullName 'server.py'))) { throw "The download looks wrong." }
  $new = (Get-Content (Join-Path $src.FullName 'VERSION') -Raw).Trim()

  # 2. Stop the app if it's running from this folder
  $venvPy = (Join-Path $Dir '.venv\Scripts\python.exe').ToLower()
  $batPath = (Join-Path $Dir "$App.bat")
  $all = @(Get-CimInstance Win32_Process)
  $byId = @{}; foreach ($p in $all) { $byId[[int]$p.ProcessId] = $p }
  $victims = @()
  foreach ($p in $all) {
    if ($p.ProcessId -eq $PID -or -not $p.CommandLine) { continue }
    $cl = $p.CommandLine.ToLower()
    if ($p.Name -ieq 'cmd.exe' -and $cl.Contains($batPath.ToLower())) { $victims += $p; continue }
    if ($p.Name -like 'python*.exe' -and $cl -match 'server\.py') {
      $exe = "$($p.ExecutablePath)".ToLower()
      $parent = $byId[[int]$p.ParentProcessId]
      $pexe = if ($parent) { "$($parent.ExecutablePath)".ToLower() } else { '' }
      if ($exe -eq $venvPy -or $pexe -eq $venvPy) { $victims += $p }
    }
  }
  $wasRunning = $victims.Count -gt 0
  if ($wasRunning) {
    Say "Closing $App for a moment ..."
    Set-Content -Path $flag -Value 'updating'
    foreach ($v in $victims) { Stop-Process -Id $v.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 2
  }

  # 3. Copy the new app files over (never .venv, models or data)
  Copy-Item (Join-Path $Dir 'config.json') (Join-Path $Dir 'data\config.before-update.json') -Force
  Get-ChildItem $src.FullName -Force |
    Where-Object { @('.venv', 'models', 'data', '.git') -notcontains $_.Name } |
    ForEach-Object { Copy-Item $_.FullName -Destination $Dir -Recurse -Force }

  $py = Join-Path $Dir '.venv\Scripts\python.exe'
  if (Test-Path $py) {
    # Keep the config.json settings you changed, take new defaults for the rest
    & $py (Join-Path $Dir 'merge_config.py')
    # Reinstall Python packages only if the list changed
    $req = (Get-FileHash (Join-Path $Dir 'requirements.txt') -Algorithm SHA1).Hash.ToLower()
    $shaFile = Join-Path $Dir 'data\requirements.sha1'
    $had = if (Test-Path $shaFile) { (Get-Content $shaFile -Raw).Trim().ToLower() } else { '' }
    if ($req -ne $had) {
      Say "Updating Python packages ..."
      & $py -m pip install --quiet -r (Join-Path $Dir 'requirements.txt')
      if ($LASTEXITCODE -ne 0) { throw "Installing Python packages failed" }
      Set-Content -Path $shaFile -Value $req
    }
  }

  if (Test-Path (Join-Path $Dir 'shortcuts.ps1')) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Dir 'shortcuts.ps1') | Out-Null
  }

  if ($old -eq $new) { Say "$App is up to date ($new)." } else { Say "Updated $App`: $old -> $new" }

  # 4. Start it again if it was running
  if ($wasRunning) {
    Say "Restarting $App ..."
    Start-Process -FilePath $batPath -ArgumentList '--no-browser' -WorkingDirectory $Dir -WindowStyle Minimized
    Start-Sleep -Seconds 3
    Say "$App restarted. An open $App window reloads by itself."
  }
  Say "Done."
}
catch {
  $code = 1
  Say "Something went wrong: $($_.Exception.Message)"
  Say "Your installed $App was not damaged; you can try again later."
}
finally {
  if (Test-Path $flag) { Remove-Item $flag -Force -ErrorAction SilentlyContinue }
  if ($tmp -and (Test-Path $tmp)) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($Pause) { Write-Host ""; Read-Host "Press Enter to close this window" | Out-Null }
exit $code
