@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title indee - Cai dat tu dong

:: ============================================================================
:: install-indee.cmd - Bo cai dat tu dong cho ung dung indee
:: ============================================================================
:: Tu dong, han che thao tac cua nguoi dung toi da:
::   1. Tu nang quyen quan tri (UAC) neu chua chay voi quyen Administrator.
::   2. Kiem tra Windows 7 da co Service Pack 1 va 2 ban va bat buoc de tin
::      cay chu ky SHA-2 (KB4474419, KB4490628) chua - day la dieu kien bat
::      buoc truoc khi .NET Framework 4.8 cai duoc tren Windows 7, dung nhu
::      README-indee.md "Cai dat tren Windows 7" da ghi. Khong the tu dong
::      tai 2 muc nay (Microsoft chi phat hanh qua Update Catalog, can phien
::      lam viec trinh duyet, khong co link tinh de tai thang) - script se mo
::      san trang tim kiem tren Update Catalog va dung lai, nguoi dung cai
::      xong thi chay lai chinh file install-indee.cmd nay de tiep tuc (cac buoc da
::      xong se tu dong duoc bo qua).
::   3. Kiem tra & cai am tham .NET Framework 4.8 (bo cai offline chinh thuc
::      cua Microsoft, /q /norestart - khong hien dialog nao).
::   4. Best-effort: cai them 1 font mau (Noto Color Emoji, giay phep OFL -
::      duoc phep phan phoi lai) neu may chua co san font "Segoe UI Emoji",
::      de cac icon dang emoji trong giao dien (tu ban indee moi, xem
::      Helpers/UIHelper.cs) hien day du hon tren Windows 7/8/8.1. Buoc nay
::      KHONG dam bao chac chan hien mau - GDI co dien cua cac ban Windows
::      truoc Windows 10 khong chinh thuc ho tro bang mau CBDT/COLR cua cac
::      font emoji mau, nen ket qua co the van la icon den trang hoac thieu
::      o mot so may - khong lam that bai qua trinh cai neu buoc nay khong
::      thanh cong.
::   5. Tai ban indee moi nhat tu GitHub Releases - dung dung nguon va cach
::      xac dinh file moi nhat ma chinh ung dung dung cho tinh nang tu cap
::      nhat cua no (xem Services/UpdateService.cs: repo github.com/lai-2/
::      photocopy, asset "indee-<version>.zip" trong release "latest") - va
::      giai nen vao C:\Program Files\indee.
::   6. Tao shortcut "indee" ngoai Desktop.
::
:: Moi lan chay, toan bo output cua script (ke ca khi loi hoac thoat dot ngot)
:: duoc tu dong ghi vao 1 file log rieng (install-log-<timestamp>.txt) ngay
:: trong cung thu muc voi file install-indee.cmd nay, dong thoi van hien tren
:: man hinh nhu binh thuong - de tien kiem tra sau nay, dac biet huu ich khi
:: debug tren Windows 7.
:: ============================================================================

set "INSTALL_DIR=C:\Program Files\indee"
set "TEMP_DIR=%TEMP%\IndeeInstall"
set "NET48_FWLINK=https://go.microsoft.com/fwlink/?linkid=2088631"
set "EMOJI_FONT_URL=https://raw.githubusercontent.com/googlefonts/noto-emoji/main/fonts/NotoColorEmoji_WindowsCompatible.ttf"

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%" >nul 2>&1

:: ---- Buoc 0: tu nang quyen Administrator ----------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Can quyen Administrator de cai dat - dang yeu cau...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ---- Buoc 0b: tu ghi log toan bo qua trinh cai dat ra file -----------------
:: Chi wrap 1 lan (danh dau bang tham so __LOGGED__) - lan chay ke tiep (da la
:: tien trinh Administrator) se thay danh dau nay va bo qua, chay thang phan
:: than script ben duoi. Dung "& '%~f0'" (khong dung cmd /c "...") de tranh
:: loi nested-quote khi duong dan script co khoang trang.
if /I not "%~1"=="__LOGGED__" (
    for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set "LOG_TS=%%T"
    set "LOG_FILE=%~dp0install-log-!LOG_TS!.txt"
    echo [*] Dang ghi log cai dat vao: !LOG_FILE!
    powershell -NoProfile -Command "& { & '%~f0' __LOGGED__ 2>&1 | Tee-Object -FilePath '!LOG_FILE!'; exit $LASTEXITCODE }"
    exit /b !errorlevel!
)

