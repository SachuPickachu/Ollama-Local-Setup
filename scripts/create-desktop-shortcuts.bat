@echo off
REM =============================================================================
REM Create Desktop Shortcuts for Local LLM Stack
REM =============================================================================
REM This batch file creates Windows desktop shortcuts for start-all and stop-all scripts

echo Creating Desktop Shortcuts for Local LLM Stack (Fixed Version)
echo =============================================================
echo.

REM Get the script directory and project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."

REM Get desktop path
for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Desktop 2^>nul') do set "DESKTOP_PATH=%%b"

echo Desktop Path: %DESKTOP_PATH%
echo.

REM Create start-all shortcut
echo Creating Start All shortcut...
set "START_SCRIPT=%PROJECT_ROOT%\scripts\start-all.ps1"
set "START_SHORTCUT=%DESKTOP_PATH%\Start Local LLM.lnk"

echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\CreateShortcut.vbs"
echo sLinkFile = "%START_SHORTCUT%" >> "%TEMP%\CreateShortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\CreateShortcut.vbs"
echo oLink.TargetPath = "powershell.exe" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.Arguments = "-ExecutionPolicy Bypass -NoProfile -Command ""Set-Location '%PROJECT_ROOT%'; . '%PROJECT_ROOT%\config\env.ps1'; & '%START_SCRIPT%'""" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.WorkingDirectory = "%PROJECT_ROOT%" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.Description = "Start Ollama and Open WebUI services" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.Save >> "%TEMP%\CreateShortcut.vbs"

cscript //nologo "%TEMP%\CreateShortcut.vbs"
if exist "%START_SHORTCUT%" (
    echo ✓ Start Local LLM shortcut created successfully
) else (
    echo ✗ Failed to create Start Local LLM shortcut
)

REM Create stop-all shortcut
echo Creating Stop All shortcut...
set "STOP_SCRIPT=%PROJECT_ROOT%\scripts\stop-all.ps1"
set "STOP_SHORTCUT=%DESKTOP_PATH%\Stop Local LLM.lnk"

echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\CreateShortcut2.vbs"
echo sLinkFile = "%STOP_SHORTCUT%" >> "%TEMP%\CreateShortcut2.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\CreateShortcut2.vbs"
echo oLink.TargetPath = "powershell.exe" >> "%TEMP%\CreateShortcut2.vbs"
echo oLink.Arguments = "-ExecutionPolicy Bypass -NoProfile -Command ""Set-Location '%PROJECT_ROOT%'; . '%PROJECT_ROOT%\config\env.ps1'; & '%STOP_SCRIPT%'""" >> "%TEMP%\CreateShortcut2.vbs"
echo oLink.WorkingDirectory = "%PROJECT_ROOT%" >> "%TEMP%\CreateShortcut2.vbs"
echo oLink.Description = "Stop Ollama and Open WebUI services" >> "%TEMP%\CreateShortcut2.vbs"
echo oLink.Save >> "%TEMP%\CreateShortcut2.vbs"

cscript //nologo "%TEMP%\CreateShortcut2.vbs"
if exist "%STOP_SHORTCUT%" (
    echo ✓ Stop Local LLM shortcut created successfully
) else (
    echo ✗ Failed to create Stop Local LLM shortcut
)

REM Clean up temporary files
del "%TEMP%\CreateShortcut.vbs" 2>nul
del "%TEMP%\CreateShortcut2.vbs" 2>nul

echo.
echo Summary:
echo ========
echo ✓ Start Local LLM shortcut created successfully
echo ✓ Stop Local LLM shortcut created successfully
echo.
echo Shortcuts created on desktop:
echo - Start Local LLM: Double-click to start all services
echo - Stop Local LLM: Double-click to stop all services
echo.
echo Note: You may need to right-click and 'Run as Administrator' if you encounter permission issues.
echo.
pause
