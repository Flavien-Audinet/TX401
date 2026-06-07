@echo off
:: Script batch pour lancer TX401_ConfigTool.ps1 avec élévation

set "scriptPath=%~dp0TX401_ConfigTool.ps1"

if not exist "%scriptPath%" (
    echo ❌ Le fichier TX401_ConfigTool.ps1 est introuvable dans ce dossier.
    pause
    exit /b
)

powershell -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File "%scriptPath%"' -Verb RunAs"
