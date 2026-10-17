@echo off
chcp 65001 >nul
setlocal
title CC Switch - Restauration d'origine

set "HERE=%~dp0"
set "TARGET=%LOCALAPPDATA%\Programs\CC Switch"
if defined CCTARGET set "TARGET=%CCTARGET%"
set "SETTINGS=%USERPROFILE%\.cc-switch\settings.json"

echo.
echo  Restauration de CC Switch d'origine
echo  -----------------------------------
echo.

if not exist "%HERE%old\cc-switch.exe" (
  echo [ERREUR] old\cc-switch.exe est manquant : impossible de restaurer.
  pause
  exit /b 1
)

taskkill /f /im cc-switch.exe >nul 2>&1
timeout /t 2 /nobreak >nul

copy /y "%HERE%old\cc-switch.exe" "%TARGET%\cc-switch.exe" >nul
if errorlevel 1 (
  echo [ERREUR] La restauration a echoue.
  pause
  exit /b 1
)

if exist "%HERE%old\settings.json" (
  copy /y "%HERE%old\settings.json" "%SETTINGS%" >nul
)

echo  Version d'origine restauree.
start "" "%TARGET%\cc-switch.exe"
timeout /t 3 /nobreak >nul
exit /b 0
