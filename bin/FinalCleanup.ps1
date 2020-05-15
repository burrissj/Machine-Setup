
#------------------------------------------------------
# Name:        Final Cleanup 
# Purpose:     Removes All Leftover files from setup
# Author:      John Burriss
# Created:     10/7/2019  1:00 PM 
#------------------------------------------------------
#Requires -RunAsAdministrator

Start-Sleep -Seconds 10

#Restarts Explorer to close all open windows
Stop-Process -ProcessName explorer

#Closes all other open Powershell windows
Get-Process Powershell  | Where-Object { $_.ID -ne $pid } | Stop-Process

Start-Sleep -Seconds 5

#Removes the Setup Folder
Try{
Remove-Item "C:\Setup" -Force -Recurse
}
Catch{
    Write-host "Failed to Delete the C:\Setup folder. Please delete Manually" -ForegroundColor Red
}
Start-Sleep -Seconds 5
#Clears Powershell History
Clear-History

#Removes Currently Running Script
Remove-Item -Path $MyInvocation.MyCommand.Source

Exit