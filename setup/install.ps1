param(
  [string]$Dir,            # папка, куда setup.exe распаковал вложенные файлы (дистрибутив + этот скрипт)
  [switch]$Silent,
  [switch]$NoFinishBox
)
$ErrorActionPreference = 'Stop'
$TaskName = 'SmartPSS (no UAC)'

function Find-SmartPSS {
  $cands = @(
    'C:\Program Files (x86)\Smart Professional Surveillance System\SmartPSS\SmartPSS.exe',
    'C:\Program Files\Smart Professional Surveillance System\SmartPSS\SmartPSS.exe',
    'D:\Smart Professional Surveillance System\SmartPSS\SmartPSS.exe'
  )
  foreach ($c in $cands) { if (Test-Path $c) { return $c } }
  $lnk = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\SmartPSS\SmartPSS.lnk'
  if (Test-Path $lnk) {
    $t = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk).TargetPath
    if ($t -and (Test-Path $t)) { return $t }
  }
  return $null
}

Write-Output "Проверяю наличие SmartPSS..."
$exe = Find-SmartPSS
if (-not $exe) {
  $inst = Join-Path $Dir 'SmartPSS-Installer.exe'
  if (-not (Test-Path $inst)) {
    $inst = Get-ChildItem $Dir -Filter 'General_SMARTPSS*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
  }
  if (-not $inst) { throw 'Не найден ни установленный SmartPSS, ни дистрибутив внутри установщика.' }
  # Ключ /S понимает сам дистрибутив Dahua (проверено 09.11.2026: тихая установка ~11 с,
  # папка C:\Program Files (x86)\Smart Professional Surveillance System). В «тихом» режиме
  # мастера быть не должно: раньше здесь всегда открывался мастер, а в silent-сборке он
  # никем не нажимался, и скрипт падал с «SmartPSS.exe не найден».
  if ($Silent) {
    Write-Output 'Тихая установка SmartPSS (дистрибутив Dahua с ключом /S)...'
    Start-Process $inst -ArgumentList '/S' -Wait
  } else {
    Write-Output 'Запускаю установку SmartPSS (пройдите мастер Dahua до конца)...'
    Start-Process $inst -Wait
  }
  $exe = Find-SmartPSS
  if (-not $exe) { throw 'После установки SmartPSS.exe не найден — дистрибутив не установился (запустите мастер вручную).' }
}
Write-Output "SmartPSS: $exe"

# Задача Планировщика с наивысшими правами — запуск без UAC.
# Имя учётки берём у текущего токена: "$env:USERDOMAIN\$env:USERNAME" в ssh-сессии и под
# виртуальными учётками не резолвится (0x80070534 «не удалось сопоставить имя с SID»).
$who = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$a = New-ScheduledTaskAction -Execute $exe -WorkingDirectory (Split-Path $exe)
$p = New-ScheduledTaskPrincipal -UserId $who -LogonType Interactive -RunLevel Highest
$s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $TaskName -Action $a -Principal $p -Settings $s -Force | Out-Null
Write-Output "Задача '$TaskName' создана для $who"

function Set-TaskShortcut([string]$Path) {
  $d = Split-Path $Path
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  $l = (New-Object -ComObject WScript.Shell).CreateShortcut($Path)
  $l.TargetPath   = 'C:\Windows\System32\schtasks.exe'
  $l.Arguments    = "/run /tn `"$TaskName`""
  $l.IconLocation = "$exe,0"
  $l.WindowStyle  = 7
  $l.Description  = 'SmartPSS с правами администратора без запроса UAC'
  $l.Save()
}
Set-TaskShortcut 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\SmartPSS\SmartPSS.lnk'
Set-TaskShortcut (Join-Path ([Environment]::GetFolderPath('Desktop')) 'SmartPSS.lnk')
Remove-Item 'C:\Users\Public\Desktop\SmartPSS.lnk' -ErrorAction SilentlyContinue
Write-Output "Ярлыки настроены"

# убрать распакованный дистрибутив (101 МБ), чтобы не занимал место
Remove-Item (Join-Path $Dir 'SmartPSS-Installer.exe') -Force -ErrorAction SilentlyContinue
Get-ChildItem $Dir -Filter 'General_SMARTPSS*.exe' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Output "OK"
exit 0
