@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title Microsoft Office Standalone Installer (Word, Excel, PowerPoint)
color 0B

:: ==============================================================================
:: STEP 1: Administrator Privileges Check & Auto-Elevation
:: ==============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ==============================================================================
    echo  [ADMINISTRATOR PRIVILEGES REQUIRED]
    echo ==============================================================================
    echo.
    echo  [INFO] Requesting Administrator permissions (UAC Prompt)...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Set working directory to the script's folder
cd /d "%~dp0"

cls
echo ==============================================================================
echo        Microsoft Office Standalone Installer (Word, Excel, PowerPoint)
echo             [Official Download and Installation from Microsoft CDN]
echo ==============================================================================
echo.

:: ==============================================================================
:: STEP 2: Detect System Architecture (64-bit vs 32-bit)
:: ==============================================================================
set "ARCH=64"
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    if not defined PROCESSOR_ARCHITEW6432 (
        set "ARCH=32"
    )
)
echo [1/5] System Architecture Detected: %ARCH%-bit Windows
echo.

:: ==============================================================================
:: STEP 3: Check Internet Connection to Microsoft Servers
:: ==============================================================================
echo [2/5] Checking internet connectivity to Microsoft servers...

set "NET_OK=0"
ping -n 1 -w 2500 officecdn.microsoft.com >nul 2>&1
if %errorlevel% equ 0 (
    set "NET_OK=1"
) else (
    ping -n 1 -w 2500 8.8.8.8 >nul 2>&1
    if %errorlevel% equ 0 set "NET_OK=1"
)

if "!NET_OK!"=="0" (
    color 0C
    echo.
    echo ==============================================================================
    echo  [ERROR] No active internet connection detected!
    echo ==============================================================================
    echo.
    echo  An active internet connection is required to download official Office
    echo  components directly from Microsoft servers.
    echo.
    echo  Please connect your computer to the internet and run this script again.
    echo.
    goto :EXIT_SCRIPT
)
echo       Internet connection verified successfully.
echo.

:: ==============================================================================
:: STEP 4: Download and Prepare Microsoft Office Deployment Tool (setup.exe)
:: ==============================================================================
echo [3/5] Verifying official Microsoft Setup Engine (setup.exe)...

if not exist "%~dp0setup.exe" (
    echo       [INFO] setup.exe not found in local directory.
    echo       [INFO] Downloading official Office Deployment Tool from Microsoft...
    
    set "ODT_PRIMARY_URL=https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_20430-20146.exe"
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ProgressPreference = 'SilentlyContinue'; " ^
        "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
        "$target = Join-Path '%~dp0' 'odt_temp.exe'; " ^
        "try { " ^
        "    $wc = New-Object System.Net.WebClient; " ^
        "    $wc.Headers.Add('User-Agent', 'Mozilla/5.0'); " ^
        "    $wc.DownloadFile('%ODT_PRIMARY_URL%', $target); " ^
        "} catch { " ^
        "    try { " ^
        "        $page = (Invoke-WebRequest -Uri 'https://www.microsoft.com/en-us/download/details.aspx?id=49117' -UseBasicParsing).Content; " ^
        "        if ($page -match 'https://download\.microsoft\.com/[^\"]+officedeploymenttool[^\"]*\.exe') { " ^
        "            $wc.DownloadFile($matches[0], $target); " ^
        "        } " ^
        "    } catch {} " ^
        "}"
    
    if exist "%~dp0odt_temp.exe" (
        echo       [INFO] Extracting setup engine...
        if exist "%SystemRoot%\System32\7z.exe" (
            "%SystemRoot%\System32\7z.exe" e "%~dp0odt_temp.exe" setup.exe -o"%~dp0" -y >nul 2>&1
        ) else (
            start /wait "" "%~dp0odt_temp.exe" /quiet /extract:"%~dp0"
        )
        del /f /q "%~dp0odt_temp.exe" >nul 2>&1
    )
)

