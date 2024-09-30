# Version 1.5.3

# Features to add in 1.3 and future versions (most to least important)
# - Detection that the script has already been ran
# - Add post-install image / instructions and open browsers with ublock origin
# - Customize autoinstall using a file which can be create trough the menu
# - Bypass appstoinstall list using an apps.whatever file to install another list of apps

param (
    [switch]$FromIRM
)

New-Item -Path $PSScriptRoot\things -Force -ItemType Directory > $null

# get and flush os ver and arch to variables
$osInfo = Get-WmiObject -Class Win32_OperatingSystem
$osVersion = $osInfo.Version
$osArchitecture = $osInfo.OSArchitecture
$NumArchitecture = $osArchitecture -replace "[^\d]", ""

#list of apps to install, put here to be easily modiffiable, app ids can be found on: https://winget.run
$global:appsToInstall = @('Mozilla.Firefox', 'videolan.vlc', 'Google.Chrome', '7zip.7zip', 'AnyDeskSoftwareGmbH.AnyDesk', "Adobe.Acrobat.Reader.${NumArchitecture}-bit")

Clear-Host

$Host.UI.RawUI.WindowTitle = "Adware Installer"

Write-Host "              _                          _____           _        _ _           "
Write-Host "     /\      | |                        |_   _|         | |      | | |          "
Write-Host "    /  \   __| |_      ____ _ _ __ ___    | |  _ __  ___| |_ __ _| | | ___ _ __ "
Write-Host "   / /\ \ / _`  \ \ /\ /  / _` | '__/ _ \   | | | '_ \/ __| __/ _`  | | |/ _ \ '__|"
Write-Host "  / ____ \ (_| |\ V  V / (_| | | |  __/  _| |_| | | \__ \ || (_| | | |  __/ |"
Write-Host " /_/    \_\__,_| \_/\_/ \__,_|_|  \___| |_____|_| |_|___/\__\__,_|_|_|\___|_|" -NoNewline; Write-Host "	Version 1.5.2 - The Update.. update?" -ForegroundColor Magenta
Write-Host ""

# simple check to see if the computer has internet, if it doesn'r then script exits
$pingResult = Test-Connection -ComputerName google.com -Count 1 -Quiet
if (-not $pingResult) {
    Write-Host "Aucun accès internet. Assurez-vous que l'ordinateur soit bien connecté."
    Write-Host "Appuyez sur une touche pour quitter..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# functions to do anything at all really
function DownloadConfiguration {
    $configUrl = "https://raw.githubusercontent.com/kaipicalt/adware-installer/main/Configuration.xml"
    $localConfigPath = "$PSScriptRoot\things\Configuration.xml"

    if (-not (Test-Path $localConfigPath)) {
        Write-Host "Le fichier Configuration.xml est introuvable, téléchargement..."
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($configUrl, $localConfigPath)
            Write-Host "Le fichier Configuration.xml a été téléchargé avec succès."
        } catch {
            Write-Host "Erreur lors du téléchargement de Configuration.xml. Error: $_"
        }
    } else {
        Write-Host "Le fichier Configuration.xml est présent."
    }
}

function SetOfficeClientEdition {
    $localConfigPath = "$PSScriptRoot\things\Configuration.xml"
    [xml]$configXml = Get-Content $localConfigPath

    $architecture = if ([System.Environment]::Is64BitOperatingSystem) { "64" } else { "32" }
    $configXml.Configuration.Add.OfficeClientEdition = $architecture

    $configXml.Save($localConfigPath)
    Write-Host "OfficeClientEdition modifié. ($architecture bits.)"
}

function Update-AdwareInstaller {
    $scriptUrl = "https://raw.githubusercontent.com/kaipicalt/adware-installer/main/adwareinstaller.ps1"
    $localScriptPath = "$PSScriptRoot\adwareinstaller.ps1"

    function Get-ScriptVersion($scriptContent) {
        $versionLine = $scriptContent | Select-String -Pattern "# Version (\d+\.\d+\.\d+)"
        if ($null -ne $versionLine) {
            return $versionLine.Matches.Groups[1].Value.Trim()
        }
        return $null
    }

    if (Test-Path $localScriptPath) {
        $localScript = Get-Content -Path $localScriptPath -Raw
        $localVersion = Get-ScriptVersion $localScript
    } else {
        $localVersion = "0.0.0"
    }

    $webClient = New-Object System.Net.WebClient
    try {
        $onlineScript = $webClient.DownloadString($scriptUrl)
        $onlineVersion = Get-ScriptVersion $onlineScript

        if ([version]$onlineVersion -gt [version]$localVersion) {
            $webClient.DownloadFile($scriptUrl, $localScriptPath)
            Write-Host "Le script adwareinstaller.ps1 est obsolète, mise à jour... Nouvelle version: $onlineVersion"
            Write-Host "Redémarrage du script..."
            Start-Sleep -Seconds 2
            Start-Process -FilePath "$PSScriptRoot\launcher.bat" -WorkingDirectory $PSScriptRoot
            exit
        }
    } catch {
        Write-Host "Erreur lors du téléchargement ou traitement du script. Error: $_"
    }
}

