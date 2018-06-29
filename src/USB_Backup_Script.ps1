$date = Get-Date -Format yyyyMMddHHmmss
$path = $MyInvocation.MyCommand.Path
$path = $path -replace "USB_Backup_Script.ps1", ""
$log = $path + "USBBackup.log"

echo "UltraBackupper started" > $log
$answer = Read-Host "Do you want to start UltraBackupper? (y/n)"

if ($answer.ToLowerInvariant().Equals("n")) {
    exit
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
$backupFilePath = $path + "\" + $date

#COMPRESS USB STICK CONTENT
try {
    Compress-Archive -Path $dir -CompressionLevel Optimal -DestinationPath $backupFilePath
}
catch {
    $errorMessage = "COMPRESSION ERROR source folder: " + $dir + " destination folder: " + $backupFilePath
    echo $errorMessage >> $log
    exit
}

#UPLOAD COMPRESSED ARCHIVE TO GOOGLE DRIVE
#accestoken has to be refreshed every 24h https://developers.google.com/oauthplayground, usage/explanation https://github.com/MVKozlov/GMGoogleDrive
$accesstoken = "ya29.GlvpBYqr7udwTqBNKi4EuUOxKfGYFpNpDYj_zmGumvnfV-q6R0TSavLO124nASV_EAysG-R15FIMfH3QK6oh6Cuy47WbODSxSUc1WSNGI1svpYyy9yl4s7J6d_uC"
$uri = "https://www.googleapis.com/upload/drive/v3/files"
$filePath = $backupFilePath + ".zip"

# Get the source file contents and details, encode in base64
$sourceItem = Get-Item $filePath
$sourceBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($sourceItem.FullName))


# Set the file metadata
$uploadMetadata = @{
    originalFilename = $sourceItem.Name
    name = $sourceItem.Name
    description = $sourceItem.VersionInfo.FileDescription
}

# Set the upload body
$uploadBody = @"
--boundary
Content-Type: application/json; charset=UTF-8

$($uploadMetadata | ConvertTo-Json)

--boundary
Content-Transfer-Encoding: base64
Content-Type: application/zip

$sourceBase64
--boundary--
"@

$Headers = @{
    "Authorization"           = "Bearer $accesstoken"
    "Content-type"            = 'multipart/related; boundary=boundary'
    "X-Upload-Content-Length" = $uploadBody.Length
}

#Send upload- (POST) request
Invoke-RestMethod -Uri $uri -Method Post -Headers $Headers -Body $uploadBody

#remove uploaded zip file
Remove-Item -Path $filePath

echo $date >> $log
echo Done. >> $log
