@echo off
echo ==================================================
echo      Mess Meal Management App - Emulator Installer
echo ==================================================

REM Path to Flutter SDK
set FLUTTER_BIN=E:\Workspace\Antigravity\SDK\flutter\bin
set PATH=%PATH%;%FLUTTER_BIN%

echo.
echo [1/2] Uninstalling old version (if exists)...
call java -jar "%FLUTTER_BIN%\cache\artifacts\engine\android-x64\platform-tools\adb" uninstall com.example.mess_manager 2>nul
echo Done.

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

call flutter install -d emulator-5554 --use-application-binary "%APK_PATH%"

echo.
echo ==================================================
echo          INSTALLATION COMPLETE!
echo ==================================================
pause
