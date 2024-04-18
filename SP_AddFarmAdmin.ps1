# Assumes AD PowerShell cmdlets is installed
# Assumes SP PowerShell is installed

if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.PowerShell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.PowerShell}
 
#Get Netbios Name of the Domain
$Domain = get-addomain
[String] $NBName = $domain.NetBIOSName
 
# Domain Group to Add
$CA_Group = "$NBName\Some_AD_Group"
 
# Get SharePoint Web Application
$CA_WebApp = Get-SPWebApplication -IncludeCentralAdministration | where-object {$_.DisplayName -eq "SharePoint Central Administration v4"}
 
# Get SharePoint Web Site
$CA_Web = Get-SPWeb $CA_WebApp.Url
 
#Get Farm Administrators Group
$FarmAdminGroup = $CA_Web.SiteGroups["Farm Administrators"]
 
#Add group to the Group
$FarmAdminGroup.AddUser($CA_Group,"",$CA_Group, "")
Write-Host "Group: $($CA_Group) has been added to Farm Administrators Group!"
