Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange
while (1 -eq 1) {
    $newEvent = Wait-Event -SourceIdentifier volumeChange
    $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
    if ($eventType -eq 2) { #Device arrival        
        $path = $MyInvocation.MyCommand.Path
        $path = $path -replace "TriggerDetecter.ps1", "USB_Backup_Script.ps1"

        $arguments = "-file " + $path
        Start-Process powershell.exe -ArgumentList $arguments -Wait
    }
    
    Remove-Event -SourceIdentifier volumeChange
}
Unregister-Event -SourceIdentifier volumeChange