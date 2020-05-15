#------------------------------------------------------
# Name:        SQLInstall
# Purpose:     Installs SQL server, Management Studio and Sets TCPip Port and sets Max memory to 80%
# Author:      John Burriss
# Created:     9/22/2019  8:45 PM 
#------------------------------------------------------

#Requires -RunAsAdministrator
[CmdletBinding()]
Param(
[Parameter()]
$Type,
[Parameter()]
$DataDirectory,
[Parameter()]
$Instance,
[Parameter()]
$SAPWD,
[Parameter()]
$Key,
[Parameter()]
$FilestreamShareName
)

#$ErrorActionPreference = "Stop"
$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json

#Import-Module Storage

$Path = "c:\setup\SQLsetup.log"

if(!(Test-Path $Path)) { 
    New-Item -ItemType File -Path "c:\setup\SQLsetup.log"
}

Start-Transcript -Path "c:\setup\SQLsetup.log" -Force

$DriveLetter = "C:\setup\bin\SQL"

$Setup = $DriveLetter + '\setup.exe'
Write-Host "Installing SQL Server" -ForegroundColor Yellow
$CurrentUser = $env:USERDOMAIN + '\' + $env:USERNAME
if ($Type -match "test" -or "smallsite"){
$CustomParameters = @()
if ($DataDirectory) {
  $PID1 =  "22222-00000-00000-00000-00000"
  $CustomParameters += "/PID=$PID1"
  $SqlBackupDir =  "$DataDirectory\SQLServer\Backup"
  $CustomParameters += "/SQLBACKUPDIR=$SqlBackupDir"
  $SqlUserDbDir =  "$DataDirectory\SQLServer\Data"
  $CustomParameters += "/SQLUSERDBDIR=$SqlUserDbDir"
  $SqlUserDbDir =  "$DataDirectory\SQLServer\Data"
  $CustomParameters += "/SQLUSERDBLOGDIR=$SQLUSERDBLOGDIR"
  $SqlTempDbDir = "$DataDirectory\SQLServer\TempDb"
  $CustomParameters += "/SQLTEMPDBDIR=$SqlTempDbDir"
  $SqlTempDbDir = "$SQLTEMPDBLOGDIR\SQLServer\Logs"
  $CustomParameters += "/SQLTEMPDBLOGDIR=$SQLTEMPDBLOGDIR"
  $SAPWD = "$SAPWD"
  $CustomParameters += "/SAPWD=$SAPWD"
}
}
if ($Type -match "prod"){
    $CustomParameters = @()
      $PID1 =  "$Key"
      $CustomParameters += "/PID=$PID1"
      $SqlBackupDir =  "R:\SQLBackups"
      $CustomParameters += "/SQLBACKUPDIR=$SqlBackupDir"
      $SqlUserDbDir =  "D:\SQLData"
      $CustomParameters += "/SQLUSERDBDIR=$SqlUserDbDir"
      $SqlUserDbDir =  "D:\SQLData"
      $CustomParameters += "/SQLUSERDBLOGDIR=$SQLUSERDBLOGDIR"
      $SqlTempDbDir = "T:\SQLData"
      $CustomParameters += "T:\SQLData"
      $SqlTempDbDir = "L:\SQLLogs"
      $CustomParameters += "/SQLTEMPDBLOGDIR=$SQLTEMPDBLOGDIR"
      $INSTALLSQLDATADIR = "E:\Program Files\Microsoft SQL Server"
      $CustomParameters += "/INSTALLSQLDATADIR=$INSTALLSQLDATADIR"
      $SAPWD = "$SAPWD"
      $CustomParameters += "/SAPWD=$SAPWD"
    }

& $Setup /ACTION=Install /QS /IACCEPTSQLSERVERLICENSETERMS `
  /ENU `
  /UpdateEnabled="false" /UpdateSource="MU" `
  /TCPENABLED="1" /NPENABLED="1" /SQLSVCSTARTUPTYPE="Automatic" /SECURITYMODE="SQL" `
  /AGTSVCSTARTUPTYPE="Automatic" /BROWSERSVCSTARTUPTYPE="Automatic" `
  /FEATURES="SQLEngine" /INSTANCENAME="$Instance" /INSTANCENAME="$Instance" /SQLCOLLATION="Latin1_General_CI_AS" `
  /FILESTREAMLEVEL="3" /FILESTREAMSHARENAME="$FilestreamShareName" `
  /SQLSYSADMINACCOUNTS="$CurrentUser" "BUILTIN\Administrators" `
  @CustomParameters

Write-Host "Installed SQL Server" -ForegroundColor Green

