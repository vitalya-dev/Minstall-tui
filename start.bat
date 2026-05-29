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
echo  8 - Открыть настройки Защитника Windows
echo  9 - Автоматический режим (Установка, настройка, активация)
echo.
echo  0 - Выход
echo.
echo ===================================================

:: Запрашиваем ввод от пользователя (БЕЗ нажатия Enter)
choice /C 1234567890 /N /M " Выбери нужный пункт: "
set "choice_res=%errorlevel%"

if %choice_res% equ 1 call :run_minstall
if %choice_res% equ 2 call :run_sdi
if %choice_res% equ 3 call :run_office
if %choice_res% equ 4 call :run_massgrave
if %choice_res% equ 5 call :run_debloat
if %choice_res% equ 6 call :run_icons
if %choice_res% equ 7 call :run_wifi
if %choice_res% equ 8 call :run_defender
if %choice_res% equ 9 call :run_auto
if %choice_res% equ 10 goto end

goto main_menu

:run_minstall
echo.
echo Запускаю MInstAll...
cd core
start "" cmd /c "install.bat"
cd ..
exit /b

:run_sdi
echo.
echo Запускаю Snappy Driver Installer...
cd SDI_RUS\SDI
start "" "SDI_x64_R2604.exe" -autoinstall
cd ..\..
exit /b

:run_office
echo.
echo Запускаю установку Microsoft Office 2021...
cd "Microsoft Office LTSC 2021 Final + Project Pro + Visio Pro\Microsoft Office LTSC 2021 Final RUS x86_x64\ru_office_professional_plus_2021_x86_x64_dvd_2c455c8d"
start "" "Setup.exe"
cd /d "%~dp0"
exit /b

:run_massgrave
echo.
echo Запускаю Microsoft Activation Scripts (оффлайн)...

set "ZIP_FILE=%~dp0Microsoft-Activation-Scripts.zip"
set "EXTRACT_TO=%~dp0Microsoft-Activation-Scripts"
set "SEVEN_ZIP=%~dp07z.exe"
set "ARCHIVE_PASSWORD=1"

if not exist "%EXTRACT_TO%\MAS\All-In-One-Version-KL\MAS_AIO.cmd" (
    if not exist "%ZIP_FILE%" (
        echo [ОШИБКА] Архив "%ZIP_FILE%" не найден!
        pause
        goto main_menu
    )
    if not exist "%SEVEN_ZIP%" (
        echo [ОШИБКА] 7z.exe не найден в корне флешки!
        pause
        goto main_menu
    )
 
    echo [-] Распаковываю запароленный архив, подожди...
    "%SEVEN_ZIP%" x "%ZIP_FILE%" -o"%EXTRACT_TO%" -p"%ARCHIVE_PASSWORD%" -y >nul
    
    if errorlevel 1 (
        echo [ОШИБКА] Не удалось распаковать архив!
        echo Проверьте пароль сейчас: %ARCHIVE_PASSWORD%
        pause
        goto main_menu
    )
    echo [+] Готово!
)

set "MAS_SCRIPT=%EXTRACT_TO%\MAS\All-In-One-Version-KL\MAS_AIO.cmd"

if exist "%MAS_SCRIPT%" (
    echo [+] Запускаю активацию Windows и Office...
    start "" cmd /c "%MAS_SCRIPT%" /Z-WindowsESUOffice
) else (
    echo [ОШИБКА] MAS_AIO.cmd не найден!
    echo Проверь структуру архива.
    pause
    goto main_menu
)

timeout /t 2 >nul
goto main_menu

:run_debloat
echo.
echo Запускаю Win11Debloat...
start "" powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://debloat.raphi.re/'))) -CLI -Silent -RunDefaults"
exit /b

:run_icons
echo.
echo Добавляю значки на рабочий стол...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f >nul
:: Запуск PowerShell в видимом режиме
start "" powershell -NoProfile -Command "$d=[Environment]::GetFolderPath('Desktop'); $cp=[Environment]::GetFolderPath('CommonPrograms'); $up=[Environment]::GetFolderPath('Programs'); @('Word.lnk', 'Excel.lnk', 'PowerPoint.lnk') | ForEach-Object { $c=$cp+'\'+$_; $u=$up+'\'+$_; if(Test-Path $c){Copy-Item $c $d -Force} elseif(Test-Path $u){Copy-Item $u $d -Force} }"
echo.
echo [УСПЕШНО] Значки добавлены на рабочий стол!
pause
goto main_menu

:run_wifi
echo.
echo Подключаюсь к Wi-Fi (VTI3 и VTI3_Wi-Fi5)...

if exist "wifi_profiles\Беспроводная сеть-VTI3.xml" (
    netsh wlan add profile filename="wifi_profiles\Беспроводная сеть-VTI3.xml" >nul
    echo [+] Профиль VTI3 добавлен.
) else (
    echo [-] Файл "wifi_profiles\Беспроводная сеть-VTI3.xml" не найден.
)

if exist "wifi_profiles\Беспроводная сеть-VTI3_Wi-Fi5.xml" (
    netsh wlan add profile filename="wifi_profiles\Беспроводная сеть-VTI3_Wi-Fi5.xml" >nul
    echo [+] Профиль VTI3_Wi-Fi5 добавлен.
) else (
    echo [-] Файл "wifi_profiles\Беспроводная сеть-VTI3_Wi-Fi5.xml" не найден.
)

