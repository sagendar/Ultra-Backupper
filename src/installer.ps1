ipmo ScheduledTasks 
$path = $MyInvocation.MyCommand.Path
$path = $path -replace "installer.ps1", ""
$path = $path + 'TriggerDetecter.ps1' 
$yeet = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden ' + $path
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $yeet
$trigger =  New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "UltraBackupper" -Description "Automatic Ultra USB Backupper" 