#######################################################################################
# Variables to update
#######################################################################################
$Domain="CONTOSSO"
$SVC_MIMSERVICE="SVC_MIMSERVICE"
$SVC_MIMSYNC="SVC_MIMSYNC"
$SVC_MIMSCHEDULER="SVC_MIMSCHEDULER"
$SVC_MIMMA = "SVC_MIMMA"

#######################################################################################
# Function that will assign rights to Local Group Policy
# Based on script located at:
# https://gallery.technet.microsoft.com/PowerShell-script-to-add-b005e0f6
#######################################################################################
Function Add_UserRightsAssignment
{
    Param([string]$accountToAdd,[string]$URA_Permission, [string]$URA_FriendlyName)
        
    # Original Function written by Ingo Karstein, http://ikarstein.wordpress.com
    # v1.0, 10/12/2012
 
    #################################################################
    # List of Allow Rights for reference
    #################################################################
    # SeServiceLogonRight - Allow Log on as a Service 
    # SeInteractiveLogonRight - Allow Logon Locally
 
    #################################################################
    # List of Deny Rights for reference
    #################################################################
    # SeDenyNetworkLogonRight - Deny access to this computer from the network 
    # SeDenyBatchLogonRight - Deny logon as a batch job
    # SeDenyServiceLogonRight - Deny logon as a service
    # SeDenyInteractiveLogonRight - Deny logon locally
    # SeDenyRemoteInteractiveLogonRight - Deny log on through Remote Desktop Services
 
    #######################################################################################
    # Get SID for account
    #######################################################################################
    $sidstr = $null
 
    try 
    {
        $ntprincipal = new-object System.Security.Principal.NTAccount "$accountToAdd"
        $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
        $sidstr = $sid.Value.ToString()
    } 
    catch 
    {
        $sidstr = $null
    }
 
    Write-Host "Account: $($accountToAdd)" -ForegroundColor Green
 
    if([string]::IsNullOrEmpty($sidstr)) 
    {
          Write-Host "Account not found!" -ForegroundColor Red
          exit -1
    }
 
    Write-Host "Account SID: $($sidstr)" -ForegroundColor Green
 
    $tmp = [System.IO.Path]::GetTempFileName()
 
    Write-Host "Export current Local Security Policy" -ForegroundColor Green
    secedit.exe /export /cfg "$($tmp)" 
 
    $c = Get-Content -Path $tmp 
 
    $currentSetting = ""
 
    foreach($s in $c) 
    {
        if( $s -like "$URA_Permission*") 
        {
            $x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
            $currentSetting = $x[1].Trim()
        }
    }
 
    if($currentSetting -notlike "*$($sidstr)*") 
    {
        Write-Host "Modify Setting ""$URA_FriendlyName""" -ForegroundColor Green
      
        if([string]::IsNullOrEmpty($currentSetting)) 
        {
            $currentSetting = "*$($sidstr)"
        } 
        else 
        {
            $currentSetting = "*$($sidstr),$($currentSetting)"
        }
      
        Write-Host "$currentSetting"
      
        $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
$URA_Permission = $($currentSetting)
"@
 
        $tmp2 = [System.IO.Path]::GetTempFileName()
      
        Write-Host "Import new settings to Local Security Policy" -ForegroundColor Green
        $outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force
 
        Push-Location (Split-Path $tmp2)
      
        try 
        {
            secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS 
        } 
        finally 
        {   
            Pop-Location
        }
    } 
    else #$currentSetting -notlike "*$($sidstr)*")
    {
        Write-Host "NO ACTIONS REQUIRED! Account already in ""$URA_FriendlyName""" -ForegroundColor Green
    }
 
    Write-Host "Done." -ForegroundColor Green
} #End Function Add_UserRightsAssignment 
 
################################################################################
# MIM MA Service Account
#   Update the advanced User Rights Assignments (Computer Configuration\Windows Settings\Security Settings\Local Policies\User Rights Assignment) 
#   and add the SVC_MIMMA account to the following policies:
#
#   - Allow Allow Logon Locally
################################################################################
Add_UserRightsAssignment "$Domain\$SVC_MIMMA" "SeInteractiveLogonRight" "Allow Logon Locally"
 
#######################################################################################
# MIM Sync Service Account
#   Update the advanced User Rights Assignments (Computer Configuration\Windows Settings\Security Settings\Local Policies\User Rights Assignment) 
#   and add the SVC_MIMSYNC account to the following settings:
#   
#   - Deny logon as a batch job 
#   - Deny logon locally
#   - Deny access to this computer from the network
################################################################################
Add_UserRightsAssignment "$Domain\$SVC_MIMSYNC" "SeDenyBatchLogonRight" "Deny logon as a batch job"
Add_UserRightsAssignment "$Domain\$SVC_MIMSYNC" "SeDenyInteractiveLogonRight" "Deny logon locally" 
Add_UserRightsAssignment "$Domain\$SVC_MIMSYNC" "SeDenyNetworkLogonRight" "Deny access to this computer from the network"
 
################################################################################
# MIM Service Service Account
#   Update the advanced User Rights Assignments (Computer Configuration\Windows Settings\Security Settings\Local Policies\User Rights Assignment) 
#   and add the SVC_MIMSERVICE account to the following policies:
#
#   - Deny logon as a batch job
#   - Deny logon locally
#   - Deny access to this computer from the network
################################################################################
Add_UserRightsAssignment "$Domain\$SVC_MIMSERVICE" "SeDenyBatchLogonRight" "Deny logon as a batch job"
Add_UserRightsAssignment "$Domain\$SVC_MIMSERVICE" "SeDenyInteractiveLogonRight" "Deny logon locally" 
Add_UserRightsAssignment "$Domain\$SVC_MIMSERVICE" "SeDenyNetworkLogonRight" "Deny access to this computer from the network"
 
################################################################################
# MIM Scheduler Service Account
#  Update the advanced User Rights Assignments (Computer Configuration\Windows Settings\Security Settings\Local Policies\User Rights Assignment) 
#   and add the SVC_MIMSCHEDULER account to the following policies:
#  - Allow Log On as a Batch Job
################################################################################
Add_UserRightsAssignment "$Domain\$SVC_MIMSCHEDULER" "SeBatchLogonRight" "Log On as a Batch Job"
