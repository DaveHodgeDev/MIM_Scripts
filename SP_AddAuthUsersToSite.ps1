# Assumes SP is already installed
# Assumes SP Site is already setup
# Assumes MIM is already installed

if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.PowerShell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.PowerShell}
 
# Add Authenticated Users are added to the SharePoint site
$group = "NT Authority\Authenticated Users"
$webapp.EnsureUser($group)
$ADGroupSPFriendly = $webapp | Get-SpUser $group
$GroupAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($ADGroupSPFriendly)
$GroupRole = $webApp.RoleDefinitions["Read"]
$GroupAssignment.RoleDefinitionBindings.Add($GroupRole)
$webApp.RoleAssignments.Add($GroupAssignment)
