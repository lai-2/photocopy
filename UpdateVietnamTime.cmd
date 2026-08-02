@echo off
:: ===========================================
:: Update Vietnam Time - Auto Admin
:: ===========================================

:: Kiem tra quyen Admin, neu chua co thi tu elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Restarting as Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo ==========================================
echo       Update Vietnam System Time
echo ==========================================
echo.

:: Dat mui gio Viet Nam
echo Setting time zone to Vietnam (UTC+7)...
tzutil /s "SE Asia Standard Time"
if %errorLevel% equ 0 (
    echo [OK] Time zone set to Vietnam.
) else (
    echo [ERROR] Cannot set time zone.
)
echo.

:: Dam bao Windows Time Service tu khoi dong va dang chay
echo Configuring Windows Time service...
sc config w32time start= auto >nul
sc query w32time | find "RUNNING" >nul
if %errorLevel% neq 0 (
    net start w32time >nul 2>&1
)
echo [OK] Windows Time service is running.
echo.

:: Cau hinh NTP servers
echo Configuring NTP servers...
w32tm /config /manualpeerlist:"time.google.com,0x8 time.cloudflare.com,0x8 pool.ntp.org,0x8" /syncfromflags:manual /reliable:no /update >nul

:: Khoi dong lai service de ap dung cau hinh, doi vai giay cho on dinh
echo Restarting time service...
net stop w32time >nul 2>&1
net start w32time >nul 2>&1
timeout /t 5 /nobreak >nul

:: Dong bo thoi gian
echo.
echo Synchronizing time...
w32tm /resync /force
if %errorLevel% equ 0 (
    echo [OK] Time synchronized successfully.
) else (
    echo [WARNING] Resync failed, trying to re-register service...
    net stop w32time >nul 2>&1
    w32tm /unregister >nul 2>&1
    w32tm /register >nul 2>&1
    net start w32time >nul 2>&1
    timeout /t 5 /nobreak >nul
    w32tm /resync /force
)

echo.
echo ------------------------------------------
echo Current Time:
echo ------------------------------------------
date /t
time /t
echo ------------------------------------------
echo.
echo Done.
pause
