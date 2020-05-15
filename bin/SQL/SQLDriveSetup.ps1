#------------------------------------------------------
# Name:        SQLDriveSetup
# Purpose:     Sets up Drives for SQL server setup and passes info to the SQL install script
# Author:      John Burriss
# Created:     9/25/2019  2:24 PM 
#------------------------------------------------------

#Requires -RunAsAdministrator

$Path = "c:\setup\SQLDriveSetup.log"

if(!(Test-Path $Path)) { 
    New-Item -ItemType File -Path "c:\setup\SQLDriveSetup.log"
}

Start-Transcript -Path "c:\setup\SQLDriveSetup.log" -Force

$Settings = Get-Content 'C:\Setup\Setup.json' | ConvertFrom-Json

$BuildType = $Settings.SQL.BUILDTYPE
if ($BuildType -match "Prod"){
    $ProdDisks = $Settings.SQL.NEWDISKS
    if($ProdDisks -match "y"){
        $newdisk = @(get-disk | Where-Object partitionstyle -eq 'raw')
        if($newdisk.Count -le 6){
            Write-Host "There are not the correct amount of disks in the system to continue with this config.
            Please ensure that all the disks are added to the machine and unformatted." -ForegroundColor Red
            Start-Sleep -Seconds 10
            exit
        }
        $Drives = Get-WmiObject -Class win32_volume
        foreach($Drive in $Drives){
            $DriveLetter = $Drive.DriveLetter
                if($DriveLetter -match "D:"){
                    Write-Host "Please Disconnec Disk Drive if Connected"
                    Write-Host -NoNewLine 'Press any key when drive is disconnected to continue';
                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                }
 }
        $Labels = @('Data','EXE','FileStream','Dicom','Logs','Backup','Temp')
        
        for($i = 0; $i -lt $newdisk.Count ; $i++)
        {
        
            $disknum = $newdisk[$i].Number
            $dl = get-Disk $disknum | 
               Initialize-Disk -PartitionStyle GPT -PassThru | 
                  New-Partition -AssignDriveLetter  -UseMaximumSize
                    if($Labels[$i] -eq "Data"){
                        Format-Volume -driveletter $dl.Driveletter -FileSystem NTFS -NewFileSystemLabel $Labels[$i] -AllocationUnitSize 65536 -Confirm:$false
                    }
                    else{
                        Format-Volume -driveletter $dl.Driveletter -FileSystem NTFS -NewFileSystemLabel $Labels[$i] -Confirm:$false
                    }
        }


#Sets Drives to Temporary Letters

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Data'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="K:"; Label="Data"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'EXE'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="X:"; Label="EXE"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'FileStream'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="Y:"; Label="FileStream"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Dicom'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="Q:"; Label="Dicom"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Logs'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="O:"; Label="Logs"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Backup'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="M:"; Label="Backup"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Temp'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="N:"; Label="Temp"}

#Sets Drives to Perm Letter

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Data'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="D:"; Label="Data"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'EXE'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="E:"; Label="EXE"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'FileStream'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="I:"; Label="FileStream"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Dicom'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="J:"; Label="Dicom"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Logs'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="L:"; Label="Logs"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Backup'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="R:"; Label="Backup"}

$drive = Get-WmiObject -Class win32_volume -Filter "label = 'Temp'"

Set-WmiInstance -input $drive -Arguments @{DriveLetter="T:"; Label="Temp"}


Start-Sleep -Seconds 10
try{
    mkdir "D:\SQLData"
}
Catch{
    Write-Host "Unable to Create Directory D:\SQLData" -ForegroundColor Red
}
Try{
    mkdir "L:\SQLLogs"
}
Catch{
    Write-Host "Unable to Create Directory L:\SQLLogs" -ForegroundColor Red
}
Try{
    mkdir "R:\SQLBackups"
}
Catch{
    Write-Host "Unable to Create Directory R:\SQLBackups" -ForegroundColor Red
}
Try{
    mkdir "R:\SQLJobLogs"
}
Catch{
    Write-Host "Unable to Create Directory R:\SQLJobLogs" -ForegroundColor Red
}
Try{
    mkdir "T:\SQLData"
}
Catch{
    Write-Host "Unable to Create Directory T:\SQLData" -ForegroundColor Red
}
Try{
    mkdir "T:\SQLLogs"
}
Catch{
    Write-Host "Unable to Create Directory T:\SQLLogs" -ForegroundColor Red
}
Try{
    mkdir "D:\RSConfig"
}
Catch{
    Write-Host "Unable to Create Directory D:\RSConfig" -ForegroundColor Red
}
Try{
    mkdir "D:\RSInstall"
}
Catch{
    Write-Host "Unable to Create Directory D:\RSInstall" -ForegroundColor Red
    }    
  }
  Try{
    mkdir "D:\DicomImageStorage"
}
Catch{
    Write-Host "Unable to Create Directory D:\DicomImageStorage" -ForegroundColor Red
}
Try{
    mkdir "D:\DicomImageStorage\Import"
}
Catch{
    Write-Host "Unable to Create Directory D:\DicomImageStorage\Import" -ForegroundColor Red
}
Try{
    mkdir "D:\DicomImageStorage\Export"
}
Catch{
    Write-Host "Unable to Create Directory D:\DicomImageStorage\Export" -ForegroundColor Red
}


}

