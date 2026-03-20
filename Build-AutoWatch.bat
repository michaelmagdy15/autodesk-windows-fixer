@echo off
echo Initiating Auto-Build Watcher...
echo Every time you save Clean-Autodesk.ps1, it will automatically rebuild Autodesk-Fixer.exe!
echo ----------------------------------------------------
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0build.ps1" -Watch
pause