echo ================================================================
echo   Cai dat indee - tu dong
echo ================================================================
if defined LOG_FILE echo   Log: %LOG_FILE%
echo.

:: ---- Buoc 1: xac dinh he dieu hanh -----------------------------------------
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-WmiObject Win32_OperatingSystem).Version"`) do set "OS_VER=%%A"
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-WmiObject Win32_OperatingSystem).ServicePackMajorVersion"`) do set "OS_SP=%%A"
if not defined OS_SP set "OS_SP=0"

echo [*] He dieu hanh: Windows NT %OS_VER%, Service Pack %OS_SP%

set "IS_WIN7=0"
if "%OS_VER:~0,3%"=="6.1" set "IS_WIN7=1"
if "%IS_WIN7%"=="1" goto :check_win7_prereqs
goto :check_net48

:check_win7_prereqs
if %OS_SP% GEQ 1 goto :check_win7_kb

echo.
echo [!] May nay la Windows 7 nhung chua co Service Pack 1 SP1.
echo     .NET Framework 4.8 khong the cai neu thieu SP1, va Microsoft
echo     khong con phat hanh link tai tinh cho SP1 nen khong the tu dong
echo     tai o day. Dang mo trang Microsoft Update Catalog de cai thu cong.
echo     Sau khi cai xong SP1 va KHOI DONG LAI may, chay lai file install-indee.cmd
echo     nay de tiep tuc cac buoc con lai.
echo.
start "" "https://www.catalog.update.microsoft.com/Search.aspx?q=KB976932"
pause
exit /b 1

:check_win7_kb
echo [*] Kiem tra 2 ban va SHA-2 bat buoc tren Windows 7: KB4474419, KB4490628...
set "MISSING_KB="
wmic qfe list | findstr /I "KB4474419" >nul
if errorlevel 1 set "MISSING_KB=!MISSING_KB! KB4474419"
wmic qfe list | findstr /I "KB4490628" >nul
if errorlevel 1 set "MISSING_KB=!MISSING_KB! KB4490628"

if not defined MISSING_KB (
    echo [OK] Da co du 2 ban va SHA-2.
    goto :check_net48
)

echo.
echo [!] May nay dang thieu ban va:!MISSING_KB!
echo     Cac ban va nay bat buoc de Windows tin tuong goi cai .NET Framework
echo     4.8 ky bang chu ky SHA-2. Dang mo Microsoft Update Catalog de tai/
echo     cai thu cong - khong the tu dong hoa vi trang nay can thao tac
echo     trinh duyet. Cai xong thi chay lai install-indee.cmd nay de tiep tuc.
echo.
start "" "https://www.catalog.update.microsoft.com/Search.aspx?q=KB4474419"
start "" "https://www.catalog.update.microsoft.com/Search.aspx?q=KB4490628"
pause
exit /b 1

:: ---- Buoc 2: .NET Framework 4.8 --------------------------------------------
:check_net48
echo.
echo [*] Kiem tra .NET Framework 4.8...
set "NET48_OK=0"
set "RELHEX="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2^>nul') do set "RELHEX=%%A"
if defined RELHEX (
    set /a RELDEC=!RELHEX!
    if !RELDEC! GEQ 528040 set "NET48_OK=1"
)

if "%NET48_OK%"=="1" (
    echo [OK] Da co .NET Framework 4.8 hoac moi hon.
    goto :install_font
)

