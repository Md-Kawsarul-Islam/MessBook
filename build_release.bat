@echo off
setlocal
title Mess App Builder
color 0B
cls

echo ==================================================
echo       Mess Meal Management App - Build Tool
echo ==================================================
echo.
echo This script will:
echo 1. Delete previous output folder
echo 2. Clean Flutter builds
echo 3. Update dependencies
echo 4. Build a fresh Release APK
echo.

REM Check if flutter is in path, if not try to add it
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Flutter not found in PATH... trying to auto-locate...
    if exist "E:\Workspace\Antigravity\SDK\flutter\bin" (
        echo Found Flutter at E:\Workspace\Antigravity\SDK\flutter\bin
        set "PATH=%PATH%;E:\Workspace\Antigravity\SDK\flutter\bin"
    ) else (
        echo Could not find Flutter automatically. Please ensure it is installed.
    )
)

if exist "release_output" (
    echo Deleting old release_output folder...
    rd /s /q "release_output"
)

echo Deleting old build artifacts...
if exist "build\app\outputs\flutter-apk" rd /s /q "build\app\outputs\flutter-apk"
if exist "android\app\build\outputs\apk" rd /s /q "android\app\build\outputs\apk"

echo.

echo.
echo [1/3] Running flutter clean...
call flutter clean
if %ERRORLEVEL% NEQ 0 goto :Error

echo.
echo [2/3] Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 goto :Error

echo.
echo [3/3] Building Release APK with Obfuscation...
call flutter build apk --release --obfuscate --split-debug-info=debug_info

echo.
echo ==================================================
echo           CHECKING BUILD STATUS
echo ==================================================
echo.

set "APK_1=build\app\outputs\flutter-apk\app-release.apk"
set "APK_2=android\app\build\outputs\apk\release\app-release.apk"
set "APK_3=build\app\outputs\apk\release\app-release.apk"
set "FINAL_DIR=release_output"

set "SOURCE_APK="

if exist "%APK_1%" set "SOURCE_APK=%APK_1%"
if not defined SOURCE_APK if exist "%APK_2%" set "SOURCE_APK=%APK_2%"
if not defined SOURCE_APK if exist "%APK_3%" set "SOURCE_APK=%APK_3%"

if defined SOURCE_APK (
    echo Success! Found fresh APK at: %SOURCE_APK%
    goto :CopyAndOpen
)

echo.
echo ERROR: APK not found in any expected location.
goto :Error

:CopyAndOpen
if not exist "%FINAL_DIR%" mkdir "%FINAL_DIR%"
copy /Y "%SOURCE_APK%" "%FINAL_DIR%\app-release.apk" >nul
echo.
echo ==================================================
echo           BUILD SUCCESSFUL!
echo ==================================================
echo.
echo APK Copied to: %FINAL_DIR%\app-release.apk
echo.
echo Opening output folder...
start "" "%FINAL_DIR%"

echo.
echo Press any key to exit...
pause >nul
exit /b 0

:Error
echo.
echo ==================================================
echo           BUILD FAILED!
echo ==================================================
echo.
echo Please check the Gradle output above for errors.
pause
exit /b 1
