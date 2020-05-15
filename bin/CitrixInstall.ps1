#------------------------------------------------------
# Name:        CitrixInstall
# Purpose:     Installs Citrix VDA
# Author:      John Burriss
# Created:     1/6/2020  9:49 PM 
#------------------------------------------------------


$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json

$Path = "c:\setup\CitrixSetup.log"

if(!(Test-Path $Path)) { 
    New-Item -ItemType File -Path "c:\setup\CitrixSetup.log"
}

Start-Transcript -Path "c:\setup\CitrixSetup.log" -Force

$CitrixLocation = $Settings.CITRIX.CITRIXISOLOCATION

if(Test-Path -Path $CitrixLocation){

    # Extracts the Citrix ISO to the C:\Setup\Bin\Citrix Folder
    Write-Host "Mounting disk image file '$ImageFile'..."
    $DiskImage = Mount-DiskImage $CitrixLocation -PassThru
    $DriveLetter = (Get-Volume -DiskImage $DiskImage).DriveLetter
    $DriveLetter = $DriveLetter + ":\"
    Write-Host "Copying contents of SQL ISO to C:\Setup\bin\Citrix" -ForegroundColor Yellow
    robocopy $DriveLetter "C:\setup\bin\Citrix\" /E /NFL /NDL /NJH /NJS /nc /ns /np
    Write-host "Copied contents of SQL iso to C:\setup\bin\Citrix" -ForegroundColor Green
    Dismount-DiskImage -InputObject $DiskImage
}

# Pauses Install if the ISO path is incorrect
else{
    Write-Host "Path to SQL ISO incorrect. Please Unzip SQL iso into C:\setup\bin\SQL" -ForegroundColor Red
    Write-Host -NoNewLine 'Press any key to continue when the ISO is unzipped';
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

#Sets up the installer and runs the Installation
$DeliveryControllers = $Settings.CITRIX.DELIVERYCONTROLLERS

Write-Host "Installing Citrix VDA" -ForegroundColor Yellow

Start-process "C:\Setup\bin\Citrix\x64\XenDesktop Setup\XenDesktopVDASetup.exe" -ArgumentList "/components VDA /controllers `"$DeliveryControllers`" /disableexperiencemetrics /enable_framehawk_port /enable_hdx_ports /enable_hdx_udp_ports /enable_real_time_transport /enable_remote_assistance /exclude `"Personal vDisk, Citrix Personalization for App-V - VDA`" /optimize /logpath c:\Setup\VDAInstallLogs /noreboot /quiet" -wait

Write-Host "Finished Citrix VDA, A Reboot is required to complete the Install" -ForegroundColor Green

Stop-Transcript