Write-Host "Installing SQL Server Management Studio" -ForegroundColor yellow
$SSMSSetup = Join-Path $DriveLetter "SSMS-Setup-ENU.exe"
Start-Process -FilePath $SSMSSetup -ArgumentList @("/install", "/passive") -Wait

Write-Host "Installed SQL Server Management Studio" -ForegroundColor Green

Write-Host "Setting SQL Port to 1433" -ForegroundColor Yellow

function SetPort($Instance1, $port)
{
    # fetch the WMI object that contains TCP settings; filter for the 'IPAll' setting only
    # note that the 'ComputerManagement13' corresponds to SQL Server 2017
    Try{
    $settings = Get-WmiObject `
        -Namespace root/Microsoft/SqlServer/ComputerManagement14 `
        -Class ServerNetworkProtocolProperty `
        -Filter "InstanceName='$Instance1' and IPAddressName='IPAll' and PropertyType=1 and ProtocolName='Tcp'"
    }
    Catch{
        $settings = Get-WmiObject `
        -Namespace root/Microsoft/SqlServer/ComputerManagement13 `
        -Class ServerNetworkProtocolProperty `
        -Filter "InstanceName='$Instance1' and IPAddressName='IPAll' and PropertyType=1 and ProtocolName='Tcp'"
    }
    # there are two settings in a list: TcpPort and TcpDynamicPorts
    foreach ($setting in $settings)
    {
        if ($null-ne $setting )
        {
            # set the static TCP port and at the same time clear any dynamic ports
            if ($setting.PropertyName -eq "TcpPort")
            {
                $setting.SetStringValue($port)
            }
            elseif ($setting.PropertyName -eq "TcpDynamicPorts")
            {
                $setting.SetStringValue("")
            }
        }
    }
}

SetPort "$Instance" 1433
Write-Host "Set SQL Port to 1433" -ForegroundColor Green

#Functions to set SQL Max Memory
Function Get-SQLMaxMemory { 
    $memtotal = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1mb
    $min_os_mem = 2048 ;
    if ($memtotal -le $min_os_mem) {
        Return $null;
    }
    if ($memtotal -le 8192) {
        $sql_mem = $memtotal - 2048
    } else {
        $sql_mem = $memtotal * 0.8 ;
    }
    return [int]$sql_mem ;  
}
Function Set-SQLInstanceMemory {
    param (
        [string]$SQLInstanceName = ".", 
        [int]$maxMem = $null, 
        [int]$minMem = 0
    )
 
    if ($minMem -eq 0) {
        $minMem = $maxMem
    }
    [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
    $srv = New-Object Microsoft.SQLServer.Management.Smo.Server($SQLInstanceName)
    if ($srv.status) {
        Write-Host "[Running] Setting Maximum Memory to: $($srv.Configuration.MaxServerMemory.RunValue)"
        Write-Host "[Running] Setting Minimum Memory to: $($srv.Configuration.MinServerMemory.RunValue)"
 
        Write-Host "[New] Setting Maximum Memory to: $maxmem"
        Write-Host "[New] Setting Minimum Memory to: $minmem"
        $srv.Configuration.MaxServerMemory.ConfigValue = $maxMem
        $srv.Configuration.MinServerMemory.ConfigValue = $minMem   
        $srv.Configuration.Alter()
    }
}

Write-Host "Setting SQL Memory Config" -ForegroundColor Yellow
$MSSQLInstance = $Instance
Set-SQLInstanceMemory $MSSQLInstance (Get-SQLMaxMemory)
$SQLMem = Get-SQLMaxMemory
Write-Host "Set SQL Max memory to $SQLMem" -ForegroundColor Green

#Restarts the SQL Service

Write-Host "Restarting SQL Services" -ForegroundColor Yellow
$SQLServices = Get-service *SQL* | Where-Object {$_.status -eq   "Running"} 

ForEach($SQLService in $SQLServices){

Restart-Service -Name $SQLService.Name -Force

}

$FileStreamDrive = $Settings.SQL.FILESTREAMDRIVE
if($FileStreamDrive -ne ""){
$FileStreamDrive = $FileStreamDrive + ":\SQLServer\FileStream"
}
else {
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[string]$SQLInstanceName = "."
$SMOServer = New-Object Microsoft.SQLServer.Management.Smo.Server($SQLInstanceName)
$FileStreamDrive = $SMOServer.Information.MasterDBPath
}
#Start Performance Test on FileStream
C:\Setup\bin\sql\FileStreamPerformance.ps1 -FileStreamDirectory $FileStreamDrive -FixProblems "fix"

Stop-Transcript

