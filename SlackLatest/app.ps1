param (
    [String]$Action
)

IF (Test-Path "$ENV:SystemDrive\Program files (x86)"){
    $URL = 'https://slack.com/ssb/download-win64-msi'
    $BIT = "64"
}else{
    $URL = 'https://slack.com/ssb/download-win-msi'
    $BIT = "32"
}
Write-Host "$($Action + "ing") Slack Please Wait..."
$FileName = "Slack_" + $BIT + ".msi"
Get-Process slack -ErrorAction SilentlyContinue | Stop-Process -Force 

function Install-App {
    try {
        if (Test-Path "$PSScriptRoot\$FileName" -ErrorAction SilentlyContinue){Remove-Item "$PSScriptRoot\$FileName" -Force -ErrorAction Stop}
        Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile "$PSScriptRoot\$FileName" -ErrorAction Stop
        $Install = (Get-ChildItem | Where-Object -Property Name -like "$FileName").Name
    }
    catch {
        $Install = (Get-ChildItem | Where-Object -Property Name -like "Backup*$BIT.msi").Name
    }
    $Pros = Start-Process msiexec.exe -ArgumentList "/i $Install /QN /l* $ENV:Temp\Slack_Install.log" -Wait -PassThru
    IF ($($Pros.ExitCode) -ne 0){EXIT $Pros}
}

Function Uninstall-App {
    #Google Keeps switching there uninstall string location this will find it no matter what 
    $String = (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-Item | Get-ItemProperty | Where-Object -Property DisplayName -like "*Slack (Machine)*").UninstallString
    if ($String -eq $null) {$String = (Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-Item | Get-ItemProperty | Where-Object -Property DisplayName -like "*Slack (Machine)*").UninstallString}
    if ($String -eq $null) {Write-Host "Slack is not installed" ; EXIT 0}
    $CODE = $String.Substring($($String.IndexOf("{")))
    $Pros = Start-Process msiexec.exe -ArgumentList "/X $CODE /QN /NORESTART /l* $ENV:Temp\Slack_Uninstall.log" -Wait -PassThru
    IF ($($Pros.ExitCode) -ne 0){EXIT $Pros}
}

Function Repair-App {
    Uninstall-App
    Install-App
}

switch ($Action) {
    'Uninstall' {Uninstall-App}
    'Repair' {Repair-App}
    Default {Install-app}
}