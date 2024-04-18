Function Export_Tasks
{
  Param ([string] $Folder)

  $Tasks = Get-ScheduledTask -TaskPath "\MIM\" | where {$_.TaskName -notlike "Optimize*"}

  foreach($task in $tasks.TaskName)
  {
    write-host "Task: $task"
    Export-ScheduledTask -TaskName $Task -TaskPath "\MIM\" | out-file "$Folder\$Task.xml"
  }
}

Function Import_Tasks
{
    Param ([string] $Folder, [string]$Task, [string] $TaskPath, [string] $User, [string] $Pass)

    $xml = Get-Content "$Folder\$Task" -Raw
    $TaskName = [IO.Path]::GetFileNameWithoutExtension($Task)

    Register-ScheduledTask -Xml $xml -TaskName $TaskName -TaskPath $TaskPath -User $user -Password $pass
}


#######################################################################
# Variables
#######################################################################
$Folder = "C:\CODE\MIM-Sync-ScheduledTasks"
$User = "Domain\ServiceAccount" 
$Pass = Read-Host "Enter the password for $User"

#######################################################################
# Export Scheduled Tasks
#######################################################################
Export_Tasks $Folder

#######################################################################
# Import Scheduled Tasks
#######################################################################
$Files = get-childitem $FOLDER| Select Name

foreach($file in $files.name)
{
    Write-Host "File: $file"
    Import_Tasks $Folder $file "MIM2" $User $Pass
}
