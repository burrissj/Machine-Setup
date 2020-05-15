#
#------------------------------------------------------
# Name:        NvidiaPerformance
# Purpose:     Nvidia Driver Install Based on Selection
# Author:      John Burriss
# Created:     8/26/2019  5:24 PM 
#------------------------------------------------------
#Requires -RunAsAdministrator

set-ExecutionPolicy Unrestricted

$Path = "c:\setup\NvidiaSetup.log"

if(!(Test-Path $Path)) { 
    New-Item -ItemType file -Path "c:\setup\NvidiaSetup.log" -Force
}

$INI = Get-IniContent C:\Setup\setup.ini

Start-Transcript -Path "c:\setup\NvidiaSetup.log"

$DriverVersion = $ini['OPTIONS'].NVIDIADRIVERVER

if($DriverVersion -match "425"){
    $DriverPath = Test-Path "C:\setup\bin\nvidia\425\setup.exe"
        if($DriverPath){
             Write-Host "Installing Nvidia Driver version 425" -ForegroundColor Green
                C:\setup\bin\nvidia\425\setup.exe Display.Driver -n -s | Out-Null
        }
    
    }

if($DriverVersion -match "431"){
    $DriverPath = Test-Path "C:\setup\bin\nvidia\431\setup.exe"
        if($DriverPath){
             Write-Host "Installing Nvidia Driver version 431" -ForegroundColor Green
                C:\setup\bin\nvidia\431\setup.exe Display.Driver -n -s | Out-Null
        }
    
    }

if($DriverVersion -match "411"){
$DriverPath = Test-Path "C:\setup\bin\nvidia\411\setup.exe"
    if($DriverPath){
         Write-Host "Installing Nvidia Driver version 411" -ForegroundColor Green
            C:\setup\bin\nvidia\411\setup.exe  Display.Driver -n -s | Out-Null
    }

}

ElseIf($DriverVersion -match "430"){
    $DriverPath = Test-Path "C:\setup\bin\nvidia\430\setup.exe"
    if($DriverPath){
        Write-Host "Installing Nvidia Driver version 430" -ForegroundColor Green
         C:\setup\bin\nvidia\430\setup.exe Display.Driver -n -s | Out-Null
    }
}
Else{
Write-Host "Your selection was incorrect, Please Manually Install." -ForegroundColor Red
}

$DriverScript = Test-Path "C:\Setup\bin\NvidiaPerformance.ps1"
if($DriverScript -eq $true){
    $RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    Set-ItemProperty $RunOnceKey "NextRun" "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Unrestricted -File C:\Setup\bin\NvidiaPerformance.ps1"
    Write-Host "Cards will be optimized on next boot." -ForegroundColor Green 
 }
 Stop-Transcript
 $Readhost = $ini['OPTIONS'].AUTOREBOOT
 Switch ($ReadHost) {
     Y {Write-host "Rebooting now..."; Start-Sleep -s 2; Restart-Computer -Force}
     N {Write-Host "Exiting script in 5 seconds."; Start-Sleep -s 5}
     Default {Write-Host "Exiting script in 5 seconds"; Start-Sleep -s 5}
 }
