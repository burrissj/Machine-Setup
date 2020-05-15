# Download and silent install Java Runtime Environnement

# working directory path
$WorkingDirectory = "c:\setup\bin\java\"

# Check if work directory exists if not create it
If (!(Test-Path -Path $WorkingDirectory -PathType Container))
{ 
New-Item -Path $WorkingDirectory  -ItemType directory 
}

#create config file for silent install
$text = '
INSTALL_SILENT=Enable
AUTO_UPDATE=Enable
SPONSORS=Disable
REMOVEOUTOFDATEJRES=1
'
$text | Set-Content "$WorkingDirectory\jreinstall.cfg"
    
#download executable, this is the small online installer
[Net.ServicePointManager]::SecurityProtocol = "tls12"
$source = "http://javadl.oracle.com/webapps/download/AutoDL?BundleId=230511_2f38c3b165be4555a1fa6e98c45e0808"
$destination = "$WorkingDirectory\jreInstall.exe"
$client = New-Object System.Net.WebClient
$client.DownloadFile($source, $destination)

#install silently
Start-Process -FilePath "$WorkingDirectory\jreInstall.exe" -ArgumentList INSTALLCFG="$WorkingDirectory\jreinstall.cfg" -Wait

# Remove the installer
Remove-Item $WorkingDirectory\jre* -Force