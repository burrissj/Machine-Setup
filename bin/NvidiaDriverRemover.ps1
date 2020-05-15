
#
#------------------------------------------------------
# Name:        NvidiaDriverRemover
# Purpose:     Removed all Nvidia Components. Required for Windows 10 Driver Install.
# Author:      John Burriss
# Created:     12/18/2019  11:55 PM 
#------------------------------------------------------
 #Requires -RunAsAdministrator

set-ExecutionPolicy Unrestricted

$Path = "c:\setup\NvidiaSetup.log"

if(!(Test-Path $Path)) { 
    New-Item -ItemType file -Path "c:\setup\NvidiaSetup.log" -Force
}

Start-Transcript -Path "c:\setup\NvidiaSetup.log"

$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json


$RemoveNvidiaDriver = $Settings.GPU.REMOVECURRENTDRIVER

if($RemoveNvidiaDriver = $Settings.GPU.REMOVECURRENTDRIVER -match "y"){

$ServerType = $Settings.general.SERVERTYPE

#Adds Reg Key to stop Automatic Driver Install
if($Null -eq (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -name "ExcludeWUDriversInQualityUpdate" -errorAction SilentlyContinue)){
        Write-Host "Adding Reg Key to stop Automatic Driver Instalation" -ForegroundColor Yellow
        New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force |  New-ItemProperty -Name "ExcludeWUDriversInQualityUpdate"  -PropertyType dword -Value "1"
        Write-Host "Added Reg Key to stop Automatic Driver Instalation" -ForegroundColor Green
    }

    #Runs the DDU to remove all of the Nvidia Components
    $DDU = "C:\Setup\bin\DDU\Display Driver Uninstaller.exe"
    Write-Host "Removeing all Nvidia Components" -ForegroundColor Yellow
    Start-Process  $DDU -ArgumentList "-silent -nosafemodemsg -cleannvidia" -Wait
    Write-Host "Finished Removing all Nvidia Components. Please reboot before re-installing" -ForegroundColor Green

    #Sets the Nvidia Driver to install on next boot
    if ($ServerType -match "app") {
        Write-Host "Setting Nvidia driver to install on next boot" -ForegroundColor Green
        $RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        Set-ItemProperty $RunOnceKey "NextRun" "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Unrestricted -File C:\Setup\bin\NvidiaInstaller.ps1"
    }

    
#$Readhost = $Settings.general.AUTOREBOOT
#Switch ($ReadHost) {
#    Y {Write-host "Rebooting now..."; Start-Sleep -s 2; Restart-Computer -Force}
#    N {Write-Host "Exiting script in 5 seconds. Please Reboot to continue the Script."; Start-Sleep -s 5}
#    Default {Write-Host "Exiting script in 5 seconds. Please Reboot to continue the Script."; Start-Sleep -s 5}
#}
}
Stop-Transcript