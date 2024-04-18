#Exports the Pending Exports in the connector space to an xml file (<ma>.xml) and then runs the AAD Connect utility (CSExportAnalyzer.exe) to generate a CSV file.

Function GenerateChangesFile
{
PARAM ([Parameter(Mandatory=$true)][string]$MA_NAME)

    if (Test-Path(".\$MA_Name.xml"))
    {
        erase ".\$MA_Name.xml"
    }

    if (Test-Path(".\$MA_Name.csv"))
    {
        erase ".\$MA_Name.csv"
    }

    & "D:\Program Files\Microsoft Forefront Identity Manager\2010\Synchronization Service\Bin\csexport.exe" "$MA_NAME" "D:\MIM\PendingExportsReview\$MA_Name.xml" /fx /od
    Write-Host "File is located at: D:\MIM\PendingExportsReview\$MA_Name.xml" -ForegroundColor Green
}

#-------------------------------------------------------------------------------------------------
write-host "`nConfigured Management Agents"  
write-host "============================"

$lstMA = @(get-wmiobject -class "MIIS_ManagementAgent" `
                         -namespace "root\MicrosoftIdentityIntegrationServer" `
                         -computername ".") 

if($lstMA.count -eq 0) 
{
    throw "There is no management agent configured"
}

$lstMA | format-list -property Name #, Type, Guid

foreach($ma in $lstMA)
{
    $maname = "$($ma.Name)"
    generateChangesFile "$maname"
    Sleep -Seconds 1
    .\CSExportAnalyzer.exe ".\$($maName).xml" > "$($maname).csv"
}

#-------------------------------------------------------------------------------------------------
trap 
{
   Write-Host "`nError: $($_.Exception.Message)`n" -foregroundcolor white -backgroundcolor darkred    
   Exit 1
}
#----------------------------------------------------------------------------------
