@echo off
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' (
    PowerShell.exe -ExecutionPolicy Bypass -File "%~dp0adwareinstaller.ps1"
) else (
    echo Script needs to be launched as admin...
    PowerShell.exe -Command "Start-Process '%comspec%' -Verb RunAs -ArgumentList '/c %~dpnx0'"
)