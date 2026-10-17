@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title CC Switch - Application du patch francais

set "HERE=%~dp0"
set "TARGET=%LOCALAPPDATA%\Programs\CC Switch"
if defined CCTARGET set "TARGET=%CCTARGET%"
set "SETTINGS=%USERPROFILE%\.cc-switch\settings.json"

echo.
echo  CC Switch - version francaise
echo  -----------------------------
echo  Cible    : %TARGET%
echo.

if not exist "%TARGET%\cc-switch.exe" (
  echo [ERREUR] CC Switch est introuvable dans le dossier cible.
  echo          Verifiez que le programme est bien installe.
  pause
  exit /b 1
)
if not exist "%HERE%patch\cc-switch.exe" (
  echo [ERREUR] Le fichier patch\cc-switch.exe est manquant.
  pause
  exit /b 1
)

echo [1/4] Fermeture de CC Switch...
taskkill /f /im cc-switch.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/4] Sauvegarde de l'installation actuelle...
if not exist "%HERE%old\cc-switch.exe" (
  copy /y "%TARGET%\cc-switch.exe" "%HERE%old\cc-switch.exe" >nul
)
if exist "%SETTINGS%" if not exist "%HERE%old\settings.json" (
  copy /y "%SETTINGS%" "%HERE%old\settings.json" >nul
)

echo [3/4] Copie de la version francaise...
copy /y "%HERE%patch\cc-switch.exe" "%TARGET%\cc-switch.exe" >nul
if errorlevel 1 (
  echo [ERREUR] La copie a echoue. Fermez CC Switch puis reessayez.
  pause
  exit /b 1
)

echo [4/4] Passage de l'interface en francais...
if exist "%SETTINGS%" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:USERPROFILE '.cc-switch\settings.json'; if(Test-Path -LiteralPath $p){ $j=Get-Content -LiteralPath $p -Raw | ConvertFrom-Json; if($j.PSObject.Properties.Name -contains 'language'){ $j.language='fr' } else { $j | Add-Member -NotePropertyName language -NotePropertyValue 'fr' }; $txt=$j | ConvertTo-Json -Depth 30; [IO.File]::WriteAllText($p,$txt,(New-Object System.Text.UTF8Encoding($false))) }"
)

echo.
echo  Termine. CC Switch va s'ouvrir en francais.
start "" "%TARGET%\cc-switch.exe"
timeout /t 3 /nobreak >nul
exit /b 0
