
@echo off
setlocal

:: Create backups folder if it doesn't exist
if not exist "backups" mkdir "backups"

:: Get timestamp in MM-dd-yy_HH-mm format
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format 'MM-dd-yy_HH-mm'"') do set "TIMESTAMP=%%a"

set "ZIP_NAME=%TIMESTAMP%-backup.zip"

:: Compress the files/folders directly into .\backups
powershell -NoProfile -Command "Compress-Archive -Path 'scenes', 'scripts', '.editorconfig', 'project.godot' -DestinationPath 'backups\%ZIP_NAME%' -Force"

echo Created: backups\%ZIP_NAME%