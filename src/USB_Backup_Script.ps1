$date = Get-Date -Format yyyyMMddTHHmm
$path = $MyInvocation.MyCommand.Path
$path = $path -replace "USB_Backup_Script.ps1", ""
$backup = $path + 'backup'
$log = $path + "USBBackup.log"

echo "UltraBackupper started" > $log

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
    
#COMPRESS USB STICK CONTENT
Compress-Archive -Path $x -CompressionLevel Optimal -DestinationPath C:\temp\$d

#UPLOAD COMPRESSED ARCHIVE TO GOOGLE DRIVE


echo $date >> .\USBBackup.log
echo Done. >> .\USBBackup.log