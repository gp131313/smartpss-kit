#Requires -RunAsAdministrator
# Откат: удаляет задачу и ярлык на рабочем столе (сам SmartPSS не трогает).
Unregister-ScheduledTask -TaskName 'SmartPSS (no UAC)' -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item (Join-Path ([Environment]::GetFolderPath('Desktop')) 'SmartPSS.lnk') -ErrorAction SilentlyContinue
Write-Host "Задача и ярлык на рабочем столе удалены. Ярлык в меню «Пуск» восстановится при переустановке SmartPSS."
