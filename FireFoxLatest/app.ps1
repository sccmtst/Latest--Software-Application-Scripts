param (
    [String]$Action
)

IF (Test-Path "$ENV:SystemDrive\Program files (x86)"){
    $URL = 'https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=#language'
    $BIT = "64"
}else{
    $URL = 'https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win&lang=#language'
    $BIT = "32"
}

Write-Host "$($Action + "ing") Mozilla Firefox Please Wait..."
$FileName = "Mozilla_Firefox_" + $BIT + ".msi"
$Script:ProgressPreference = "SilentlyContinue"
Get-Process firefox -ErrorAction SilentlyContinue | Stop-Process -Force

function Install-App {
    try {
        if (Test-Path "$PSScriptRoot\$FileName" -ErrorAction SilentlyContinue){Remove-Item "$PSScriptRoot\$FileName" -Force -ErrorAction Stop}
        Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile "$PSScriptRoot\$FileName" -ErrorAction Stop
        $Install = (Get-ChildItem | Where-Object -Property Name -like "$FileName").Name
    }
    catch {
        $Install = (Get-ChildItem | Where-Object -Property Name -like "Backup*$BIT.msi").Name
    }
    $Pros = Start-Process msiexec.exe -ArgumentList "/i $Install /QN /l* $ENV:Temp\Mozilla_Firefox_Install.log" -Wait -PassThru
    $StopCode = $($Pros.ExitCode)
}

Function Uninstall-App {
    $String = (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-Item | Get-ItemProperty | Where-Object -Property DisplayName -like "Mozilla Firefox*").UninstallString
    if ($String -eq $null) {$String = (Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-Item | Get-ItemProperty | Where-Object -Property DisplayName -like "Mozilla Firefox*").UninstallString}
    if ($String -eq $null) {Write-Host "Firefox is not installed" ; EXIT 0}
    $Pros = Start-Process $String -ArgumentList "/S" -Wait -PassThru
    $StopCode = $($Pros.ExitCode)
}

switch ($Action) {
    'Uninstall' {Uninstall-App}
    'Repair' {Uninstall-App;Install-App}
    Default {Install-app}
}

EXIT $StopCode
