##############################################################################
# Import the module
##############################################################################
Import-Module LithnetRMA;

$ErrorActionPreference = "SilentlyContinue"

##############################################################################
# Connect to the FIM service instance
##############################################################################
Set-ResourceManagementClient -BaseAddress http://localhost:5725;

##############################################################################
#Add the object's ObjectID into the Owners variable
##############################################################################
Function LookupOwners
{
Param ([string] $lGroup, [string] $AccountName)
    #write-host "Look up $AccountName"
    #write-host "$($IDTable.Count)"

    If($IDTable[$AccountName] -eq $null)
    {
        $obj = Get-Resource -ObjectType Person -AttributeName AccountName -AttributeValue $AccountName
        if ($obj -eq $null)
        {
            write-host "$accountname not found" -ForegroundColor red
            "$lGroup`t$AccountName" | Out-File .\AddGroupOwner-NotFound.txt -Append
        }
        $global:owners += $($obj.ObjectID)
        $IDTable.Add($AccountName,$($obj.ObjectID))
    }
    Else
    {
        write-host "Found cache"
        $global:owners += $IDTable[$AccountName].ToString()
    }
}

Function UpdateGroupOwnersByAccountName
{ Param ([string] $AccountName)
    #$group=$null
    #$groups=$null

    $groups = Search-Resources -XPath "/Group[AccountName = '$AccountName']" -AttributesToGet @("AccountName", "DisplayName", "DisplayedOwner", "Owner")

    Write-host "`t#######################################################" -ForegroundColor White
    Write-host "`tAccountName: $AccountName" -ForegroundColor White
    Write-host "`tOwners: $owners" -ForegroundColor White
    Write-Host "`tDisplayed Owner: $($owners[0])" -ForegroundColor White

    foreach ($group in $groups)
    {
        Write-Host "`t----------------------------------------------------------------------"
        write-host "`tDisplayName: $($group.DisplayName)" -ForegroundColor White
        write-host "`tAccountName: $($group.AccountName)" -ForegroundColor White
        write-host "`tOwner: $($group.Owner)" -ForegroundColor White
        write-host "`tDisplay Owner: $($group.DisplayedOwner)" -ForegroundColor White
        $group.Owner = $owners
        $group.DisplayedOwner = $($owners[0])
    }

    Save-Resource $groups
}

##############################################################################
# Add the accounts for lookup into the array
##############################################################################
$accounts = New-Object collections.arraylist
$IDTable = New-Object 'system.collections.generic.dictionary[string,string]'

##############################################################################
# Get paramters from a .csv file 
#  - comment out to do bulk updates by XPath Query 
#  - method for populating non-departmental groups with distinct owners
##############################################################################
$lines = Import-Csv .\GroupOwners.txt -Delimiter `t
$x = 0

ForEach($line in $lines)
{
    ##############################################################################
    # Declare the owners
    ##############################################################################
    $owners = New-Object collections.arraylist

    ##############################################################################
    # Display CSV File Entry
    ##############################################################################
    $x = $x + 1
    Write-Host "###############################################" -ForegroundColor Green
    Write-Host "$x of $($lines.Count)" -ForegroundColor Green
    Write-Host "GroupName: $($line.Group)" -ForegroundColor Green
    Write-Host "Owners: $($line.Owners)" -ForegroundColor Green

    $strOwners = $line.Owners.Split(",")

    foreach($csvowner in $strOwners)
    {
        #write-host "`tOwner: $csvowner"
        LookupOwners $($line.Group) $csvowner
    }

    write-host "Owners: $owners" -ForegroundColor green

    UpdateGroupOwnersByAccountName $($line.Group)
}

exit
