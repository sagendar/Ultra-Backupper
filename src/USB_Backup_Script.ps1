echo "USB Backup started" > c:\temp\USBBackup.log

try
{
    $x = gwmi win32_diskdrive | ?{$_.interfacetype -eq "USB"} | %{gwmi -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} |  %{gwmi -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | %{$_.deviceid}
}
catch
{
    echo "Caught Error: Unable to locate External USB Drive for Backup." >> c:\temp\USBBackup.log
    exit 
}

if ($x) {}
else
{
    echo "Null Drive Letter: Unable to locate External USB Drive [USB_D2D] for D2D Backup." >> c:\temp\USBBackup.log
    exit 
}    

#COMPRESS USB STICK CONTENT
#UPLOAD COMPRESSED ARCHIVE TO GOOGLE DRIVE

$d = get-date
echo $d >> c:\temp\USBBackup.log
echo Done. >> c:\temp\USBBackup.log