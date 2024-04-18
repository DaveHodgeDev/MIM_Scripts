$dayDiff = "500"

$dateDelete = Get-Date
$dateDelete = $dateDelete.AddDays(-$dayDiff)
Write-Host "Deleting run history earlier than:" $dateDelete.toString('MM/dd/yyyy')
 
$lstSrv = @(get-wmiobject -class "MIIS_SERVER" -namespace "root\MicrosoftIdentityIntegrationServer" -computer ".")
Write-Host "Result: " $lstSrv[0].ClearRuns($dateDelete.toString('yyyy-MM-dd')).ReturnValue
