#------------------------------------------------------
# Name:        MachineInfo
# Purpose:     Makes API request to Dell to get support information for Service Tag
# Author:      John Burriss
# Created:     10/7/2019  12:13 PM 
#------------------------------------------------------
[CmdletBinding()]

Param(
[Parameter()]
$PWD
)

$SN = get-ciminstance win32_bios | Select-object SerialNumber -ExpandProperty SerialNumber
#Start of the API request to dell
$Make = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer -ExpandProperty Manufacturer
$Internet = PING.EXE 8.8.8.8
if ($internet -contains "Packets: Sent = 4, Received = 4" -or "Packets: Sent = 4, Received = 3") {
  if ($Make -match "Dell") {

$url=''

$postdata=''

$content=''

$auth_response=''

$url='https://apigtwb2c.us.dell.com/auth/oauth/v2/token'

$postdata= @{client_id='l7d194d0a2037c4648a4d2b68b27f0597f';client_secret='149e2d0014544e8d86cb964ace4b0362';grant_type='client_credentials'}

$content='application/x-www-form-urlencoded'
try{
$auth_response = Invoke-RestMethod -URI $url -Method Post -Body $postdata -ContentType $content # -ErrorAction SilentlyContinue | Out-Null
}
Catch{
  Write-Host "Unable to resolve Dell.com" -ForegroundColor Red
}
$Token = $auth_response.access_token


 $params = @{
    Uri         = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements?servicetags=$SN"
    Headers     = @{ 'Authorization' = "Bearer $Token" }
    Method      = 'GET'
    Body        = $jsonSample
    ContentType = 'application/json'
    }
    Try {
    $Details = Invoke-RestMethod @params # -ErrorAction SilentlyContinue
    $Details1 = $Details.entitlements | Select-Object serviceLevelDescription, startDate, endDate
    $Details1 = $Details1 -replace "@{serviceLevelDescription=",""
    $Details1 = $Details1 -replace "}",""
    $Details1 = $Details1 -replace "startDate=","Start Date: "
    $Details1 = $Details1 -replace "endDate=","End Date: "
    $Details1 = $Details1 -replace "[T][0-9]{2}\:[0-9]{2}\:[0-9]{2}[Z]",""
    $Details1 = $Details1 -replace "[T][0-9]{2}\:[0-9]{2}\:[0-9]{2}\.[0-9]{3}[Z]",""
    #$Details1 = $Details1 | ConvertFrom-Csv -Delimiter ";"

    }
    Catch{
      Write-Host "Failed to retrieve support information from Dell" -ForegroundColor Red
    }
  }
  }


    $Model = (Get-WmiObject -Class:Win32_ComputerSystem).Model
    $OS = Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object ProductName -ExpandProperty ProductName
    $Path = "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe"
    if(Test-Path $path){
    $GPUs = & "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" --query-gpu=name --format=csv | select-object -skip 1
    $GPUDriver = & "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" --query-gpu=driver_version --format=csv | select-object -skip 1 | Select-Object -First 1
    $GPUSN = (& "C:\Program Files\NVIDIA CORPORATION\NVSMI\nvidia-smi.exe" -a)
    $GPUSN = $GPUSN  | Where-Object  {$_ -match "Serial Number"}
    $GPUSN = $GPUSN -replace "    Serial Number                   :",""

    }
    Else{
      $GPUs = "N/A"
      $GPUDriver = "N/A"      
    }
    #Checks to see if file exists, removes it if it does.
    $Path = "C:\users\$env:UserName\desktop\MachineInfo.txt"

    if(Test-Path $Path){
      Remove-Item $Path
    }

    Start-Sleep -Milliseconds 100

    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "$Make $Model"
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "Serial Number: $SN"
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "Hostname: $env:COMPUTERNAME"
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "Installed OS: $OS"
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "GPU(s): $GPUs"
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "GPU Driver: $GPUDriver"
    if($Null -ne $GPUSN){
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "GPU Serial Number(s): $GPUSN"
    }
    #Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "$GPUSN"
    if($Null -ne $PWD){
      $Password = $PWD
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "The Local Admin pw: $Password"
    }
    if($Null -ne $Details){
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" "The support Information for ServiceTag $SN is:"
    Add-Content "C:\users\$env:UserName\desktop\MachineInfo.txt" $Details1
    }