netsh wlan connect name="VTI3" >nul 2>&1
netsh wlan connect name="VTI3_Wi-Fi5" >nul 2>&1

echo.
echo [ГОТОВО] Сети импортированы, команды на подключение отправлены!
pause
goto main_menu

:run_defender
echo.
echo Открываю раздел "Защита от вирусов и угроз"...
echo.
start "" "windowsdefender://threat"
pause
exit /b


:run_auto
cls
echo ===================================================
echo           АВТОМАТИЧЕСКИЙ РЕЖИМ ЗАПУЩЕН
echo ===================================================
echo.

echo [1/6] Запускаю Snappy Driver Installer...
cd SDI_RUS\SDI
start "" "SDI_x64_R2604.exe" -autoinstall
cd ..\..

echo [2/6] Запускаю MInstAll...
cd core
start "" cmd /c "install.bat"
cd ..

echo [3/6] Запускаю установку Microsoft Office 2021...
cd "Microsoft Office LTSC 2021 Final + Project Pro + Visio Pro\Microsoft Office LTSC 2021 Final RUS x86_x64\ru_office_professional_plus_2021_x86_x64_dvd_2c455c8d"
start "" "Setup.exe"
cd /d "%~dp0"

echo.
echo [4/6] Ожидание установки драйверов, Wi-Fi и интернета...
:wait_for_internet

:: Постоянно пытаемся импортировать сети и подключиться.
:: Если драйвер еще не встал, команды просто проигнорируются.
if exist "wifi_profiles\Беспроводная сеть-VTI3.xml" (
    netsh wlan add profile filename="wifi_profiles\Беспроводная сеть-VTI3.xml" >nul 2>&1
)
if exist "wifi_profiles\Беспроводная сеть-VTI3_Wi-Fi5.xml" (
    netsh wlan add profile filename="wifi_profiles\Беспроводная сеть-VTI3_Wi-Fi5.xml" >nul 2>&1
)
netsh wlan connect name="VTI3" >nul 2>&1
netsh wlan connect name="VTI3_Wi-Fi5" >nul 2>&1

:: Проверяем, появился ли интернет после попытки подключения
ping -n 1 -w 1000 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
    timeout /t 5 >nul
    goto wait_for_internet
)
echo [+] Интернет подключен!

echo.
echo [5/6] Запускаю Win11Debloat...
start "" powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://debloat.raphi.re/'))) -CLI -Silent -RunDefaults"

echo.
echo [6/6] Ожидание завершения установки Office 2021...
:wait_for_office
tasklist /fi "imagename eq setup.exe" | find /i "setup.exe" >nul
if %errorlevel% equ 0 (
    timeout /t 5 >nul
    goto wait_for_office
)
echo [+] Установка Office завершена!

echo.
echo [+] Запускаю Microsoft Activation Scripts (оффлайн)...
set "ZIP_FILE=%~dp0Microsoft-Activation-Scripts.zip"
set "EXTRACT_TO=%~dp0Microsoft-Activation-Scripts"
set "SEVEN_ZIP=%~dp07z.exe"
set "ARCHIVE_PASSWORD=1"

if not exist "%EXTRACT_TO%\MAS\All-In-One-Version-KL\MAS_AIO.cmd" (
    if not exist "%ZIP_FILE%" (
        echo [ОШИБКА] Архив "%ZIP_FILE%" не найден!
        goto skip_mas
    )
    if not exist "%SEVEN_ZIP%" (
        echo [ОШИБКА] 7z.exe не найден в корне флешки!
        goto skip_mas
    )
    echo [-] Распаковываю запароленный архив MAS...
    "%SEVEN_ZIP%" x "%ZIP_FILE%" -o"%EXTRACT_TO%" -p"%ARCHIVE_PASSWORD%" -y >nul
)

set "MAS_SCRIPT=%EXTRACT_TO%\MAS\All-In-One-Version-KL\MAS_AIO.cmd"
if exist "%MAS_SCRIPT%" (
    echo [+] Запускаю активацию Windows и Office...
    start "" cmd /c "%MAS_SCRIPT%" /Z-WindowsESUOffice
) else (
    echo [ОШИБКА] Скрипт активации не найден!
)
:skip_mas

echo.
echo [+] Добавляю значки на рабочий стол...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f >nul
start "" powershell -NoProfile -Command "$d=[Environment]::GetFolderPath('Desktop'); $cp=[Environment]::GetFolderPath('CommonPrograms'); $up=[Environment]::GetFolderPath('Programs'); @('Word.lnk', 'Excel.lnk', 'PowerPoint.lnk') | ForEach-Object { $c=$cp+'\'+$_; $u=$up+'\'+$_; if(Test-Path $c){Copy-Item $c $d -Force} elseif(Test-Path $u){Copy-Item $u $d -Force} }"

echo.
echo ===================================================
echo     АВТОМАТИЧЕСКИЙ РЕЖИМ УСПЕШНО ЗАВЕРШЕН!
echo ===================================================
pause
goto main_menu

:end
exit