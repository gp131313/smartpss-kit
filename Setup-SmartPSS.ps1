#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Разворачивает SmartPSS (Dahua) на Windows без запросов UAC при каждом запуске.
.DESCRIPTION
  1. Если SmartPSS не установлен — запускает инсталлятор (ищет рядом со скриптом или по -Installer).
  2. Создаёт задачу Планировщика "SmartPSS (no UAC)" с наивысшими правами.
  3. Заменяет ярлыки на рабочем столе и в меню «Пуск» на запуск этой задачи.
  Запускать от администратора: pwsh -ExecutionPolicy Bypass -File .\Setup-SmartPSS.ps1
#>
param(
  [string]$Installer,          # путь к General_SMARTPSS-Win64_*.exe (по умолчанию ищется рядом)
  [string]$InstallDir          # куда установлен/устанавливать; по умолчанию определяется автоматически
)
$ErrorActionPreference = 'Stop'
$TaskName = 'SmartPSS (no UAC)'

function Find-SmartPSS {
  $cands = @()
  if ($InstallDir) { $cands += Join-Path $InstallDir 'SmartPSS.exe'; $cands += Join-Path $InstallDir 'SmartPSS\SmartPSS.exe' }
  $cands += 'C:\Program Files (x86)\Smart Professional Surveillance System\SmartPSS\SmartPSS.exe'
  $cands += 'C:\Program Files\Smart Professional Surveillance System\SmartPSS\SmartPSS.exe'
  $cands += 'D:\Smart Professional Surveillance System\SmartPSS\SmartPSS.exe'
  foreach ($c in $cands) { if (Test-Path $c) { return $c } }
  $lnk = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\SmartPSS\SmartPSS.lnk'
  if (Test-Path $lnk) {
    $t = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk).TargetPath
    if ($t -and (Test-Path $t)) { return $t }
  }
  return $null
}

# 1. Установка, если нужно
$exe = Find-SmartPSS
if (-not $exe) {
  if (-not $Installer) {
    $Installer = Get-ChildItem $PSScriptRoot -Filter 'General_SMARTPSS*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
  }
  if (-not $Installer -or -not (Test-Path $Installer)) {
    throw "SmartPSS не найден и инсталлятор не указан. Скачайте General_SMARTPSS-Win64_*.exe из релиза репозитория и положите рядом со скриптом (или передайте -Installer)."
  }
  Write-Host "Запускаю инсталлятор: $Installer (пройдите мастер установки до конца)"
  Start-Process $Installer -Wait
  $exe = Find-SmartPSS
  if (-not $exe) { throw "После установки SmartPSS.exe не найден. Укажите путь через -InstallDir." }
}
Write-Host "SmartPSS: $exe"

# 2. Задача Планировщика с наивысшими правами (запускается без запроса UAC)
$a = New-ScheduledTaskAction -Execute $exe -WorkingDirectory (Split-Path $exe)
$p = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $TaskName -Action $a -Principal $p -Settings $s -Force | Out-Null
Write-Host "Задача '$TaskName' создана"

# 3. Ярлыки -> запуск задачи
function Set-TaskShortcut([string]$Path) {
  $dir = Split-Path $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $l = (New-Object -ComObject WScript.Shell).CreateShortcut($Path)
  $l.TargetPath   = 'C:\Windows\System32\schtasks.exe'
  $l.Arguments    = "/run /tn `"$TaskName`""
  $l.IconLocation = "$exe,0"
  $l.WindowStyle  = 7
  $l.Description  = 'SmartPSS с правами администратора без запроса UAC'
  $l.Save()
  Write-Host "Ярлык: $Path"
}
Set-TaskShortcut 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\SmartPSS\SmartPSS.lnk'
Set-TaskShortcut (Join-Path ([Environment]::GetFolderPath('Desktop')) 'SmartPSS.lnk')
Remove-Item 'C:\Users\Public\Desktop\SmartPSS.lnk' -ErrorAction SilentlyContinue

Write-Host "`nГотово. Запускайте SmartPSS ярлыком с рабочего стола или из меню «Пуск»."