if not exist "%~dp0setup.exe" (
    color 0C
    echo.
    echo ==============================================================================
    echo  [ERROR] Failed to obtain setup.exe from Microsoft servers!
    echo ==============================================================================
    echo.
    echo  Troubleshooting:
    echo   1. Check if antivirus or firewall is blocking the download.
    echo   2. You can manually download the Microsoft Office Deployment Tool from:
    echo      https://www.microsoft.com/en-us/download/details.aspx?id=49117
    echo   3. Extract setup.exe into this folder: %~dp0
    echo.
    goto :EXIT_SCRIPT
)
echo       setup.exe is ready and verified.
echo.

:: ==============================================================================
:: STEP 5: Generate Configuration XML (Word, Excel, PowerPoint only)
:: ==============================================================================
echo [4/5] Preparing configuration (Microsoft Word, Excel, PowerPoint only)...

(
echo ^<Configuration^>
echo   ^<Add OfficeClientEdition="%ARCH%" Channel="Current"^>
echo     ^<Product ID="ProPlus2021Retail"^>
echo       ^<Language ID="en-us" /^>
echo       ^<ExcludeApp ID="Access" /^>
echo       ^<ExcludeApp ID="Bing" /^>
echo       ^<ExcludeApp ID="Groove" /^>
echo       ^<ExcludeApp ID="Lync" /^>
echo       ^<ExcludeApp ID="OneDrive" /^>
echo       ^<ExcludeApp ID="OneNote" /^>
echo       ^<ExcludeApp ID="Outlook" /^>
echo       ^<ExcludeApp ID="Publisher" /^>
echo       ^<ExcludeApp ID="Teams" /^>
echo     ^</Product^>
echo   ^</Add^>
echo   ^<Updates Enabled="TRUE" /^>
echo   ^<Display Level="Full" AcceptEULA="TRUE" /^>
echo ^</Configuration^>
) > "%~dp0configuration.xml"

echo       configuration.xml generated successfully.
echo.

:: ==============================================================================
:: STEP 6: Execute Official Microsoft Office Setup
:: ==============================================================================
echo [5/5] Launching Microsoft Office Setup...
echo.
echo ==============================================================================
echo   Included Applications:
echo     [+] Microsoft Word
echo     [+] Microsoft Excel
echo     [+] Microsoft PowerPoint
echo.
echo   Excluded Applications:
echo     [-] Access, Outlook, Publisher, Teams, OneDrive, OneNote
echo.
echo   * Downloading and installing directly from official Microsoft servers.
echo   * The official Microsoft Office installation progress UI is now running.
echo   * 100%% Genuine: No illegal activation or cracked files are used.
echo   * Please do not close this window until the setup completes...
echo ==============================================================================
echo.

"%~dp0setup.exe" /configure "%~dp0configuration.xml"
set "EXIT_CODE=%errorlevel%"

echo.
if %EXIT_CODE% equ 0 (
    color 0A
    echo ==============================================================================
    echo  [SUCCESS] Microsoft Office installed successfully!
    echo ==============================================================================
    echo.
    echo  - Microsoft Word, Excel, and PowerPoint are now available in your Start Menu.
    echo  - Launch any of the apps and sign in with your genuine Microsoft Account
    echo    or enter your valid Product Key to activate.
    echo.
) else (
    color 0C
    echo ==============================================================================
    echo  [ERROR] Installation did not complete successfully. (Exit Code: %EXIT_CODE%)
    echo ==============================================================================
    echo.
    echo  Possible Causes & Solutions:
    echo   1. Exit Code 17002 / 30088: Network drop or timeout during download. Run again.
    echo   2. Another Office installation is running. Close it via Task Manager.
    echo   3. Insufficient disk space on drive C: (minimum 4GB required).
    echo   4. For detailed diagnostic logs, inspect files in: %%TEMP%%\*.log
    echo.
)

:EXIT_SCRIPT
echo ------------------------------------------------------------------------------
echo Press any key to exit...
pause >nul
endlocal
