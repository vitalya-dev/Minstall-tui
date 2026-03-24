@echo off
:: Включаем поддержку русского языка в консоли
chcp 65001 >nul
:: Делаем корень флешки рабочей папкой
cd /d "%~dp0"

:main_menu
cls
echo ===================================================
echo               ГЛАВНОЕ МЕНЮ ФЛЕШКИ
echo ===================================================
echo.
echo  1 - Запустить MInstAll (Автоматическая установка софта)
echo  2 - Запустить Snappy Driver Installer (SDI)
echo  3 - Установить Microsoft Office 2021
echo  4 - Запустить Microsoft Activation Scripts
echo  5 - Запустить Win11Debloat (Очистка Windows 11)
echo  6 - Вывести иконки ПК, Панели управления и Office на рабочий стол
echo.
echo  0 - Выход
echo.
echo ===================================================

:: Запрашиваем ввод от пользователя
set /p choice=" Выбери нужный пункт и нажми Enter: "

:: Обрабатываем выбор
if "%choice%"=="1" goto run_minstall
if "%choice%"=="2" goto run_sdi
if "%choice%"=="3" goto run_office
if "%choice%"=="4" goto run_massgrave
if "%choice%"=="5" goto run_debloat
if "%choice%"=="6" goto run_icons
if "%choice%"=="0" goto end

:: Если ввели что-то другое
echo.
echo [ОШИБКА] Неверный пункт меню! Попробуй еще раз.
pause
goto main_menu

:run_minstall
echo.
echo Запускаю MInstAll в отдельном окне...
cd Minstall-tui
start "" "install.bat"
cd ..
goto main_menu

:run_sdi
echo.
echo Запускаю Snappy Driver Installer в отдельном окне...
cd SDI_RUS
start "" "SDI_x64_R2503.exe"
cd ..
goto main_menu

:run_office
echo.
echo Запускаю установку Microsoft Office 2021 в отдельном окне...
start "" "Microsoft Office LTSC 2021 Final + Project Pro + Visio Pro\Microsoft Office LTSC 2021 Final RUS x86_x64\ru_office_professional_plus_2021_x86_x64_dvd_2c455c8d\Setup.exe"
goto main_menu

:run_massgrave
echo.
echo Запускаю свой PowerShell скрипт в отдельном окне...
start "" powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"
goto main_menu

:run_debloat
echo.
echo Запускаю Win11Debloat в отдельном окне...
:: Заменили двойные кавычки на одинарные вокруг ссылки, чтобы cmd не ругался
start "" powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://debloat.raphi.re/')))"
goto main_menu


:run_icons
echo.
echo Добавляю значки на рабочий стол...

:: 1. Мой компьютер (Этот компьютер)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul

:: 2. Панель управления
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f >nul

:: 3. Ярлыки для Office (Word, Excel, PowerPoint) 
:: (Предполагается стандартный путь установки Office 2016/2019/2021)
powershell -NoProfile -Command "$s=(New-Object -COM WScript.Shell); $d=[Environment]::GetFolderPath('Desktop'); foreach($a in @('WINWORD','EXCEL','POWERPNT')){ $l=$s.CreateShortcut($d+'\'+$a+'.lnk'); $l.TargetPath='C:\Program Files\Microsoft Office\root\Office16\'+$a+'.exe'; $l.Save() }"

:: 4. Перезапускаем Проводник, чтобы иконки появились моментально без перезагрузки ПК
echo Перезапуск рабочего стола...
taskkill /f /im explorer.exe >nul
start explorer.exe

echo.
echo [УСПЕШНО] Значки добавлены на рабочий стол!
pause
goto main_menu

:end
exit