#------------------------------------------------------
# Name:        Launcher
# Purpose:     Preps Files to be consumed by setup and launches setup in new window
# Author:      John Burriss
# Created:     9/30/2019  5:24 PM 
#------------------------------------------------------
#Requires -RunAsAdministrator

set-ExecutionPolicy Unrestricted

$Path = "C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules"

if(!(Test-Path $Path)) { 
    New-Item -ItemType Directory -Path "C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules"
}
$Path = "C:\Program Files\PackageManagement\ProviderAssemblies"

if(!(Test-Path $Path)) { 
Copy-Item "C:\Setup\bin\NuGet" -Destination "C:\Program Files\PackageManagement\ProviderAssemblies"
}

$Run = "C:\Setup\setup.ps1"

start-process powershell -ArgumentList "-file $Run"

exit