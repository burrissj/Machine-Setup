
#------------------------------------------------------
# Name:        Setup
# Purpose:     Base Install for App or SQL Server
# Author:      John Burriss
# Created:     8/26/2019  5:24 PM 
#Version:      0.06
#------------------------------------------------------
#Requires -RunAsAdministrator

set-ExecutionPolicy Unrestricted


$Path = "c:\setup\setup.log"

Get-Process Powershell  | Where-Object { $_.ID -ne $pid } | Stop-Process

if (!(Test-Path $Path)) { 
    New-Item -ItemType File -Path "c:\setup\setup.log"
}

$Internet = PING.EXE 8.8.8.8
if ($internet -contains "Packets: Sent = 4, Received = 4" -or "Packets: Sent = 4, Received = 3") { 
    Install-PackageProvider -Name NuGet -Force | Out-Null
}
Else {

    $RepositoryName = "Temp"
    $Path = "C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules"

    $exists = Test-Path "filesystem::$path"
    if (!($exists)) {
        throw "Repository $path is offline"
    }

    $Existing = Get-PSRepository -Name $RepositoryName -ErrorAction Ignore

    if ($null -eq $Existing) {
        Register-PSRepository -Name $RepositoryName -SourceLocation $Path -ScriptSourceLocation $Path -InstallationPolicy Trusted

    }
    
    $error.clear()
    Install-PackageProvider -Name NuGet -ErrorAction SilentlyContinue -Force
}

$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json

$AutoLoginChoice = $Settings.general.ENABLEAUTOLOGON
if ($AutoLoginChoice -match "y") {
    $Autologon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $Password = Read-Host "Please enter the Password for the current account" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $TempPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    $autologonexe = "C:\setup\bin\Autologon.exe"
    $username = "$env:USERNAME"
    $domain = "$env:COMPUTERNAME"
    
    Start-Process $autologonexe -ArgumentList "/accepteula", $username, $domain, $Temppassword -PassThru
    Clear-Variable -name TempPassword

    if ($ServerType -match "app" -or "standalone") {

        Set-ItemProperty $Autologon "AutoLogonCount" -Value "3" -type dword
    }
    elseif ($ServerType -match "sql") {

        Set-ItemProperty $Autologon "AutoLogonCount" -Value "2" -type dword  
    }

}

# Checking Windows version
if ((Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object ProductName -ExpandProperty ProductName) -match "Windows 10") {
    $windowsVersion = "win10"
}
else {
    $windowsVersion = "other"
}

Start-Transcript -Path "c:\setup\setup.log"

$ServerType = $Settings.general.SERVERTYPE 

$Readhost = $Settings.general.NAMEMACHINE
Switch ($ReadHost) { 
    Y {
        try {
            $ComputerName = $Settings.general.MACHINENAME
            if ($ComputerName -ne $env:computername) {
                Rename-Computer -NewName $ComputerName
                Write-Host "Machine has been renamed: $ComputerName" -ForegroundColor Green 
            }
        }             
        catch {
            Write-Host "Failed to name the machine" -ForegroundColor Red
        }
        ; $PublishSettings = $true
    } 

    N { Write-Host "Machines Name is:$env:computername" -ForegroundColor Green; $PublishSettings -eq $false } 
    Default { Write-Host "Machines Name is:$env:computername" -ForegroundColor Green; $PublishSettings -eq $false } 
} 

$TimeZone = $Settings.general.TIMEZONE

if ($TimeZone -match "est") {
    Set-TimeZone -Name "Eastern Standard Time"
}
elseif ($TimeZone -match "cst") {
    Set-TimeZone -Name "Central Standard Time"
}
elseif ($TimeZone -match "MST") {
    Set-TimeZone -Name "Mountain Standard Time"
}
elseif ($TimeZone -match "PST") {
    Set-TimeZone -Name "Pacific Standard Time"
}
elseif ($TimeZone -match "AST") {
    Set-TimeZone -Name "Alaskan Standard Time"
}
elseif ($TimeZone -match "HST") {
    Set-TimeZone -Name "Hawaiian Standard Time"
}
else {
    Write-Host "Selection was not valid. Please change Timezone Manually" -ForegroundColor red
}


#Set Power Settings
try {
    Powercfg -setacvalueindex scheme_current sub_processor 45bcc044-d885-43e2-8605-ee0ec6e96b59 100
    Powercfg -setactive scheme_current
    Powercfg -setacvalueindex scheme_current sub_processor 893dee8e-2bef-41e0-89c6-b55d0929964c 100
    Powercfg -setactive scheme_current
    Powercfg -setacvalueindex scheme_current sub_processor bc5038f7-23e0-4960-96da-33abaf5935ec 100
    Powercfg -setactive scheme_current
    powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    Powercfg -setactive scheme_current
    POWERCFG.EXE /S SCHEME_MIN
    Powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100
    Powercfg -setactive scheme_current
    Powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMIN 100
    Powercfg -setactive scheme_current
    Powercfg -setacvalueindex scheme_current sub_processor PERFBOOSTMODE 2
    Powercfg -setactive scheme_current
    Write-Host "Power Setthings have been applied." -ForegroundColor Green
}
Catch {
    Write-Host "Failed to set Power Settings" -ForegroundColor Red 
}

