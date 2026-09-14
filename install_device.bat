@echo off
echo ==================================================
echo      Mess Meal Management App - Device Installer
echo ==================================================

REM Path to Flutter SDK
set FLUTTER_BIN=E:\Workspace\Antigravity\SDK\flutter\bin
set PATH=%PATH%;%FLUTTER_BIN%

REM Device ID for TECNO CM6
set DEVICE_ID=138013857S009374

echo.
echo [1/2] Uninstalling old version (optional)...
REM Attempt to uninstall using common ADB command. Errors are ignored if ADB is not in path.
adb -s %DEVICE_ID% uninstall com.example.mess_manager 2>nul

echo.
echo [2/2] Installing new APK...
set APK_PATH=android\app\build\outputs\apk\release\app-release.apk

if not exist "%APK_PATH%" (
    REM Fallback to release_output just in case
    set APK_PATH=release_output\app-release.apk
)

echo Source: %APK_PATH%

if not exist "%APK_PATH%" (
    echo ERROR: APK not found in likely locations.
    echo Please run build_release.bat first.
    pause
    exit /b 1
)

echo Installing to Device %DEVICE_ID%...
call flutter install -d %DEVICE_ID% --use-application-binary "%APK_PATH%"

echo.
echo ==================================================
echo          INSTALLATION COMPLETE!
echo ==================================================
pause
