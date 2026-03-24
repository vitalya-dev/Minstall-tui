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
:: Запускаем Setup.exe по длинному пути, обязательно в кавычках из-за пробелов
start "" "Microsoft Office LTSC 2021 Final + Project Pro + Visio Pro\Microsoft Office LTSC 2021 Final RUS x86_x64\ru_office_professional_plus_2021_x86_x64_dvd_2c455c8d\Setup.exe"
goto main_menu

:end
exit