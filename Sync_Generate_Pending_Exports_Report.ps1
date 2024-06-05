####################################################################
# Utilizes the CSExportAnalyzer utility from AAD Connect to generate 
# a CSV file of the pending export changes.
####################################################################

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
    #generateChangesFile "$maname"
    .\CSExportAnalyzer.exe ".\$($maName).xml" > "$($maname).csv"
}