echo [*] Chua co .NET Framework 4.8 - dang tai bo cai chinh thuc tu Microsoft...
set "NET48_EXE=%TEMP_DIR%\ndp48-x86-x64-allos-enu.exe"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; [Net.WebRequest]::DefaultWebProxy = $null; try { $wc = New-Object Net.WebClient; $wc.Proxy = $null; $wc.DownloadFile('%NET48_FWLINK%', '%NET48_EXE%') } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [LOI] Khong tai duoc bo cai .NET Framework 4.8. Kiem tra ket noi mang roi chay lai install-indee.cmd.
    pause
    exit /b 1
)

echo [*] Dang cai .NET Framework 4.8 am tham - khong can thao tac gi...
"%NET48_EXE%" /q /norestart
set "NET48_RC=%errorlevel%"
if "%NET48_RC%"=="0" (
    echo [OK] Da cai .NET Framework 4.8 thanh cong.
) else if "%NET48_RC%"=="3010" (
    echo [OK] Da cai .NET Framework 4.8 thanh cong - can khoi dong lai may de hoan tat.
) else (
    echo [LOI] Cai .NET Framework 4.8 that bai, ma loi %NET48_RC%.
    echo       Neu may la Windows 7, kiem tra lai da cai du SP1 va 2 ban va SHA-2 chua.
    pause
    exit /b 1
)

