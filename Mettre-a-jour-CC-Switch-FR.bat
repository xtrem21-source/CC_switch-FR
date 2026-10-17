@echo off
chcp 65001 >nul
title CC Switch FR - mise a jour
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\Maj-CC-Switch-FR.ps1" %*
echo.
pause