#Disable IE Enhanced Security and UAC
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}
function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force
    Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green    
}
try {
    Disable-UserAccessControl
}
Catch {
    Write-Host "Failed to Disable UAC" -ForegroundColor Red
}
if (($windowsVersion) -match "other") {
    try {
        Disable-InternetExplorerESC
    }
    Catch {
        Write-Host "Failed to disable IE Enhanced Security" -ForegroundColor Red
    }
}
#Disable Firewall
Try {
    Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
    Write-Host "Firewall Disabled" -ForegroundColor Green
}
Catch {
    Write-Host "Failed to Disable the Firewall" -ForegroundColor Red
}
#Enable RDP
Try {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\" -Name "fDenyTSConnections" -Value 0
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\" -Name "UserAuthentication" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Write-Host "Remote Desktop has been enabled" -ForegroundColor Green
}
Catch {
    Write-Host "Failed to enable RDP"
}

#Enables .net 3.5
Write-Host "Enabling .net 3.5" -ForegroundColor Yellow
Add-WindowsCapability –Online -Name NetFx3~~~~ –Source c:\setup\bin\.net
Write-Host "Enabled .net 3.5" -ForegroundColor Green

#Calls script to setup SQL
If ($ServerType -eq "sql") {
    $SQLDriveSetup = "C:\Setup\bin\sql\SQLDriveSetup.ps1"
    & $SQLDriveSetup -Wait

    if ($Settings.general.CLEANUP -match "y") {
        Write-Host "Setting Machine to Cleanup on Next Boot" -ForegroundColor Green
        $RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        Set-ItemProperty $RunOnceKey "NextRun" "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Unrestricted -File C:\Setup\bin\Cleanup.ps1"
    }
}

#Sets Script to continue to install Nvidia Driver
if ($ServerType -match "app") {
    
    $RemoveNvidiaDriver = $Settings.GPU.REMOVECURRENTDRIVER

    if($RemoveNvidiaDriver -match "y"){
        C:\setup\bin\NvidiaDriverRemover.ps1
    }

    Write-Host "Setting Nvidia driver to install on next boot" -ForegroundColor Green
    $RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    Set-ItemProperty $RunOnceKey "NextRun" "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Unrestricted -File C:\Setup\bin\NvidiaInstaller.ps1"
}
if ($ServerType -match "standalone") {

    $CurrentUser = $env:USERDOMAIN + '\' + $env:USERNAME
    Write-Host "Creating Local User Groups" -ForegroundColor Yellow
    New-LocalGroup -Name "RayStation-Users"
    New-LocalGroup -Name "RayStation-Administrators"
    New-LocalGroup -Name "RayStation-BeamCommissioning"
    New-LocalGroup -Name "RayStation-PlanApproval"
    Write-Host "Finished Creating Local Groups" -ForegroundColor Green

    Write-Host "Adding Current User to RayStation Groups" -ForegroundColor "Yellow"
    Add-LocalGroupMember -Group "RayStation-Users" -Member "$CurrentUser"
    Add-LocalGroupMember -Group "RayStation-Administrators" -Member "$CurrentUser"
    Add-LocalGroupMember -Group "RayStation-BeamCommissioning" -Member "$CurrentUser"
    Add-LocalGroupMember -Group "RayStation-PlanApproval" -Member "$CurrentUser"
    Write-Host "Finished Adding Current User to RayStation Groups" -ForegroundColor Green

    $RemoveNvidiaDriver = $Settings.GPU.REMOVECURRENTDRIVER
    if($RemoveNvidiaDriver = $Settings.GPU.REMOVECURRENTDRIVER -match "y"){
        C:\setup\bin\NvidiaDriverRemover.ps1
    }

    Write-Host "Setting Nvidia to run on next boot" -ForegroundColor Green
    $RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    Set-ItemProperty $RunOnceKey "NextRun" "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Unrestricted -File C:\Setup\bin\NvidiaInstaller.ps1"
    $SQLDriveSetup = "C:\Setup\bin\sql\SQLDriveSetup.ps1"
    & $SQLDriveSetup -Wait

}


#Sets up the Switch to Install the Citrix VDA
$CitrixInstall = $Settings.CITRIX.INSTALLCITRIX
Switch ($CitrixInstall) { 
    Y {
        C:\setup\bin\CitrixInstall.ps1
    }
    N {
        Write-Host "Skipping Citrix VDA Install" -ForegroundColor Green
    }
    Default {
        Write-Host "Skipping Citrix VDA Install" -ForegroundColor Green
    }
}


$INSTALLBASESOFTWARE = $Settings.General.INSTALLBASESOFTWARE

