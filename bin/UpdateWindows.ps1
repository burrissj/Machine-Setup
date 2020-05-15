#------------------------------------------------------
# Name:        Update Windows
# Purpose:     Updates Windows
# Author:      John Burriss
# Created:     12/2/2019  4:48 PM 
#------------------------------------------------------

$Internet = PING.EXE 8.8.8.8
if ($internet -contains "Packets: Sent = 4, Received = 4" -or "Packets: Sent = 4, Received = 3") {

            try {
                Install-PackageProvider -Name NuGet -Force   
                Install-Module PSWindowsUpdate -Force
                Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -confirm:$false
                Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -Confirm:$false
            }
            Catch {
                Write-Host "Unable to Install Packages for Windows Update. Please Check Internet Connection" -ForegroundColor Red
            }
  
        } 