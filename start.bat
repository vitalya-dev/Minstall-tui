@echo off
:: Включаем поддержку русского языка в консоли
chcp 65001 >nul

:: ===================================================
:: ЗАПРОС ПРАВ АДМИНИСТРАТОРА
:: ===================================================
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo Требуются права Администратора! Запрашиваю доступ...
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)
:: ===================================================

:: Делаем корень флешки рабочей папкой (это очень важно после перезапуска с админом!)
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
echo  7 - Подключиться к Wi-Fi
echo.
echo  0 - Выход
echo.
echo ===================================================

:: Запрашиваем ввод от пользователя (БЕЗ нажатия Enter)
:: /C 12345670 - это список разрешенных кнопок
:: /N - скрывает стандартную системную подсказку с кнопками
:: /M - выводит наше собственное сообщение
choice /C 12345670 /N /M " Выбери нужный пункт: "

:: Обрабатываем выбор.
:: ВАЖНО: проверяется позиция символа в списке 12345670. 
:: То есть кнопка '0' стоит на 8-м месте, поэтому её код будет 8.
if %errorlevel% equ 1 goto run_minstall
if %errorlevel% equ 2 goto run_sdi
if %errorlevel% equ 3 goto run_office
if %errorlevel% equ 4 goto run_massgrave
if %errorlevel% equ 5 goto run_debloat
if %errorlevel% equ 6 goto run_icons
if %errorlevel% equ 7 goto run_wifi
if %errorlevel% equ 8 goto end

:: Защита от ошибок ввода больше не нужна, choice просто не даст нажать другие кнопки!
:: Если ввели что-то другое
echo.
echo [ОШИБКА] Неверный пункт меню! Попробуй еще раз.
pause
goto main_menu

:run_minstall
echo.
echo Запускаю MInstAll в отдельном окне (исправление для Win 11)...
cd Minstall-tui
start "" cmd /c "install.bat"
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
echo Запускаю установку Microsoft Office 2021...
:: 1. Переходим прямо в папку с установщиком (кавычки спасают от пробелов)
cd "Microsoft Office LTSC 2021 Final + Project Pro + Visio Pro\Microsoft Office LTSC 2021 Final RUS x86_x64\ru_office_professional_plus_2021_x86_x64_dvd_2c455c8d"

:: 2. Спокойно запускаем Setup.exe в независимом окне
start "" "Setup.exe"

:: 3. Обязательно возвращаемся обратно в корень флешки!
cd /d "%~dp0"
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

:: 3. Копируем готовые ярлыки Office из меню "Пуск" на рабочий стол
start "" powershell -NoProfile -Command "$d=[Environment]::GetFolderPath('Desktop'); $cp=[Environment]::GetFolderPath('CommonPrograms'); $up=[Environment]::GetFolderPath('Programs'); @('Word.lnk', 'Excel.lnk', 'PowerPoint.lnk') | ForEach-Object { $c=$cp+'\'+$_; $u=$up+'\'+$_; if(Test-Path $c){Copy-Item $c $d -Force} elseif(Test-Path $u){Copy-Item $u $d -Force} }"
echo.
echo [УСПЕШНО] Значки добавлены на рабочий стол!
pause
goto main_menu

:run_wifi
echo.
echo Подключаюсь к Wi-Fi (VTI3 и VTI3_Wi-Fi5)...

:: 1. Проверяем и добавляем обычную сеть VTI3
if exist "Беспроводная сеть-VTI3.xml" (
    netsh wlan add profile filename="Беспроводная сеть-VTI3.xml" >nul
    echo [+] Профиль VTI3 добавлен.
) else (
    echo [-] Файл "Беспроводная сеть-VTI3.xml" не найден.
)

:: 2. Проверяем и добавляем сеть VTI3_Wi-Fi5
if exist "Беспроводная сеть-VTI3_Wi-Fi5.xml" (
    netsh wlan add profile filename="Беспроводная сеть-VTI3_Wi-Fi5.xml" >nul
    echo [+] Профиль VTI3_Wi-Fi5 добавлен.
) else (
    echo [-] Файл "Беспроводная сеть-VTI3_Wi-Fi5.xml" не найден.
)

:: 3. Отправляем команды на подключение
:: Сначала подключаемся к VTI3, затем к VTI3_Wi-Fi5
netsh wlan connect name="VTI3" >nul 2>&1
netsh wlan connect name="VTI3_Wi-Fi5" >nul 2>&1

echo.
echo [ГОТОВО] Сети импортированы, команды на подключение отправлены!
pause
goto main_menu

:end
exit