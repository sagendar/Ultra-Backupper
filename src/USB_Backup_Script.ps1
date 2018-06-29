$date = Get-Date -Format yyyyMMddHHmmss
$path = $MyInvocation.MyCommand.Path
$path = $path -replace "USB_Backup_Script.ps1", ""
$backup = $path + 'backup' 
$log = $path + "USBBackup.log"

echo "UltraBackupper started" > $log
$answer = Read-Host "Do you want to start UltraBackupper? (y/n)"

if ($answer.ToLowerInvariant().Equals("n")) {
    exit
}

if (Test-Path -Path $backup) {
    $existingFiles = Get-ChildItem -Path $backup
    foreach ($file in $existingFiles) {
        $file = $file -replace ".zip", ""
        $fileNameParsed = [datetime]::parseexact($file, 'yyyyMMddHHmmss', $null)
        if ($date.AddSeconds(-10) -lt $fileNameParsed) {
            $dateErrorMessage = "Script was executed at: " + $fileNameParsed + " now it is: " + $date
            echo $dateErrorMessage >> $log
            exit
        }
    } 
}
else {
    #create directory
    new-item $backup -itemtype directory
    echo "Folder created: " $backup >> $log
}

try {
    $dir = gwmi win32_diskdrive | ? {$_.interfacetype -eq "USB"} | % {gwmi -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} | % {gwmi -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | % {$_.deviceid}
}
catch {
    echo "Caught Error: Unable to locate External USB Drive for Backup." >> $log
    exit 
}
if ($dir) {}
else {
    echo "Null Drive Letter: Unable to locate External USB Drive [USB_D2D] for D2D Backup." >> $log
    exit 
}    

$dir = $dir + "\*"
$backup = $backup + "\" + $date

#COMPRESS USB STICK CONTENT
try {
    Compress-Archive -Path $dir -CompressionLevel Optimal -DestinationPath $backup
}
catch {
    $errorMessage = "COMPRESSION ERROR source folder: " + $dir + " destination folder: " + $backup
    echo $errorMessage >> $log
    exit
}

#UPLOAD COMPRESSED ARCHIVE TO GOOGLE DRIVE
#accestoken has to be refreshed every 24h https://developers.google.com/oauthplayground, usage/explanation https://github.com/MVKozlov/GMGoogleDrive
$accesstoken = "ya29.GlvpBY56Ptkh1DHUty-EKaXNkRiWMjHjq51ReTTGbEoWs1mBiWK3WsTQLocJi5rNI_CTmZpJqGuKsaUu35ya-pmZB9SkUHGfepOBH3wcFmohcM9AIQpl-UJQf9m2"
$contenttype = "Content-type: application/x-zip-compressed"
$uri = "https://www.googleapis.com/upload/drive/v3/files"
$file = $backup + ".zip"
$stream = New-Object System.IO.FileStream $file, 'Open'

$Headers = @{
    "Authorization"           = "Bearer $accesstoken"
    "Content-type"            = "application/json"
    "X-Upload-Content-Type"   = $contenttype
    "X-Upload-Content-Length" = $stream.Length
}
$stream.Close()
Invoke-RestMethod -Uri $uri -Method Post -InFile $file -Headers $Headers

echo $date >> $log
echo Done. >> $log