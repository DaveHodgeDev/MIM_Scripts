##############################################################################################################
# CommitChanges.ps1
# Copyright © 2009 Microsoft Corporation
# This script applies the changes necessary to migrate configuration.
##############################################################################################################

if(@(get-pssnapin | where-object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {add-pssnapin FIMAutomation}

$changes_filename = "D:\code\base\serviceconfig\SchemaChanges.xml"
$undone_filename = "D:\code\base\serviceconfig\SchemaChanges_undone.xml"

$imports = ConvertTo-FIMResource -file $changes_filename

if($imports -eq $null)
{
    throw (new-object NullReferenceException -ArgumentList "Changes is null.  Check that the changes file has data.")
}

Write-Host "Importing changes into production."

$undoneImports = $imports | Import-FIMConfig

if($undoneImports -eq $null)
{
    Write-Host "Import complete."
}
else
{
    Write-Host
    Write-Host "There were " $undoneImports.Count " uncompleted imports."
    $undoneImports | ConvertFrom-FIMResource -file $undone_filename
    Write-Host
    Write-Host "Please see the documentation on how to resolve the issues."
}