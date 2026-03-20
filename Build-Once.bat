@echo off
echo Packaging Clean-Autodesk.ps1 into Autodesk-Fixer.exe...
echo ----------------------------------------------------
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0build.ps1"
pause
