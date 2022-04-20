param (
    [String]$Action
)

IF (Test-Path "$ENV:SystemDrive\Program files (x86)"){
    $URL = (Invoke-RestMethod -Uri 'https://update.code.visualstudio.com/api/update/win32-x64/stable/version' -Method Default -UseBasicParsing).url
    $BIT = "64"
}else{
    $URL = (Invoke-RestMethod -Uri 'https://update.code.visualstudio.com/api/update/win32/stable/version' -Method Default -UseBasicParsing).url
    $BIT = "32"
}
Write-Host "$($Action + "ing") Microsoft VSCode Please Wait..."
$FileName = "Microsoft_VSCode_" + $BIT + ".exe"
Get-Process code -ErrorAction SilentlyContinue | Stop-Process -Force 

function Install-App {
    try {
        if (Test-Path "$PSScriptRoot\$FileName" -ErrorAction SilentlyContinue){Remove-Item "$PSScriptRoot\$FileName" -Force -ErrorAction Stop}
        Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile "$PSScriptRoot\$FileName" -ErrorAction Stop
        $Install = (Get-ChildItem | Where-Object -Property Name -like "$FileName").Name
    }
    catch {
        $Install = (Get-ChildItem | Where-Object -Property Name -like "Backup*$BIT.exe").Name
    }
    $Pros = Start-Process $FileName -ArgumentList "/silent /FORCECLOSEAPPLICATIONS /mergetasks='!runcode,addcontextmenufiles,associatewithfiles,addtopath' /LOG=""$ENV:Temp\Microsoft_VSCode_Install.log""" -Wait -PassThru
    IF ($($Pros.ExitCode) -ne 0){EXIT $Pros}
}

Function Uninstall-App {
    #Google Keeps switching there uninstall string location this will find it no matter what 
    $String = (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-Item | Get-ItemProperty | Where-Object -Property DisplayName -like "Microsoft Visual Studio Code").UninstallString
    if ($String -eq $null) {$String = (Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-Item | Get-ItemProperty | Where-Object -Property DisplayName -like "Microsoft Visual Studio Code").UninstallString}
    if ($String -eq $null) {Write-Host "Microsoft VSCode is not installed" ; EXIT 0}
    $Pros = Start-Process $String -ArgumentList "/SILENT /FORCECLOSEAPPLICATIONS /LOG=""$ENV:Temp\Microsoft_VSCode_Uninstall.log""" -Wait -PassThru
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