elseif($BuildType -match "test" -or "smallsite"){
    $Drives = Get-WmiObject -Class win32_volume
    if($ProdDisks = $Settings.SQL.NEWDISKS -match "y"){
    foreach($Drive in $Drives){
        $DriveLetter = $Drive.DriveLetter
            if($DriveLetter -match "D:"){
                Write-Host "Please Disconnect Disk Drive if Connected"
                Write-Host -NoNewLine 'Press any key when drive is disconnected to continue';
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
            }
    }
}
    $Readhost = $Settings.SQL.NEWDISKS
    Switch ($ReadHost) 
     { 
       Y {
 $Disks = $Settings.SQL.DISKNUMBER
 If($Disks -eq 1){
    Get-Disk | Where-Object partitionstyle -eq 'raw' | Select-Object -first 1 | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter  -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DATA" -AllocationUnitSize 65536 -Confirm:$false
 
    $drive = Get-WmiObject -Class win32_volume -Filter "label = 'Data'"
    Set-WmiInstance -input $drive -Arguments @{DriveLetter="D:"; Label="Data"}
 }
 elseif ($Disks -eq 2) {
    Get-Disk | Where-Object partitionstyle -eq 'raw' | Select-Object -first 1 | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter  -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DATA" -AllocationUnitSize 65536 -Confirm:$false
    Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter  -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "FileStream" -Confirm:$false    
  
    $drive = Get-WmiObject -Class win32_volume -Filter "label = 'Data'"
    Set-WmiInstance -input $drive -Arguments @{DriveLetter="D:"; Label="Data"}    
    
    $drive = Get-WmiObject -Class win32_volume -Filter "label = 'FileStream'"
    Set-WmiInstance -input $drive -Arguments @{DriveLetter="I:"; Label="FileStream"}
 }          
; $PublishSettings -eq $true
}
N{
 Write-Host "Skipping disk format"   ; $PublishSettings=$false
}
Default {
    Write-Host "Skipping disk format"   ; $PublishSettings=$false
}
     }
$SQLDrive = $Settings.SQL.SQLDRIVE
$SQLDrive = $SQLDrive + ":"
$FileStreamDrive = $Settings.SQL.FILESTREAMDRIVE
$FileStreamDrive = $FileStreamDrive + ":"
Try{
    mkdir "$SQLDrive\DicomImageStorage"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\DicomImageStorage" -ForegroundColor Red
}
Try{
    mkdir "$SQLDrive\DicomImageStorage\Import"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\DicomImageStorage\Import" -ForegroundColor Red
}
Try{
    mkdir "$SQLDrive\DicomImageStorage\Export"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\DicomImageStorage\Export" -ForegroundColor Red
}
Try{
    mkdir "$SQLDrive\RSConfig"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\RSConfig" -ForegroundColor Red
}
Try{
    mkdir "$SQLDrive\RSInstall"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\RSInstall" -ForegroundColor Red    
}
Try{
    mkdir "$SQLDrive\SQLServer"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\SQLServer" -ForegroundColor Red   
}
Try{
    mkdir "$SQLDrive\SQLServer\Backup"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\SQLServer\Backup" -ForegroundColor Red 
}
Try{
    mkdir "$SQLDrive\SQLServer\Data"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\SQLServer\Data" -ForegroundColor Red 
}
Try{
    mkdir "$SQLDrive\SQLServer\Logs"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\SQLServer\Logs" -ForegroundColor Red 
}
Try{
    mkdir "$SQLDrive\SQLServer\TempDB"
}
Catch{
    Write-Host "Unable to Create Directory $SQLDrive\SQLServer\TempDB" -ForegroundColor Red 
}
    if($SQLDrive -ne $FileStreamDrive){
        Try{
            mkdir "$FileStreamDrive\SQLServer"
        }
        Catch{
            Write-Host "Unable to Create Directory $FileStreamDrive\SQLServer" -ForegroundColor Red 
        }
}
Try{
mkdir "$FileStreamDrive\SQLServer\FileStream"
}
Catch{
    Write-Host "Unable to Create Directory $FileStreamDrive\SQLServer\FileStream" -ForegroundColor Red 
 }
}




