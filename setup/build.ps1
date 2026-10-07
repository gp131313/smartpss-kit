# build.ps1 — сборка SmartPSS-Setup.exe компилятором C# из состава Windows (.NET Framework 4.x), SDK не нужен.
# Положите рядом дистрибутив Dahua под именем SmartPSS-Installer.exe (или задайте -Installer <путь>).
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 -Installer C:\path\General_SMARTPSS-Win64_...exe
param([string]$Installer = 'SmartPSS-Installer.exe')
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path $csc)) { throw 'Не найден csc.exe (.NET Framework 4.x)' }

$inst = if (Test-Path $Installer) { (Resolve-Path $Installer).Path } else { Join-Path $here $Installer }
if (-not (Test-Path $inst)) { throw "Не найден дистрибутив: $Installer. Положите его рядом как SmartPSS-Installer.exe или укажите -Installer." }

# csc не принимает длинные имена ресурсов (CS2021) — вкладываем под коротким именем SmartPSS-Installer.exe
$res = @(
  ('-resource:{0},install.ps1' -f (Join-Path $here 'install.ps1')),
  ('-resource:{0},SmartPSS-Installer.exe' -f $inst)
)
$exe = Join-Path $here 'SmartPSS-Setup.exe'
& $csc -nologo -target:winexe -platform:anycpu -optimize+ -codepage:65001 `
  ('-win32manifest:{0}' -f (Join-Path $here 'admin.manifest')) `
  -reference:System.Windows.Forms.dll -reference:System.Drawing.dll `
  @res ('-out:{0}' -f $exe) (Join-Path $here 'Setup.cs')
if ($LASTEXITCODE -ne 0) { throw "Ошибка компиляции (код $LASTEXITCODE)" }

# тихий установщик — тот же файл: режим он определяет по собственному имени (…-Silent.exe)
$silent = Join-Path $here 'SmartPSS-Setup-Silent.exe'
Copy-Item $exe $silent -Force
foreach ($f in $exe, $silent) { '{0}  {1} bytes  sha256 {2}' -f $f, (Get-Item $f).Length, (Get-FileHash $f -Algorithm SHA256).Hash.ToLower() }
