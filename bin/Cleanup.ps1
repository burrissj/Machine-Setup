
#------------------------------------------------------
# Name:        Cleanup
# Purpose:     Removes All Leftover files from setup
# Author:      John Burriss
# Created:     8/26/2019  5:24 PM 
#------------------------------------------------------
#Requires -RunAsAdministrator

$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json

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

#Runs Machine Info Script before Final Cleanup
c:\Setup\bin\MachineInfo.ps1

#Removes Leftover Reg keys of they exist
Write-Host "Removing Leftover Reg Keys" -ForegroundColor Yellow
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$RegistryRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

if(Get-ItemProperty -Path $RegistryRunOncePath -Name "NextRun" -ErrorAction SilentlyContinue){Remove-ItemProperty -Path $RegistryRunOncePath -Name "NextRun"}
if(Get-ItemProperty -Path $RegistryPath -Name "AutoAdminLogon" -ErrorAction SilentlyContinue){Remove-ItemProperty -Path $RegistryPath -Name "AutoAdminLogon"}
if(Get-ItemProperty -Path $RegistryPath -Name "DefaultUsername" -ErrorAction SilentlyContinue){Remove-ItemProperty -Path $RegistryPath -Name "DefaultUsername"}
if(Get-ItemProperty -Path $RegistryPath -Name "DefaultPassword" -ErrorAction SilentlyContinue){Remove-ItemProperty -Path $RegistryPath -Name "DefaultPassword"}
if(Get-ItemProperty -Path $RegistryPath -Name "DefaultDomainName" -ErrorAction SilentlyContinue){Remove-ItemProperty -Path $RegistryPath -Name "DefaultDomainName"}
Write-Host "Keys Removed" -ForegroundColor Green

Write-Host "Creating C:\Temp and Moving Logs and setting up final cleanup" -ForegroundColor Yellow
$Path = "C:\Temp"
if(!(Test-Path $Path)) { 
mkdir "C:\Temp"
}
Copy-Item "C:\Setup\*.log" "C:\Temp"
Copy-Item "C:\Setup\bin\FinalCleanup.ps1" "C:\Temp\"

$Run = "C:\Temp\FinalCleanup.ps1"

start-process powershell  -argument "-noexit -nologo -noprofile -file $Run"
