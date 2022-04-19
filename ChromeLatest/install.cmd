@ECHO off
cd /d %~dp0
SET val=%1
IF [%1] EQU [] SET val=INSTALL
PowerShell.exe -ExecutionPolicy Bypass -NoProfile -Command ".\app.ps1 -Action %val%"
