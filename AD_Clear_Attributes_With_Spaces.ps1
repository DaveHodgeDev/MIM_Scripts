#Search in a remote AD Domain for attributes with spaces...

$DC= "DC01.CONTOSSO.COM"
$LDAP = "dc=contosso,dc=com"
$account = "CONTOSSO\SVC_MIMADMA"
$pwd = read-host "Enter the password for $account "
$attribute = read-host "Enter the attribute:"

write-host "facsimileTelephoneNumber"
write-host "department"
write-host ""
write-host ""

#############################################################################
# Establish connection to remote directory
#############################################################################
$domainInfo = New-Object DirectoryServices.DirectoryEntry("LDAP://$dc/$ldap",$account,$pwd)
$Searcher = New-Object DirectoryServices.DirectorySearcher($domainInfo)

$Searcher.PageSize=150000
$Searcher.SearchScope = "Subtree"
$Searcher.filter = "(&($attribute=\20))"

#############################################################################
# Initiate search
#############################################################################
$colResults = $Searcher.FindAll()

write-host "###################################################"
write-host "Total objects: $($colresults.Count)"
write-host "###################################################"


#############################################################################
# Enumerate search results
#############################################################################
foreach ($objResult in $colResults)
{
    [String] $strLine = $null
    $strLine = "$($objresult.Path)" 
    $strLine = $($strLine.Replace("$dc/",""))

    Add-Content "C:\code\Scripts\EmptyString_$attribute.txt" "$strLine`t$attribute" 
    
    $de = new-Object DirectoryServices.directoryEntry($strLine,$account,$pwd)
    #Write-Host "Parent Path: $($de.Parent)"

    #############################################################################
    # Clear values
    #############################################################################
    #$de.putex(1,"$attribute",$null)
    #$de.SetInfo()
    
    $de.Dispose()
}
