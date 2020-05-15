#C:\Setup\bin\Licensing\LMXServer\lmx-enduser-tools_v4.8.12_win64_x64.msi INSTALLSERVER=1 VENDORDLLPATH=C:\Setup\bin\Licensing\LMXServer\liblmxvendor.dll INSTALLSERVICE=1
#------------------------------------------------------
# Name:        Licensing Install
# Purpose:     Installs the LMX Utility and moves the license file into the proper folder and starts the service
# Author:      John Burriss
# Created:     12/11/2019  8:45 PM 
#------------------------------------------------------
#Requires -RunAsAdministrator

set-ExecutionPolicy Unrestricted

$Path = "c:\setup\LicenseInstall.log"

if (!(Test-Path $Path)) { 
    New-Item -ItemType File -Path "c:\setup\LicenseInstall.log"
}

Start-Transcript -Path "c:\setup\LicenseInstall.log"

$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json


if($settings.LICENSING.INSTALLLMX -match "y"){
Try{
    Write-Host "Installing the LMX Utility" -ForegroundColor Yellow
    Start-Process "C:\Setup\bin\Licensing\LMXServer\lmx-enduser-tools_v4.8.12_win64_x64.msi" -ArgumentList "INSTALLSERVER=1 VENDORDLLPATH=C:\Setup\bin\Licensing\LMXServer\liblmxvendor.dll INSTALLSERVICE=1 /qr" -Wait
    Write-Host "Finished Installing LMX Utility" -ForegroundColor Green

Write-Host "Moving License and Dll Files" -ForegroundColor Yellow

if(Test-Path -Path "C:\Program Files\X-Formation\LM-X End-user Tools 4.8.12 x64"){
Copy-Item -path "C:\Setup\bin\Licensing\matrix64.dll" -Destination "C:\Program Files\X-Formation\LM-X End-user Tools 4.8.12 x64" -Force
Write-Host "Copied the Matrix64.dll file to the LMX folder" -ForegroundColor Green
}
Else{
    Write-Host "Failed to Move the Matrix64.dll to LMX folder" -ForegroundColor Red
}
#if(!(Test-Path -Path "C:\Windows\System32\config\systemprofile\AppData\Local\x-formation")){
#   New-Item -ItemType Directory -Path "C:\Windows\System32\config\systemprofile\AppData\Local\x-formation"
#}

if(test-Path -Path $Settings.LICENSING.LICENSELOCATION){
    Copy-Item -path $Settings.LICENSING.LICENSELOCATION -Destination "C:\Program Files\X-Formation\LM-X End-user Tools 4.8.12 x64\"
    Write-Host "Moved the License File to the Correct Location." -ForegroundColor Green
}
Else{
    Write-Host "No License found in Setup.json. Please Manually Add the license file and restart the LMX service" -ForegroundColor Red
}

Write-Host "Restarting the LMX Service" -ForegroundColor Yellow
$Service = Get-service | Where-Object { $_ -match "LMX"}
if($Null -ne $Service){
    Try{
    Restart-Service -Name $Service.Name
    Get-Service -Name $service.Name
    Write-Host "Restarted the LMX Service" -ForegroundColor Green
    }
    Catch{
        Write-Host "Unable to restart the LMX service, Please Manually restart the service" -ForegroundColor Red
    }
}
Else{
    Write-Host "Unable to Locate the LMX Service. Please make sure that it is installed correctly." -ForegroundColor Red
}

}

Catch{
    Write-Host "Errors Installing the LMX utility. Please Install Manually" -ForegroundColor Red
}

}

if($settings.LICENSING.LOCALLICENSE -match "y"){
    Write-Host "Installing the License Locally" -ForegroundColor Yellow
    Try{
        Write-Host "Attempting to Copy License File to C:\Program Files\RaySearch Laboratories\LicenseFile"
        if(!(Test-Path -Path "C:\Program Files\RaySearch Laboratories\LicenseFile")){
            New-Item -ItemType Directory -Path "C:\Program Files\RaySearch Laboratories\LicenseFile"
        }
        if((test-Path -Path $Settings.LICENSING.LICENSELOCATION) -eq $true){
            Copy-Item -path $Settings.LICENSING.LICENSELOCATION -Destination "C:\Program Files\RaySearch Laboratories\LicenseFile"
            Write-Host "Moved the License File to the Correct Location."
        }
        Else{
            Write-Host "No License found in Setup.json. Please Manually Add the license file and restart the LMX service" -ForegroundColor Red
        }

}
Catch{
    Write-Host "Unable to Move License File to C:\Program Files\RaySearch Laboratories\LicenseFile" -ForegroundColor Red
}
}

Stop-Transcript