:: ---- Buoc 3: font icon best-effort ------------------------------------------
:install_font
echo.
echo [*] Kiem tra font icon emoji cho giao dien...
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "Add-Type -AssemblyName System.Drawing; $c = New-Object System.Drawing.Text.InstalledFontCollection; if ($c.Families.Name -contains 'Segoe UI Emoji') { 'yes' } else { 'no' }"`) do set "HAS_EMOJI_FONT=%%A"

if /I "%HAS_EMOJI_FONT%"=="yes" (
    echo [OK] May da co san font Segoe UI Emoji.
    goto :download_app
)

echo [*] May chua co font icon mau - se thu cai them font mien phi Noto Color
echo     Emoji giay phep OFL, duoc phep phan phoi lai de icon trong app hien
echo     day du hon. Buoc nay khong bat buoc: neu that bai, app van chay
echo     binh thuong, chi mot so icon khong hien mau.
set "EMOJI_FONT_FILE=%TEMP_DIR%\NotoColorEmoji.ttf"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; [Net.WebRequest]::DefaultWebProxy = $null; try { $wc = New-Object Net.WebClient; $wc.Proxy = $null; $wc.DownloadFile('%EMOJI_FONT_URL%', '%EMOJI_FONT_FILE%'); $shell = New-Object -ComObject Shell.Application; $folder = $shell.Namespace(0x14); $folder.CopyHere('%EMOJI_FONT_FILE%', 0x10) } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [!] Khong cai duoc font icon - bo qua, khong anh huong den viec cai app.
) else (
    echo [OK] Da thu cai font icon.
)

:: ---- Buoc 4: tai va cai dat ung dung indee ----------------------------------
:download_app
echo.
echo [*] Dang tim va tai ban indee moi nhat tu GitHub...
for /f "usebackq delims=" %%A in (`powershell -NoProfile -EncodedCommand "WwBOAGUAdAAuAFMAZQByAHYAaQBjAGUAUABvAGkAbgB0AE0AYQBuAGEAZwBlAHIAXQA6ADoAUwBlAGMAdQByAGkAdAB5AFAAcgBvAHQAbwBjAG8AbAAgAD0AIABbAE4AZQB0AC4AUwBlAGMAdQByAGkAdAB5AFAAcgBvAHQAbwBjAG8AbABUAHkAcABlAF0AOgA6AFQAbABzADEAMgAKAFsATgBlAHQALgBXAGUAYgBSAGUAcQB1AGUAcwB0AF0AOgA6AEQAZQBmAGEAdQBsAHQAVwBlAGIAUAByAG8AeAB5ACAAPQAgACQAbgB1AGwAbAAKAHQAcgB5ACAAewAKACAAIAAgACAAJABkAGkAcgAgAD0AIABKAG8AaQBuAC0AUABhAHQAaAAgACQAZQBuAHYAOgBUAEUATQBQACAAJwBJAG4AZABlAGUASQBuAHMAdABhAGwAbAAnAAoAIAAgACAAIABOAGUAdwAtAEkAdABlAG0AIAAtAEkAdABlAG0AVAB5AHAAZQAgAEQAaQByAGUAYwB0AG8AcgB5ACAALQBGAG8AcgBjAGUAIAAtAFAAYQB0AGgAIAAkAGQAaQByACAAfAAgAE8AdQB0AC0ATgB1AGwAbAAKACAAIAAgACAAJAB3AGMAIAA9ACAATgBlAHcALQBPAGIAagBlAGMAdAAgAE4AZQB0AC4AVwBlAGIAQwBsAGkAZQBuAHQACgAgACAAIAAgACQAdwBjAC4AUAByAG8AeAB5ACAAPQAgACQAbgB1AGwAbAAKACAAIAAgACAAJAB3AGMALgBIAGUAYQBkAGUAcgBzAC4AQQBkAGQAKAAnAFUAcwBlAHIALQBBAGcAZQBuAHQAJwAsACcAaQBuAGQAZQBlAC0AaQBuAHMAdABhAGwAbAAtAGMAbQBkACcAKQAKACAAIAAgACAAJABqAHMAbwBuACAAPQAgACQAdwBjAC4ARABvAHcAbgBsAG8AYQBkAFMAdAByAGkAbgBnACgAJwBoAHQAdABwAHMAOgAvAC8AYQBwAGkALgBnAGkAdABoAHUAYgAuAGMAbwBtAC8AcgBlAHAAbwBzAC8AbABhAGkALQAyAC8AcABoAG8AdABvAGMAbwBwAHkALwByAGUAbABlAGEAcwBlAHMALwBsAGEAdABlAHMAdAAnACkACgAgACAAIAAgACQAbQAgAD0AIABbAHIAZQBnAGUAeABdADoAOgBNAGEAdABjAGgAKAAkAGoAcwBvAG4ALAAgACcAIgBiAHIAbwB3AHMAZQByAF8AZABvAHcAbgBsAG8AYQBkAF8AdQByAGwAIgBcAHMAKgA6AFwAcwAqACIAKABbAF4AIgBdACoAaQBuAGQAZQBlAC0AWwBeACIAXQAqAFwALgB6AGkAcAApACIAJwApAAoAIAAgACAAIABpAGYAIAAoAC0AbgBvAHQAIAAkAG0ALgBTAHUAYwBjAGUAcwBzACkAIAB7ACAAVwByAGkAdABlAC0ASABvAHMAdAAgACcARQBSAFIATwBSADoAIABBAFMAUwBFAFQAXwBOAE8AVABfAEYATwBVAE4ARAAnADsAIABlAHgAaQB0ACAAMQAgAH0ACgAgACAAIAAgACQAdQByAGwAIAA9ACAAJABtAC4ARwByAG8AdQBwAHMAWwAxAF0ALgBWAGEAbAB1AGUAIAAtAHIAZQBwAGwAYQBjAGUAIAAnAFwAXAAvACcALAAnAC8AJwAKACAAIAAgACAAJAB6AGkAcAAgAD0AIABKAG8AaQBuAC0AUABhAHQAaAAgACQAZABpAHIAIAAnAGkAbgBkAGUAZQAuAHoAaQBwACcACgAgACAAIAAgACQAZQB4AHQAcgBhAGMAdAAgAD0AIABKAG8AaQBuAC0AUABhAHQAaAAgACQAZABpAHIAIAAnAGUAeAB0AHIAYQBjAHQAZQBkACcACgAgACAAIAAgACQAdwBjAC4ARABvAHcAbgBsAG8AYQBkAEYAaQBsAGUAKAAkAHUAcgBsACwAIAAkAHoAaQBwACkACgAgACAAIAAgAGkAZgAgACgAVABlAHMAdAAtAFAAYQB0AGgAIAAkAGUAeAB0AHIAYQBjAHQAKQAgAHsAIABSAGUAbQBvAHYAZQAtAEkAdABlAG0AIAAkAGUAeAB0AHIAYQBjAHQAIAAtAFIAZQBjAHUAcgBzAGUAIAAtAEYAbwByAGMAZQAgAH0ACgAgACAAIAAgAEEAZABkAC0AVAB5AHAAZQAgAC0AQQBzAHMAZQBtAGIAbAB5AE4AYQBtAGUAIABTAHkAcwB0AGUAbQAuAEkATwAuAEMAbwBtAHAAcgBlAHMAcwBpAG8AbgAuAEYAaQBsAGUAUwB5AHMAdABlAG0ACgAgACAAIAAgAFsAUwB5AHMAdABlAG0ALgBJAE8ALgBDAG8AbQBwAHIAZQBzAHMAaQBvAG4ALgBaAGkAcABGAGkAbABlAF0AOgA6AEUAeAB0AHIAYQBjAHQAVABvAEQAaQByAGUAYwB0AG8AcgB5ACgAJAB6AGkAcAAsACAAJABlAHgAdAByAGEAYwB0ACkACgAgACAAIAAgAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAkAGUAeAB0AHIAYQBjAHQACgAgACAAIAAgAGUAeABpAHQAIAAwAAoAfQAgAGMAYQB0AGMAaAAgAHsACgAgACAAIAAgAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAoACcARQBSAFIATwBSADoAIAAnACAAKwAgACQAXwAuAEUAeABjAGUAcAB0AGkAbwBuAC4ATQBlAHMAcwBhAGcAZQApAAoAIAAgACAAIABlAHgAaQB0ACAAMQAKAH0ACgA="`) do set "APP_EXTRACT=%%A"

echo %APP_EXTRACT% | findstr /B "ERROR:" >nul
if not errorlevel 1 (
    echo [LOI] %APP_EXTRACT%
    echo       Kiem tra ket noi mang roi chay lai install-indee.cmd.
    pause
    exit /b 1
)
if not defined APP_EXTRACT (
    echo [LOI] Khong tai/giai nen duoc ban indee moi nhat.
    pause
    exit /b 1
)
echo [OK] Da tai va giai nen: %APP_EXTRACT%

echo.
echo [*] Dang cai vao "%INSTALL_DIR%"...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
robocopy "%APP_EXTRACT%" "%INSTALL_DIR%" /E /NFL /NDL /NJH /NJS /NC /NS /NP >nul
if %errorlevel% GEQ 8 (
    echo [LOI] Khong sao chep duoc file vao "%INSTALL_DIR%".
    pause
    exit /b 1
)
echo [OK] Da cai vao "%INSTALL_DIR%".

:: ---- Buoc 5: tao shortcut ngoai Desktop -------------------------------------
echo.
echo [*] Dang tao shortcut indee ngoai Desktop...
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $desktop = [Environment]::GetFolderPath('Desktop'); $lnk = $ws.CreateShortcut([System.IO.Path]::Combine($desktop, 'indee.lnk')); $lnk.TargetPath = '%INSTALL_DIR%\indee.exe'; $lnk.WorkingDirectory = '%INSTALL_DIR%'; $lnk.IconLocation = '%INSTALL_DIR%\indee.exe'; $lnk.Save()"
if errorlevel 1 (
    echo [!] Khong tao duoc shortcut - co the tu tao thu cong tu "%INSTALL_DIR%\indee.exe".
) else (
    echo [OK] Da tao shortcut indee ngoai Desktop.
)

rmdir /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo ================================================================
echo   Cai dat hoan tat!
echo ================================================================
if defined LOG_FILE echo   Log cai dat: %LOG_FILE%
echo.
echo [*] Dang mo indee...
start "" "%INSTALL_DIR%\indee.exe"

echo.
echo Nhan phim bat ky de dong cua so nay.
pause >nul
exit /b 0
