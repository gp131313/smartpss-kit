@echo off
rem PowerShell 7 module path must not leak into Windows PowerShell 5.1
set "PSModulePath="
rem SmartPSS Kit: двойной клик по этому файлу для установки. Запросит права администратора один раз.
rem Положите рядом дистрибутив General_SMARTPSS-Win64_*.exe (если он есть в пакете — уже рядом).
set "SPK_DIR=%~dp0"
set "SPK_USER=%USERDOMAIN%\%USERNAME%"
set "SPK_ARGS=%*"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$d = $env:SPK_DIR.TrimEnd('\'); $a = '-NoProfile -ExecutionPolicy Bypass -NoExit -File \"' + $d + '\Setup-SmartPSS.ps1\" ' + $env:SPK_ARGS; try { Start-Process powershell.exe -Verb RunAs -ArgumentList $a -ErrorAction Stop } catch { Write-Host 'Нужны права администратора - установка отменена.' -ForegroundColor Red; pause }"
