#
#------------------------------------------------------
# Name:        NvidiaInstaller
# Purpose:     Nvidia Driver defined in json
# Author:      John Burriss
# Created:     12/16/2019  2:07 PM 
#------------------------------------------------------
#Requires -RunAsAdministrator

set-ExecutionPolicy Unrestricted


$Path = "c:\setup\NvidiaSetup.log"

if(!(Test-Path $Path)) { 
    New-Item -ItemType file -Path "c:\setup\NvidiaSetup.log" -Force
}

$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json

Start-Transcript -Path "c:\setup\NvidiaSetup.log"


if(Test-Path -Path $Settings.GPU.DRIVERLOCATION){

    if(Test-path -Path "C:\setup\bin\nvidia\Install"){
        Remove-Item "C:\setup\bin\nvidia\Install\*" -Recurse -Force
    }

#Extracts the setup files from the exe
$fileToExtract = $settings.GPU.DRIVERLOCATION
$extractFolder = "C:\setup\bin\Nvidia\Install"
$filesToExtract = "Display.Driver NVI2 EULA.txt ListDevices.txt setup.cfg setup.exe"
$7z = "C:\setup\bin\7-ZipPortable\App\7-Zip64\7z.exe"

Write-Host "Extracting the Driver" -ForegroundColor Yellow
Start-Process -FilePath $7z -ArgumentList "x $fileToExtract $filesToExtract -o""$extractFolder""" -wait
Write-Host "Finished Extracting the Driver" -ForegroundColor Green
#Removes the dependencies in the config file 
Write-Host "Editing the Driver Config File" -ForegroundColor Yellow
(Get-Content "$extractFolder\setup.cfg") | Where-Object {$_ -notmatch 'name="\${{(EulaHtmlFile|FunctionalConsentFile|PrivacyPolicyFile)}}'} | Set-Content "$extractFolder\setup.cfg" -Encoding UTF8 -Force
Write-Host "Finished editing the Driver config file" -ForegroundColor Green

#Installs the GPU Driver with Args
$install_args = "-s -noreboot -noeula"

if ($settings.GPU.CLEANINSTALL -match "y") {
    $install_args = $install_args + " -clean"
}
Write-Host "Starting the Driver Install" -ForegroundColor Yellow
Start-Process -FilePath "$extractFolder\setup.exe" -ArgumentList $install_args -wait
Write-Host "Finished Installing the Display Driver" -ForegroundColor Green


$DriverScript = Test-Path "C:\Setup\bin\NvidiaPerformance.ps1"
if($DriverScript -eq $true){
    $RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    Set-ItemProperty $RunOnceKey "NextRun" "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Unrestricted -File C:\Setup\bin\NvidiaPerformance.ps1"
    Write-Host "Cards will be optimized on next boot." -ForegroundColor Green 
}


$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if(Get-ItemProperty -Path $RegistryPath -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue){
    Write-Host "Removing Auto Driver Update Reg Key" -ForegroundColor Yellow
    Remove-ItemProperty -Path $RegistryPath -Name "ExcludeWUDriversInQualityUpdate"
    Write-Host "Removed Auto Driver Update Reg Key" -ForegroundColor Green
}

$Readhost = $Settings.general.AUTOREBOOT
Switch ($ReadHost) {
    Y {Write-host "Rebooting now..."; Start-Sleep -s 2; Restart-Computer -Force}
    N {Write-Host "Exiting script in 5 seconds."; Start-Sleep -s 5}
    Default {Write-Host "Exiting script in 5 seconds"; Start-Sleep -s 5}
}

}
Else{
    Write-Host "Unable to locate GPU driver specified in the setup.json file. Please Install the Driver Manually" -ForegroundColor Red
    Write-Host "Please correct location in the config and run C:\Setup\bin\NvidiaInstaller.ps1 again." -ForegroundColor Red
}
Stop-Transcript