$InstallSQL = $Settings.SQL.INSTALLSQL
if($InstallSQL -match "y"){

$SQLLOCATION = $Settings.SQL.SQLLOCATION

if(Test-Path -Path $SQLLOCATION){

Write-Host "Mounting disk image file '$ImageFile'..."
$DiskImage = Mount-DiskImage $SQLLOCATION -PassThru
$DriveLetter = (Get-Volume -DiskImage $DiskImage).DriveLetter
$DriveLetter = $DriveLetter + ":\"
Write-Host "Copying contents of SQL ISO to C:\Setup\bin\SQL" -ForegroundColor Yellow
robocopy $DriveLetter "C:\setup\bin\SQL\" /E /NFL /NDL /NJH /NJS /nc /ns /np
Write-host "Copied contents of SQL iso to C:\setup\bin\SQL" -ForegroundColor Green
Dismount-DiskImage -InputObject $DiskImage
$Keyfile = Get-Content "C:\setup\bin\SQL\x64\DefaultSetup.ini"
$Key = $Keyfile -match "PID" -replace "PID=","" -replace '"',""

}  
else{
    Write-Host "Path to SQL ISO incorrect. Please Unzip SQL iso into C:\setup\bin\SQL" -ForegroundColor Red
    Write-Host -NoNewLine 'Press any key to continue when the ISO is unzipped';
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                
                $Keyfile = Get-Content "C:\setup\bin\SQL\x64\DefaultSetup.ini"
                $Key = $Keyfile -match "PID" -replace "PID=","" -replace '"',""
}

       $InstanceChoice = $Settings.SQL.DEFAULTINSTANCE
    if ($InstanceChoice -match "y"){
        $Instance = "RAYSTATION"
    }
    else{
     $Instance = Read-Host $Settings.SQL.SQLINSTANCE
    }
$FileStreamChoice = $Settings.SQL.DEFAULTINSTANCE
if ($FileStreamChoice -match "y"){
    $FilestreamShareName = "RAYSTATION"
}
    else{
    $FilestreamShareName = $Settings.SQL.FILESTREAMINSTANCE
    }
    $SAPWD = $Settings.SQL.SAPASSWORD

#if($BuildType -match "prod"){
#    $key = $Settings.SQL.SQLKEY
#}

if($BuildType -match "prod"){
C:\Setup\bin\SQL\SQLInstallProd.ps1 -Type $BuildType -Instance $Instance -FilestreamShareName $FilestreamShareName -SAPWD $SAPWD -Key $Key
& $SQLInstaller
}
elseif($BuildType -match "test"){
    $SQLInstaller = (C:\Setup\bin\SQL\SQLInstallProd.ps1 -Type $BuildType -DataDirectory $SQLDrive -Instance $Instance -FilestreamShareName $FilestreamShareName -SAPWD $SAPWD)
    & $SQLInstaller
    }
elseif($BuildType -match "smallsite"){
    $SQLInstaller = (C:\Setup\bin\SQL\SQLInstallProd.ps1 -Type $BuildType -DataDirectory $SQLDrive -Instance $Instance -FilestreamShareName $FilestreamShareName -SAPWD $SAPWD -Key $Key)
    & $SQLInstaller

}

Write-Host "Please note that Red 'Error' message is informational, not an actual error" -ForegroundColor Yellow -BackgroundColor  Red
Write-Host "SQL has finished installing" -ForegroundColor Green
}
Else{
    Write-Host "Finished Prepping Drives" -ForegroundColor Green
}
Stop-Transcript

Write-Host "" -