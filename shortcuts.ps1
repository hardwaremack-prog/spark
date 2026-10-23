# Creates the app and "Update <app>" shortcuts on the desktop and in the Start menu.
$Dir = $PSScriptRoot
$App = (Get-Content (Join-Path $Dir 'config.json') -Raw | ConvertFrom-Json).app_name
$shell = New-Object -ComObject WScript.Shell
$places = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))
foreach ($place in $places) {
  $s = $shell.CreateShortcut((Join-Path $place "$App.lnk"))
  $s.TargetPath = Join-Path $Dir "$App.bat"
  $s.WorkingDirectory = $Dir
  $s.IconLocation = Join-Path $Dir 'web\icon.ico'
  $s.WindowStyle = 7          # start minimized; the app opens in its own window
  $s.Description = 'Offline voice chat'
  $s.Save()

  $u = $shell.CreateShortcut((Join-Path $place "Update $App.lnk"))
  $u.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $u.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $Dir 'update.ps1')`" -Pause"
  $u.WorkingDirectory = $Dir
  $u.IconLocation = Join-Path $Dir 'web\icon.ico'
  $u.Description = "Get the newest version of $App"
  $u.Save()
}
Write-Host "Shortcuts ready."
