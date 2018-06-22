$date = Get-Date -Format yyyyMMddHHmm
$path = $MyInvocation.MyCommand.Path
$path = $path -replace "USB_Backup_Script.ps1", ""
$backup = $path + 'backup' 
$log = $path + "USBBackup.log"

echo "UltraBackupper started" > $log
$answer = Read-Host "Do you want to start UltraBackupper? (y/n)"

if($answer.ToLowerInvariant().Equals("n")){
    exit
}

$existingFiles = Get-ChildItem -Path $backup
foreach ($file in $existingFiles) {
    $fileNameParsed = [datetime]::parseexact($file, 'yyyyMMddHHmm', $null)
    if($date.AddSeconds(-10) -lt $fileNameParsed){
        $dateErrorMessage = "Script was executed at: " + $fileNameParsed + " now it is: " + $date
        echo $dateErrorMessage >> $log
        exit
    }
}

try
{
    $dir = gwmi win32_diskdrive | ?{$_.interfacetype -eq "USB"} | %{gwmi -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} |  %{gwmi -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | %{$_.deviceid}
}
catch
{
    echo "Caught Error: Unable to locate External USB Drive for Backup." >> $log
    exit 
}
if ($dir) {}
else
{
    echo "Null Drive Letter: Unable to locate External USB Drive [USB_D2D] for D2D Backup." >> $log
    exit 
}    

$dir = $dir + "\*"
$backup = $backup + "\" + $date

#create directory
new-item $backup -itemtype directory

#COMPRESS USB STICK CONTENT
try{
Compress-Archive -Path $dir -CompressionLevel Optimal -DestinationPath $backup
} catch{
    $errorMessage = "COMPRESSION ERROR source folder: " + $dir + " destination folder: " + $backup
    echo $errorMessage >> $log
    exit
}
#UPLOAD COMPRESSED ARCHIVE TO GOOGLE DRIVE


echo $date >> $log
echo Done. >> $log