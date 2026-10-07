# SmartPSS Kit — быстрое развёртывание SmartPSS без запроса UAC

Набор для быстрой установки **SmartPSS** (клиент видеонаблюдения Dahua) на любом Windows-компьютере так, чтобы программа запускалась с правами администратора **без запроса UAC при каждом старте**.

SmartPSS при каждом запуске требует подтверждения UAC («Разрешить этому приложению вносить изменения…»). Это набор из дистрибутива и одного скрипта, который ставит программу (если ещё не стоит) и настраивает запуск без этого окна.

## Как это работает

Windows не разрешает запускать приложение с правами администратора без UAC через обычный ярлык. Обходной путь, который применяет этот набор, — штатный и безопасный:

1. Создаётся **задача Планировщика заданий** `SmartPSS (no UAC)` с флагом «Выполнять с наивысшими правами».
2. Ярлыки на рабочем столе и в меню «Пуск» заменяются на запуск этой задачи (`schtasks /run`).
3. Задача стартует SmartPSS уже с правами администратора, а запуск самой задачи UAC не запрашивает.

Пароль администратора нигде не сохраняется. Задача работает от вашей учётной записи; повышение прав даёт сам Планировщик.

## Установка

1. Скачайте из [релиза](https://github.com/gp131313/smartpss-kit/releases/latest) архив `smartpss-kit-*.zip` и, если SmartPSS ещё не установлен, инсталлятор `General_SMARTPSS-Win64_*.exe`.
2. Распакуйте архив. Положите инсталлятор в ту же папку (скрипт найдёт его сам) либо установите SmartPSS вручную заранее.
3. Запустите PowerShell **от имени администратора** (это единственное окно UAC за всё время) и выполните:

```powershell
pwsh -ExecutionPolicy Bypass -File .\Setup-SmartPSS.ps1
```

Если установлен только Windows PowerShell 5.1:

```powershell
powershell -ExecutionPolicy Bypass -File .\Setup-SmartPSS.ps1
```

Скрипт при необходимости запустит мастер установки SmartPSS, создаст задачу и заменит ярлыки. Дальше запускайте SmartPSS ярлыком с рабочего стола или из меню «Пуск» — окна UAC больше не будет.

### Параметры

- `-Installer <путь>` — явный путь к инсталлятору `General_SMARTPSS-Win64_*.exe`.
- `-InstallDir <папка>` — где искать или куда установлен SmartPSS (например `D:\Smart Professional Surveillance System`).

### Откат

```powershell
pwsh -ExecutionPolicy Bypass -File .\Remove-SmartPSS-NoUAC.ps1
```

Удаляет задачу и ярлык на рабочем столе. Сам SmartPSS не трогает.

## Ограничения

- Только Windows (проверено на Windows 11). Планировщик есть и в Windows 10.
- Для разовой настройки нужны права администратора — иначе задачу с наивысшими правами создать нельзя.
- Дистрибутив SmartPSS распространяется Dahua; он лежит в разделе [Releases](https://github.com/gp131313/smartpss-kit/releases) как ассет для удобства, права на него принадлежат Dahua.

## Поддержать

Если набор пригодился — можно кинуть на кофе:

- **Dogecoin (DOGE)**: `D7z9UaBsmcV7EqJo5Y5fdLG9xUNw47dNgr`

Подробнее — в [DONATE.md](DONATE.md).

## Лицензия

Скрипты — [MIT](LICENSE). Дистрибутив SmartPSS — собственность Dahua Technology, распространяется на условиях правообладателя.

## English

Kit to deploy **SmartPSS** (Dahua surveillance client) on any Windows PC so it runs elevated **without a UAC prompt on every launch**. `Setup-SmartPSS.ps1` (run once from an elevated PowerShell) installs SmartPSS if needed, creates a Scheduled Task `SmartPSS (no UAC)` with highest privileges, and repoints the Desktop and Start Menu shortcuts to run that task. No admin password is stored. `Remove-SmartPSS-NoUAC.ps1` reverts it. Scripts are MIT-licensed; the SmartPSS installer in Releases belongs to Dahua.
