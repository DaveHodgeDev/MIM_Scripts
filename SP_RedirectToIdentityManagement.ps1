# Assumes SP is already installed
# Assumes SP Site is already setup
# Assumes MIM is already installed

if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.PowerShell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.PowerShell}
 
$url = (Get-SPSite).url
$webApp = Get-SPWeb $url
$root = $webApp.RootFolder
$root.WelcomePage = "IdentityManagement/default.aspx"
$root.Update()
