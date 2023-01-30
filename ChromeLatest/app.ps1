param (
    [String]$Action
)

IF (Test-Path "$ENV:SystemDrive\Program files (x86)"){
    $URL = 'https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi'
    $BIT = "64"
}else{
    $URL = 'https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise.msi'
    $BIT = "32"
}
Write-Host "$($Action + "ing") Google Chrome Please Wait..."
$Script:ProgressPreference = "SilentlyContinue"
$FileName = "Google_Chrome_Enterprise_" + $BIT + ".msi"
Get-Process Chrome -ErrorAction SilentlyContinue | Stop-Process -Force

function Install-App {
    try {
        if (Test-Path "$PSScriptRoot\$FileName" -ErrorAction SilentlyContinue){Remove-Item "$PSScriptRoot\$FileName" -Force -ErrorAction Stop}
        Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile "$PSScriptRoot\$FileName" -ErrorAction Stop
        $Install = (Get-ChildItem | Where-Object -Property Name -like "$FileName").Name
    }
    catch {
        $Install = (Get-ChildItem | Where-Object -Property Name -like "Backup*$BIT.msi").Name
    }
    $Pros = Start-Process msiexec.exe -ArgumentList "/i $Install /QN /l* $ENV:Temp\Google_Chrome_Install.log" -Wait -PassThru
    $StopCode = $($Pros.ExitCode)
}

Function Uninstall-App {
    $String = (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-Item | Get-ItemProperty | Where-Object -Property DisplayName -like "Google Chrome*").UninstallString
    if ($String -eq $null) {$String = (Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-Item | Get-ItemProperty | Where-Object -Property DisplayName -like "Google Chrome*").UninstallString}
    if ($String -eq $null) {Write-Host "Google Chrome is not installed" ; EXIT 0}
    $CODE = $String.Substring($($String.IndexOf("{")))
    $Pros = Start-Process msiexec.exe -ArgumentList "/X $CODE /QN /NORESTART /l* $ENV:Temp\Google_Chrome_Uninstall.log" -Wait -PassThru
    $StopCode = $($Pros.ExitCode)
}

switch ($Action) {
    'Uninstall' {Uninstall-App}
    'Repair' {Uninstall-App;Install-App}
    Default {Install-app}
}

EXIT $StopCode
