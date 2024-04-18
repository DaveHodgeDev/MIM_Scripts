
#######################################################################
# Add PowerShell SnapIn for SharePoint
#######################################################################
if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.Powershell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.Powershell -EA 0}

#######################################################################
# Set SharePoint site to use Kerberos
#######################################################################
Get-SPWebApplication "IdentityManagement" | Set-SPWebApplication -AuthenticationMethod "Kerberos" -Zone "Default"

#######################################################################
# Set site to use App Pool credentials
#######################################################################
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'IdentityManagement' -filter "system.webServer/security/authentication/windowsAuthentication" -name "useAppPoolCredentials" -value "True"

#######################################################################
# Set site to use Kernal Mode
#######################################################################
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'IdentityManagement' -filter "system.webServer/security/authentication/windowsAuthentication" -name "useKernelMode" -value "True"

#######################################################################
# Set site to use Windows Authentication
#######################################################################
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'IdentityManagement' -filter "system.webServer/security/authentication/windowsAuthentication" -name "enabled" -value "True" 

#######################################################################
# Refresh IIS
#######################################################################
Iisreset



###################################################################
# Variables to adjust 
###################################################################
$HOSTNAME_MIMSharePoint = "mimportal.<domain> "

$Domain = ""
$installer = ""
$SVC_MIMSHAREPOINT = ""

###################################################################
# Add SharePoint PowerShell Snapin
###################################################################
if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.Powershell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.Powershell -EA 0}

###################################################################
# Remove unused IIS Sites
# https://technet.microsoft.com/en-us/library/cc262392.aspx#section1
###################################################################
get-website -Name "Default Web Site" | Remove-Website
sleep -seconds 5

###################################################################
# Set Managed Account
###################################################################
$SPF_FarmAccountName = "$Domain\$SVC_MIMSHAREPOINT"
$cred = Get-Credential ($SPF_FarmAccountName)
$check = Get-SPManagedAccount -Identity $SVC_MIMSHAREPOINT

if ($check -eq $null)
{
    New-SPManagedAccount -Credential $cred
}


###################################################################
# Create SP Web Application
###################################################################
New-SPWebApplication -Name "IdentityManagement" -Port 80 -HostHeader $HOSTNAME_MIMSharePoint -URL http://$HOSTNAME_MIMSharePoint -ApplicationPool "IDMPortalAppPool" -ApplicationPoolAccount (Get-SPManagedAccount $SPF_FarmAccountName) -AuthenticationMethod "Kerberos"

###################################################################
# Create SP Site
###################################################################
New-SPSite -Name "IdentityManagement" -URL http://$HOSTNAME_MIMSharePoint -OwnerAlias "$domain\$INSTALLER" -Language 1033 -CompatibilityLevel 15 -Template "STS#1"

###################################################################
# Disable Server-side viewstate 
###################################################################
$contentService=[Microsoft.SharePoint.Administration.SPWebService]::ContentService
$contentService.ViewStateOnServer = $false
$contentService.Update()

###################################################################
# Add Alternative access mappings
###################################################################
$webAppName = (Get-SPWebApplication).Name
      
New-SPAlternateURL -WebApplication $webAppName –Zone "Default" -URL http://localhost -Internal
New-SPAlternateURL -WebApplication $webAppName –Zone "Default" -URL http://$HOSTNAME_MIMSharePoint  
