@echo off
setlocal enabledelayedexpansion

:: --- 1. Auto Minimize ---
if not "%1"=="min" (
    start /min cmd /c ""%~f0" min"
    exit
)

:: --- 2. Clean up old processes ---
:: Kills any leftover guardian process from a previous run
taskkill /F /FI "WINDOWTITLE eq Aria2_NoSleep_Guardian" >nul 2>&1

:: --- 3. Set Working Directory ---
:: Hardcoded path for desktop usage: D:\Software\aria2
if exist "D:\Software\aria2" (
    cd /d "D:\Software\aria2"
) else (
    echo [ERROR] Path D:\Software\aria2 not found.
    echo Please check if the directory exists.
    pause
    exit
)

title Aria2 Downloading Service
echo ========================================
echo            Aria2 Starting...
echo ========================================

:: --- 4. Start Smart Sleep Prevention ---
:: Using decimal 2147483649 (equivalent to 0x80000001) to avoid PowerShell type casting errors.
:: Effect: Prevents system sleep (ES_SYSTEM_REQUIRED), but allows display to turn off.
echo [INFO] Enabling smart sleep prevention...

set "GuardianCmd=$host.UI.RawUI.WindowTitle='Aria2_NoSleep_Guardian'; $code='[DllImport(\"kernel32.dll\")]public static extern void SetThreadExecutionState(uint esFlags);'; $type=Add-Type -MemberDefinition $code -Name Sys -Namespace Win32 -PassThru; $type::SetThreadExecutionState(2147483649); Start-Sleep 3; while(Get-Process aria2c -ErrorAction SilentlyContinue){Start-Sleep 10}"

start "Aria2_NoSleep_Guardian" /min powershell -WindowStyle Hidden -Command "%GuardianCmd%"

:: --- 5. Check Session File ---
if not exist "aria2.session" (
    echo [INFO] Creating aria2.session...
    type nul > aria2.session
)

echo [INFO] Aria2 is running...
echo [INFO] Guardian is monitoring aria2c process.
echo.

:: --- 6. Run Aria2 (Main Process) ---
:: aria2c will run in the working directory set in Section 3
aria2c.exe --conf-path=aria2.conf

:: --- 7. Exit & Cleanup ---
:: When aria2c closes, kill the invisible guardian process
taskkill /F /FI "WINDOWTITLE eq Aria2_NoSleep_Guardian" >nul 2>&1