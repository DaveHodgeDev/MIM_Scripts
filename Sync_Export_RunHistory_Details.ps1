
#############################################################################################
# Written By: Dave Hodge, MCS
# Date: 4/2/2020
# Purpose Export run history times from synchronization history
#############################################################################################
 
param(
        [Parameter(Position=0,mandatory=$false)]
        [DateTime] $Start,
        [Parameter(Position=1,mandatory=$false)]
        [DateTime] $End,
        [Parameter(Position=2,mandatory=$false)]
        [String] $Computer)
        
 
 
# Check local time
$DST = ([System.TimeZoneInfo]::ConvertTimeFromUtc(
    (get-date).ToString(),
    [System.TimeZoneInfo]::FindSystemTimeZoneById("Pacific Standard Time")
))
 
$DTOffset = $DST - $DST.ToLocalTime()
$Offset = $DTOffset.TotalHours
 
If (($Start -eq "") -or ($End -eq "") -or ($Computer -eq ""))
{
    Write-Host "To export job history:" -ForegroundColor Green
    Write-Host " - You must supply the start and end dates" -ForegroundColor Green 
    Write-Host " - The date fields must be in the following format: 'MM/DD/YYYY HH:MM:SS'" -ForegroundColor Green
    Write-Host " - The computer name of the sync server must be supplied, a period can be used to reflect localhost" -ForegroundColor Green
    Write-Host ""
    Write-Host "e.g. RunHistory.ps1 -Start '3/21/2020 00:00:00' -End '3/26/2021 12:00:00' -Computer ." -ForegroundColor Green
    Exit
}
 
$strStart =$Start.AddHours($OffSet).ToString('yyyy-MM-dd HH:mm:ss.fff')
$strEnd = $End.AddHours($OffSet).ToString('yyyy-MM-dd HH:mm:ss.fff')
 
#Build query filter
$GetRunStartTime="RunStartTime >= '$($strStart)' and RunEndTime <= '$($strEnd)'"
#Get all run history for a particular sequence of running job
$GetRunHistory = Get-WmiObject -class "MIIS_RunHistory" -namespace root\MicrosoftIdentityintegrationServer -ComputerName $Computer -Filter $GetRunStartTime 
 
If (Test-path .\history.txt)
{
    erase .\history.txt
}
 
"MA`tRun Profile`tResults`tStart Time`tEndTime`tTotal Time" | out-file ".\history.txt" -append
#Do something if there is history... 
if($GetRunHistory -ne $null)
{ 
    # Loop through all of the steps 
    foreach($Run_History in $GetRunHistory)
    { 
        [xml]$gRunHistory = $Run_History.RunDetails().ReturnValue
        $MA_Name = $gRunHistory.'run-history'.'run-details'.'ma-name'
        $MA_RUN=$gRunHistory.'run-history'.'run-details'.'run-number'
        $MA_RUNPROFILENAME=$gRunHistory.'run-history'.'run-details'.'run-profile-name'
           
        #step-details information 
        $GetRunStepDetails= $gRunHistory.'run-history'.'run-details'.'step-details'
        $errs = $null
        $strType = $null
        [DateTime]$dtStart = $($getrunstepdetails.'start-date')
        [DateTime]$dtEnd = $($getrunstepdetails.'end-date')
        [TimeSpan]$dtTotal = $dtEnd.Subtract($dtStart)
 
        Write-Host $($getrunstepdetails.'step-result')
        write-host "$($ma_name)`t$($ma_runprofilename)`t$($getrunstepdetails.'step-result')`t$($dtStart.ToLocalTime())`t$($dtEnd.ToLocalTime())`t$($dtTotal.ToString())" 
        "$($ma_name)`t$($ma_runprofilename)`t$($getrunstepdetails.'step-result')`t$($dtStart.ToLocalTime())`t$($dtEnd.ToLocalTime())`t$($dtTotal.ToString())" | out-file ".\history.txt" -append


#############################################################################
# Pathing to Stage-Delete...
#############################################################################

        # $gRunHistory.'run-history'.'run-details'.'step-details'.'staging-counters'.'stage-delete'
#        <#        
        foreach($runstep in $GetRunStepDetails)
        {
            if ($runstep.'synchronization-errors'.InnerXml -ne $null)
            {
                if ($runstep.'synchronization-errors'.InnerXml.Contains("<export-error"))
                {
                    $strType = "export"
                    $errs = $runstep.'synchronization-errors'.'export-error'
                }
                else
                {
                    $strType = "import"
                    $errs = $runstep.'synchronization-errors'.'import-error'
                }
                if ($errs -ne $null)
                {
                    If ($errs.Count -gt 0)
                    {
                        for($i=0;$i -lt $errs.count;$i++)
                        {
                            write-host "'$ma_name'," + "'$($runstep.'step-number')'," + "'$($runstep.'step-result')'," + "'$($errs[$i].dn)'," + "'$($errs[$i].'retry-count')'," + "'$($errs[$i].'date-occurred')'," + "'$($errs[$i].'first-occurred')'," + "'$($runstep.'start-date')'," + "'$($errs[$i].'error-type')'," + "'$strType'"
                        }
                    }
                    Else
                    {
                            write-host "'$ma_name'," + "'$($runstep.'step-number')'," + "'$($runstep.'step-result')'," + "'$($errs.dn)'," + "'$($errs.'retry-count')'," + "'$($errs.'date-occurred')'," + "'$($errs.'first-occurred')'," + "'$($runstep.'start-date')'," + "'$($errs.'error-type')'," + "'$strType'"
                    }
                }
            }
        }
        #>

    }
}
 