function Update-WingetScript {
    $githubUrl = "https://raw.githubusercontent.com/asheroto/winget-install/master/winget-install.ps1"

    $localScriptPath = "$PSScriptRoot\things\winget-install.ps1" 

    function Get-ScriptVersion($scriptContent) {
        $versionLine = $scriptContent | Select-String -Pattern "\.VERSION (\d+\.\d+\.\d+)"
        if ($null -ne $versionLine) {
            return $versionLine.Matches.Groups[1].Value.Trim()
        }
        return $null
    }

    # check local version
    if (Test-Path $localScriptPath) {
        $localScript = Get-Content -Path $localScriptPath -Raw
        $localVersion = Get-ScriptVersion $localScript
    } else {
        $localVersion = "0.0.0"  # weird hack to fix my spaghetti code, makes it so that if not found the script gets downloaded
    }

    # dl script from latest url
    $webClient = New-Object System.Net.WebClient
    try {
        $githubScript = $webClient.DownloadString($githubUrl)
        $onlineVersion = Get-ScriptVersion $githubScript

        # cmopare versions and update if local is older than latest
        if ([version]$onlineVersion -gt [version]$localVersion) {
            $webClient.DownloadFile($githubUrl, $localScriptPath)
            Write-Host "Le script winget-install est obsolète ou introuvable, mise à jour... Nouvelle version: $onlineVersion"
        } else {
            Write-Host "Le script winget-install est déjà à jour. Version: $localVersion"
        }
    } catch {

        Write-Host "Erreur lors du téléchargement ou traitement du script. Error: $_"
    }
}

function Update-OhookScript {
    try {
        # basically the same as Update-WingetScript so not commenting on this one
        $cmdUrl = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Activators/Ohook_Activation_AIO.cmd"

        $localCmdPath = "$PSScriptRoot\things\Ohook_Activation_AIO.cmd"

        function Get-CmdVersion($scriptContent) {
            $versionLine = $scriptContent | Select-String -Pattern "@set masver=(\d+\.\d+)"
            if ($null -ne $versionLine) {
                return $versionLine.Matches.Groups[1].Value.Trim()
            }
            return $null
        }

        if (Test-Path $localCmdPath) {
            $localCmd = Get-Content -Path $localCmdPath -Raw
            $localVersion = Get-CmdVersion $localCmd
        } else {
            $localVersion = "0.0"
        }


        $webClient = New-Object System.Net.WebClient
        $githubCmd = $webClient.DownloadString($cmdUrl)
        $onlineVersion = Get-CmdVersion $githubCmd

        if ([version]$onlineVersion -gt [version]$localVersion) {
            $webClient.DownloadFile($cmdUrl, $localCmdPath)
            Write-Host "Le script MAS (Ohook) est obsolète ou introuvable, mise à jour... Nouvelle version: $onlineVersion"
        } else {
            Write-Host "Le script MAS (Ohook) est déjà à jour. Version: $localVersion"

        }
    } catch {
        Write-Host "Erreur lors du téléchargement ou traitement du script. Error: $_"
    }
}

function Update-HWIDScript {
    try {
        # basically the same as Update-WingetScript so not commenting on this one
        $cmdUrl = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Activators/HWID_Activation.cmd"

        $localCmdPath = "$PSScriptRoot\things\HWID_Activation.cmd"

        function Get-CmdVersion($scriptContent) {
            $versionLine = $scriptContent | Select-String -Pattern "@set masver=(\d+\.\d+)"
            if ($null -ne $versionLine) {
                return $versionLine.Matches.Groups[1].Value.Trim()
            }
            return $null
        }

        if (Test-Path $localCmdPath) {
            $localCmd = Get-Content -Path $localCmdPath -Raw
            $localVersion = Get-CmdVersion $localCmd
        } else {
            $localVersion = "0.0"
        }


        $webClient = New-Object System.Net.WebClient
        $githubCmd = $webClient.DownloadString($cmdUrl)
        $onlineVersion = Get-CmdVersion $githubCmd

        if ([version]$onlineVersion -gt [version]$localVersion) {
            $webClient.DownloadFile($cmdUrl, $localCmdPath)
            Write-Host "Le script MAS (HWID) est obsolète ou introuvable, mise à jour... Nouvelle version: $onlineVersion"
        } else {
            Write-Host "Le script MAS (HWID) est déjà à jour. Version: $localVersion"

        }
    } catch {
        Write-Host "Erreur lors du téléchargement ou traitement du script. Error: $_"
    }
}

