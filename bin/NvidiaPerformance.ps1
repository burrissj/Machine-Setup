#------------------------------------------------------
# Name:        NvidiaPerformance
# Purpose:     Set Nvidia Cards in App Server to Max Power and Clock
# Author:      John Burriss
# Created:     8/22/2019  9:54 PM 
#------------------------------------------------------
#Requires -RunAsAdministrator

set-ExecutionPolicy Unrestricted

$Path = "c:\setup\NvidiaPerformance.log"

if(!(Test-Path $Path)) { 
    New-Item -ItemType file -Path "c:\setup\NvidiaPerformance.log"
}
$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json
Start-Transcript -Path "c:\setup\NvidiaPerformance.log"

#Sets Mode to Unrestricted and Sets to Persistent Mode
$Mode = (& "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -acp UNRESTRICTED)
if($Mode -match "Unsupported"){
Write-Host "Unable to set mode to Unrestricted, Unsupported" -ForegroundColor Red
}
else{
    (& "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -acp UNRESTRICTED)  
}

$Persist = & "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -pm 1
if($Persist -match "Unsupported"){
Write-Host = "Unable to set mode to persistant, unsupported" -ForegroundColor Red

}
else{
    & "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -pm 1  
}

#Gets Card Count for Loop
$CardCount = & "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -L
$i=0

$CardType = New-Object System.Collections.Generic.List[System.Object]
ForEach($Card in $CardCount){
$CardName = ($Card.Split(" ")[2])
$CardType.Add($CardName)
}

if (($CardType | Select-Object -Unique).Count -eq 1){

    $AllTesla = $true
}
else{
    $AllTesla = $false
}

ForEach($Card in $CardCount){
#Sets ECC on and TCC Mode on if Tesla
$ecc = & "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -i $i --ecc-config=1

if($ecc -match "unsupported"){
    Write-Host "Unable to change ECC Setting, Unsupported" -ForegroundColor Red
}

if($AllTesla -eq $True){
    if($i -eq 1){
        & "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -i $i -dm 0
    }
}
else{
if($Card -match "Tesla"){

        & "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -i $i -dm 1
    }
}
#Gathers Clock Speeds and Cleans data to select Top Graphics and Memory Speeds
$Clocks = (& "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -i $i -q -d SUPPORTED_CLOCKS)
if($Clocks -match 'N/A'){
Write-Host "Setting Clocks is not supported on this card: $Card" -ForegroundColor Red
}
Else{
$Clocks1 = $Clocks | Where-Object { $_ -match 'Graphics' }
$Graphics = $Clocks1[0] -replace "\D",""
$Clocks1 = $Clocks | Where-Object { $_ -match 'Memory' }
$Memory = $Clocks1[0] -replace "\D",""
#Sets Card to Max Clock Speed
& "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -ac $Memory,$Graphics -i $i
}
#Queries if cards power is adjustable and then set it to Max
 $Power = (& "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -i $i --format=csv --query-gpu=power.limit)

 if($Power -notmatch "[Not Supported]"){

 $Power = $Power[1].split('.')

 (& "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -i $i -pl $Power[0])
}
}
if($Settings.options.CLEANUP -match "y"){
    Write-Host "Setting Machine to Cleanup on Next Boot" -ForegroundColor Green
    $RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    Set-ItemProperty $RunOnceKey "NextRun" "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Unrestricted -File C:\Setup\bin\Cleanup.ps1"
    }

    #Disabled the Nvidia Tray Icon
    #$TrayIcon = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\NvTray"
    $TrayIcon = "HKLM:\SOFTWARE\NVIDIA Corporation\NvTray"
    if((Test-Path $Trayicon) -eq $null){
    New-Item $TrayIcon -Force | New-ItemProperty -Name "StartOnLogin" -Value "00000000" -type dword
    }

    #Runs Machine Info Script and updates the Machine Info with GPU Information
            c:\Setup\bin\MachineInfo.ps1
    
Stop-Transcript
$Readhost = $Settings.general.AUTOREBOOT
Switch ($ReadHost) {
    Y {Write-host "Rebooting now..."; Start-Sleep -s 2; Restart-Computer -force}
    N {Write-Host "Exiting script in 5 seconds."; Start-Sleep -s 5}
    Default {Write-Host "Exiting script in 5 seconds"; Start-Sleep -s 5}
}
