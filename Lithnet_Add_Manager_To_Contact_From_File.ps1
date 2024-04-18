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

Function UpdateObjectManagerByAccountName
{ Param ([string] $MailNickname, [string] $Manager)

    $obj = $null
    $obj = Get-Resource -ObjectType Person -AttributeName AccountName -AttributeValue $manager
    
    if ($obj -eq $null)
    {
        write-host "$accountname not found" -ForegroundColor red
        "$MailNickName`t$Manager" | Out-File .\AddContactManager-NotFound.txt -Append
        exit
    }

    $objects = Search-Resources -XPath "/mcsContact[MailnickName = '$MailNickname']" -AttributesToGet @("MailNickname", "DisplayName", "Manager")

    Write-host "`t#######################################################" -ForegroundColor White
    Write-host "`tMailNickname: $MailNickname" -ForegroundColor White
    Write-host "`tManager: $Manager" -ForegroundColor White

    foreach ($object in $objects)
    {
        Write-Host "`t----------------------------------------------------------------------"
        write-host "`tDisplayName: $($object.DisplayName)" -ForegroundColor White
        write-host "`tMailNickname: $($object.MailNickname)" -ForegroundColor White
        write-host "`tManager: $($object.Manager)" -ForegroundColor White
        $object.Manager = $($obj.ObjectID)
    }

    Save-Resource $objects
}

##############################################################################
# Get parameters from a .csv file 
#  - comment out to do bulk updates by XPath Query 
#  - method for populating non-departmental groups with distinct owners
# MailNickname, Manager
##############################################################################
$lines = Import-Csv .\Contact_Owners.txt -Delimiter `t
$x = 0

ForEach($line in $lines)
{
    ##############################################################################
    # Declare the owners
    ##############################################################################
    #$owners = New-Object collections.arraylist

    $MailNickname = $($line.MailNickname)
    $manager = $($line.manager)

    ##############################################################################
    # Display CSV File Entry
    ##############################################################################
    $x = $x + 1
    Write-Host "###############################################" -ForegroundColor Green
    Write-Host "$x of $($lines.Count)" -ForegroundColor Green
    Write-Host "MailNickname: $MailNickname" -ForegroundColor Green
    Write-Host "Manager: $Manager" -ForegroundColor Green

    UpdateObjectManagerByAccountName $MailNickname $Manager
}

exit
