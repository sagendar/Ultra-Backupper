Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange
write-host (get-date -format s) " Beginning script..."
while (1 -eq 1) {
    $newEvent = Wait-Event -SourceIdentifier volumeChange
    $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
    $eventTypeName = switch ($eventType) {
        1 {"Configuration changed"}
        2 {"Device arrival"}
        3 {"Device removal"}
        4 {"docking"}
    }
    write-host (get-date -format s) " Event detected = " $eventTypeName
    if ($eventType -eq 2) {
        $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName
        $driveLabel = ([wmi]"Win32_LogicalDisk='$driveLetter'").VolumeName
        write-host (get-date -format s) " Drive name = " $driveLetter
        write-host (get-date -format s) " Drive label = " $driveLabel
        write-host (get-date -format s) " Starting task in 3 seconds..."
        start-sleep -seconds 3

        $path = $MyInvocation.MyCommand.Path
        $path = $path -replace "TriggerDetecter.ps1", ""

        $path = $path + "USB_Backup_Script.ps1"
        $arguments = "-file " + $path
        Start-Process powershell.exe -ArgumentList $arguments
    }
    
    Remove-Event -SourceIdentifier volumeChange
}
Unregister-Event -SourceIdentifier volumeChange