Switch ($INSTALLBASESOFTWARE) {
    Y{
#Write-Host "Installing 7Zip" -ForegroundColor Yellow
#Installs 7Zip
#C:\Setup\bin\7Zip\7z1900-x64.msi /q INSTALLDIR="C:\Program Files\7-Zip"
#Write-Host "Finished Installing 7Zip" -ForegroundColor Green

#Installs Java
$Internet = PING.EXE 8.8.8.8
if ($internet -contains "Packets: Sent = 4, Received = 4" -or "Packets: Sent = 4, Received = 3") {
    Write-Host "Installing Java" -ForegroundColor Yellow
    C:\setup\bin\OnlineJavaInstall.ps1
    Write-Host "Finished Installing Java" -ForegroundColor Green
}
else{
Write-Host "Installing Java" -ForegroundColor Yellow
C:\Setup\bin\Java\JavaSetup8u221.exe  INSTALLDIR=C:\jre | Out-Null
Write-Host "Finished Installing Java" -ForegroundColor Green
}
#Installs Adobe Reader DC
Write-Host "Installing Adobe Reader" -ForegroundColor Yellow
C:\Setup\bin\Acrobat\AcroRdrDC1502320070_en_US.exe /sAll | Out-Null
Write-Host "Finished Installing Acrobat Reader" -ForegroundColor Green

#Installs .net 4.8
Write-host "Installing .net4.8" -ForegroundColor Yellow
C:\Setup\bin\.net\ndp48-x86-x64-allos-enu.exe /passive /norestart | Out-Null
Write-host "Finished Installing .net4.8" -ForegroundColor Green
    }
    N {
        Write-Host "Skipping Adobe, Java and .Net Install"
    }
    default{
        Write-Host "Skipping Adobe, Java and .Net Install"
    }
}

$Make = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer -ExpandProperty Manufacturer

#Checks for Internet then Pulls in Dell Warranty info and saves it to current user desktop in warranty.txt
if ($Make -match "Dell Inc.") {
    Write-Host "Installing Dell Open Manage" -ForegroundColor Yellow
    C:\Setup\bin\OpenManage\SYSMGMT\srvadmin\windows\SystemsManagementx64\SysMgmtx64.msi ADDLOCAL=ALL /qb
    #C:\Setup\bin\OpenManage\SYSMGMT\ManagementStation\windows\iDRACToolsx64\iDRACTools_x64.msi ADDLOCAL=ALL /qb
    #C:\Setup\bin\OpenManage\SYSMGMT\ManagementStation\windows\ADSnapInx64\ADSnapIn_x64.msi ADDLOCAL=ALL /qb
    #C:\Setup\bin\OpenManage\SYSMGMT\iSM\windows\iDRACSvcMod.msi ADDLOCAL=ALL /qb
    Write-Host "Finished Installing Dell Open Manage" -ForegroundColor Green   
}



if($Settings.LICENSING.INSTALLLICENSE -match "y"){
    C:\setup\bin\LicensingInstall.ps1
}
#Runs the Machine Info Script

    c:\Setup\bin\MachineInfo.ps1 -PWD $TempPassword



Stop-Transcript


#Install Windows Updates
#Ask if Updating
#$Internet = PING.EXE 8.8.8.8
#if ($internet -contains "Packets: Sent = 4, Received = 4" -or "Packets: Sent = 4, Received = 3") {
#    $Readhost1 = $Settings.general.UPDATEWINDOWS
#    Switch ($ReadHost1) { 
#        Y {
#            try {
#                Install-PackageProvider -Name NuGet -Force   
#                Install-Module PSWindowsUpdate -Force
#                Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -confirm:$false
#                Install-WindowsUpdate –MicrosoftUpdate –AcceptAll –AutoReboot -Confirm:$false;
#            }
#            Catch {
#                Write-Host "Unable to Install Pachages for Windows Update. Please Check Internet Connection" -ForegroundColor Red
#            }
#            $PublishSettings = $true
#        } 
#
#        N {
#            Write-Host "Machines is going to reboot" -ForegroundColor Green
#            Restart-Computer -WhatIf; $PublishSettings = $false
#        } 
#        Default {
#            Write-Host "Machines is going to reboot" -ForegroundColor Green
#            Restart-Computer -WhatIf; $PublishSettings = $false
#        } 
#    }
#}
$Readhost1 = $Settings.general.UPDATEWINDOWS
Switch ($ReadHost1) { 
    Y {
        C:\setup\bin\UpdateWindows.ps1
    }
    N {
        Write-Host "Skipping Windows Updates" -ForegroundColor Green
    } 
    Default {
        Write-Host "Skipping Windows Updates" -ForegroundColor Green
    } 
}



$Readhost = $Settings.general.AUTOREBOOT
Switch ($ReadHost) {
    Y { Write-host "Rebooting now..."; Start-Sleep -s 2; Restart-Computer -Force }
    N { Write-Host "Exiting script in 5 seconds."; Start-Sleep -s 5 }
    Default { Write-Host "Exiting script in 5 seconds"; Start-Sleep -s 5 }
}