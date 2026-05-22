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
echo.
echo  0 - Выход
echo.
echo ===================================================

:: Запрашиваем ввод от пользователя (БЕЗ нажатия Enter)
choice /C 123456780 /N /M " Выбери нужный пункт: "

if %errorlevel% equ 1 goto run_minstall
if %errorlevel% equ 2 goto run_sdi
if %errorlevel% equ 3 goto run_office
if %errorlevel% equ 4 goto run_massgrave
if %errorlevel% equ 5 goto run_debloat
if %errorlevel% equ 6 goto run_icons
if %errorlevel% equ 7 goto run_wifi
if %errorlevel% equ 8 goto run_defender
if %errorlevel% equ 9 goto end

echo.
echo [ОШИБКА] Неверный пункт меню! Попробуй еще раз.
pause
goto main_menu

:run_minstall
echo.
echo Запускаю MInstAll в фоне...
cd core
start /min "" cmd /c "install.bat"
cd ..
goto main_menu

:run_sdi
echo.
echo Запускаю Snappy Driver Installer в фоне...
cd SDI_RUS\SDI
start /min "" "SDI_x64_R2604.exe" -autoinstall
cd ..\..
goto main_menu

:run_office
echo.
echo Запускаю установку Microsoft Office 2021 в фоне...
cd "Microsoft Office LTSC 2021 Final + Project Pro + Visio Pro\Microsoft Office LTSC 2021 Final RUS x86_x64\ru_office_professional_plus_2021_x86_x64_dvd_2c455c8d"
start /min "" "Setup.exe"
cd /d "%~dp0"
goto main_menu

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
    echo [+] Запускаю активацию Windows и Office в фоне...
    start /min "" cmd /c "%MAS_SCRIPT%" /Z-WindowsESUOffice
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
echo Запускаю Win11Debloat в скрытом режиме...
:: Добавили -WindowStyle Hidden для полной невидимости консоли PS
start /min "" powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://debloat.raphi.re/'))) -CLI -Silent -RunDefaults"
goto main_menu

:run_icons
echo.
echo Добавляю значки на рабочий стол...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f >nul
:: Скрытый запуск PowerShell
start /min "" powershell -WindowStyle Hidden -NoProfile -Command "$d=[Environment]::GetFolderPath('Desktop'); $cp=[Environment]::GetFolderPath('CommonPrograms'); $up=[Environment]::GetFolderPath('Programs'); @('Word.lnk', 'Excel.lnk', 'PowerPoint.lnk') | ForEach-Object { $c=$cp+'\'+$_; $u=$up+'\'+$_; if(Test-Path $c){Copy-Item $c $d -Force} elseif(Test-Path $u){Copy-Item $u $d -Force} }"
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
start /min "" "windowsdefender://threat"
pause
goto main_menu

:end
exit