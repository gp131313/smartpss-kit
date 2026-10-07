@echo off
rem PowerShell 7 module path must not leak into Windows PowerShell 5.1
set "PSModulePath="
rem SmartPSS Kit: откат. Удаляет задачу и ярлык на рабочем столе. Запросит права администратора один раз.
set "SPK_DIR=%~dp0"
set "SPK_ARGS=%*"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$d = $env:SPK_DIR.TrimEnd('\'); $a = '-NoProfile -ExecutionPolicy Bypass -NoExit -File \"' + $d + '\Remove-SmartPSS-NoUAC.ps1\" ' + $env:SPK_ARGS; try { Start-Process powershell.exe -Verb RunAs -ArgumentList $a -ErrorAction Stop } catch { Write-Host 'Нужны права администратора - отменено.' -ForegroundColor Red; pause }"