function CountdownTimer {
    param([int]$seconds)
    Write-Host ""
    Write-Host "Appuyez sur une touche pour acceder au menu."
    for ($i = $seconds; $i -gt 0; $i--) {
        if ($Host.UI.RawUI.KeyAvailable) {

            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            ShowMenu
            return
        }
        Write-Host -NoNewline "Démarrage dans $i... "
        Start-Sleep -Seconds 1
        Write-Host -NoNewline "`r"
    }
    Write-Host "Démarrage dans 0... "
}

function ShowMenu {
    while ($true) {
        Clear-Host
        Write-Host "Menu des options:"
        Write-Host ""
        Write-Host "1. Activer Windows"
        Write-Host "2. Activer Office"
        Write-Host "3. Installer Winget"
        Write-Host "4. Installer les applications"
        Write-Host "5. Installer Office"
        Write-Host "6. Vérifier l'installation de Winget"
        Write-Host "7. Vérifier l'installation des applications"
        Write-Host "8. Désactiver l'UAC et les applications en arrière-plan"
        Write-Host "9. Effacer les fichiers externes (Winget-Install, Configuration.xml, etc...)"
        Write-Host "0. Lancer le script normalement"
        Write-Host ""
        $choice = Read-Host "Sélectionnez une option (0-9)"

        switch ($choice) {
            1 { ActivateWindows }
            2 { ActivateOffice }
            3 { InstallWinget }
            4 { InstallApps }
            5 { InstallOffice }
            6 { CheckWinget }
            7 { CheckApps }
            8 { DisableUACBackgroundApps }
            9 { ClearDownloadedFiles }
            0 { return }
            default { Write-Host "Option invalide. Veuillez réessayer."; Start-Sleep -Seconds 2 }

        }
    }
}

function ActivateWindows {
    Write-Host "Activation de Windows."
    Write-Host ""
    & "$PSScriptRoot\things\HWID_Activation.cmd" /HWID
}

function InstallWinget {
    Write-Host "Installation de Winget."
    Write-Host ""
    & "$PSScriptRoot\things\winget-install.ps1" -Force
}

function CheckWinget {
    Write-Host "Verification de l'installation de Winget."
    Write-Host ""
    $wingetPath = "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\winget.exe"
    if (-not (Test-Path $wingetPath)) {
        Write-Host "Winget n'est pas installé correctement, le script va continuer sans l'installation des applications Winget."
        Start-Sleep -Seconds 5
    } else {
        Write-Host "Winget a été correctement installé! Le script va continuer."
        Start-Sleep -Seconds 5
    }
}

function InstallApps {
    Write-Host "Installation des applications via Winget."
    Write-Host ""
    $wingetPath = "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\winget.exe"
    if (-not (Test-Path $wingetPath)) {
        Write-Host "Winget n'est pas installé correctement. Installation des applications impossible."
        return
    }

    foreach ($app in $global:appsToInstall) {
        & $wingetPath install --id $app --accept-source-agreements --accept-package-agreements -h
    }
}

function InstallOffice {
    if ($FromIRM) {
        Write-Host "Installation de Office via Winget."
        & "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\winget.exe" install --id "Microsoft.Office" --accept-source-agreements --accept-package-agreements --override "/configure $PSScriptRoot\things\Configuration.xml"
    } else {
        Write-Host "Installation de Office."
        Write-Host ""

        $setupPath = "$PSScriptRoot\Setup.exe"
        if (-not (Test-Path $setupPath)) {
            Write-Host "Le fichier Setup.exe n'existe pas. Veuillez vérifier que le fichier est présent dans le répertoire du script."
            Start-Sleep -Seconds 5
            Write-Host "Installation de Office via Winget."
            & "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\winget.exe" install --id "Microsoft.Office" --accept-source-agreements --accept-package-agreements --override "/configure $PSScriptRoot\things\Configuration.xml"
        } else {
            Start-Process -FilePath $setupPath -WorkingDirectory $PSScriptRoot -Wait 
        }
    }
}

function ActivateOffice {
    Write-Host "Activation de Office."
    Write-Host ""
    & "$PSScriptRoot\things\Ohook_Activation_AIO.cmd" /Ohook
}

function DisableUACBackgroundApps {
    Write-Host "Désactivation de l'UAC et des applications en arrière-plan."
    Write-Host ""
    Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}' -Force -ErrorAction SilentlyContinue
    Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
    Reg Add HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications /v GlobalUserDisabled /t REG_DWORD /d 1 /f
    Start-Sleep -Seconds 5
}

function CheckApps {
    function IsAppInstalled($appName) {
        $result = & $env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\winget.exe list --id $appName
        return $result -match $appName
    }

    function IsOfficeInstalled {
        try {
            $officeVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' | Select-Object -ExpandProperty VersionToReport
            if ($officeVersion) {
                return $true
            }
        } catch {
        }
        return $false
    }

    $missingApps = @()

    foreach ($app in $global:appsToInstall) {
        if (-not (IsAppInstalled $app)) {
            $missingApps += $app
        }
    }

    if (-not (IsOfficeInstalled)) {
        $missingApps += "Microsoft.Office"
    }

    if ($missingApps) {
        Write-Host "Les applications suivantes n'ont pas été installées correctement: $($missingApps -join ', ')"
        $retry = Read-Host "Voulez-vous essayer à nouveau? (O/N)"

        if ($retry -eq "O") {
            foreach ($app in $missingApps) {
                if ($app -eq "Microsoft.Office") {
                    Write-Host "Réinstallation de Microsoft Office..."
                    InstallOffice
                } else {
                    Write-Host "Réinstallation de $app..."
                    & $env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\winget.exe install --id $app --accept-source-agreements --accept-package-agreements -h
                }
            }
        } else {
            Write-Host "Les applications n'ont pas pu être installées."
        }
    } else {
        Write-Host "Toutes les applications sont correctement installées!"
        Write-Host ""
        Write-Host "Appuyez sur une touche pour continuer..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function ClearDownloadedFiles {
    $thingsPath = "$PSScriptRoot\things"
    
    if (Test-Path $thingsPath) {
        try {
            Remove-Item -Path "$thingsPath\*" -Force -Recurse
            Write-Host ""
            Write-Host "Tous les fichiers externes ont été supprimés. Le script va maintenant redémarrer."
            Start-Sleep -Seconds 2
            Start-Process -FilePath "$PSScriptRoot\launcher.bat" -WorkingDirectory $PSScriptRoot
            exit
        } catch {
            Write-Host "Erreur lors de la suppression des fichiers. Error: $_"
        }
    }
}

#actual code starts here

function RunWin10x64 {
    Clear-Host
    ActivateWindows
    Clear-Host
    InstallWinget
    Clear-Host
    CheckWinget
    Clear-Host
    InstallApps
    Clear-Host
    InstallOffice
    Clear-Host
    ActivateOffice
    Clear-Host
    DisableUACBackgroundApps
    Clear-Host
    CheckApps
}

function RunWin11x64 {
    Write-Host "Windows 11 64-bits détecté..."
}

function RunWin10x86 {
    
}

function RunWin7x64 {
     
}

function RunWin7x86 {
     
}

#calling needed functions
if (-not $FromIRM) {
    Update-AdwareInstaller
}
Update-WingetScript
Update-OhookScript
Update-HWIDScript
DownloadConfiguration
Write-Host "---------------------------------------"
Write-Host ""
SetOfficeClientEdition
if ($FromIRM) {
    Write-Host ""
    Write-Host "Script lancé depuis IRM, Office sera installé via Winget."
}

# check os ver and arch
if ($osVersion -like "10.0.*" -and $osArchitecture -like "*64*") {
    Write-Host "Windows 10 64-bits détecté..."
    Write-Host "---------------------------------------"
    CountdownTimer -seconds 5
    RunWin10x64
} elseif ($osVersion -like "10.0.22000.*" -and $osArchitecture -like "*64*") {
    Write-Host "Windows 11 64-bits détecté..."
    CountdownTimer -seconds 5
    RunWin11x64
} elseif ($osVersion -like "10.0.*" -and $osArchitecture -like "*32*") {
    Write-Host "Windows 10 32-bits détecté..."
    CountdownTimer -seconds 5
    RunWin10x86
} elseif ($osVersion -like "6.1.*" -and $osArchitecture -like "*64*") {
    Write-Host "Windows 7 64-bits détecté..."
    CountdownTimer -seconds 5
    RunWin7x64
} elseif ($osVersion -like "6.1.*" -and $osArchitecture -like "*32*") {
    Write-Host "Windows 7 32-bits détecté..."
    CountdownTimer -seconds 5
    RunWin7x86
} else {
    Write-Host "Version de Windows ou Architecture non supportée"
    Write-Host "Appuyez sur une touche pour quitter..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
