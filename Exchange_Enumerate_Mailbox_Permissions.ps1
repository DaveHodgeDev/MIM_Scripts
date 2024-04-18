################################################################################################################################################################ 
# Original Script: https://gallery.technet.microsoft.com/scriptcenter/Export-mailbox-permissions-d12a1d28
# Author:                 Alan Byrne 
# Version:                1.0.1 
# Last Modified Date:     8/17/2020 
# Last Modified By:       Dave Hodge 
#  
# Script Prerequisites:
# 1. Run PowerShell as an Administrator 
# 2. Ensure administrator has the Exchange Recipient Admin role assigned
# 3. Ensure that the ExchangeOnlineManagement Module is installed. Use the following cmdlet to install it if needed
#    Install-Module -Name ExchangeOnlineManagement -RequiredVersion 1.0.1
#
# To run the script: 
# .\Get-AllSharedMailboxPermissions.ps1 
# 
# NOTE: The script will return the permissions of ALL Shared mailboxes in the tenant 
################################################################################################################################################################ 
 
$ErrorActionPreference = "SilentlyContinue" 
 
#Constant Variables 
$OutputFile = "MailboxPerms.csv"   #The CSV Output file that is created, change for your purposes 
 
#Main 
Function Main { 
 
    #Remove all existing PowerShell sessions 
    Get-PSSession | Remove-PSSession 
     
    #Connect To ExchangeOnline 
    $UserCredential = Get-Credential()
    # Replaced with the V2 connect method
    #$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
    Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true
 
    #Prepare Output file with headers 
    Out-File -FilePath $OutputFile -InputObject "UserPrincipalName,ObjectWithAccess,ObjectType,AccessType,Inherited,AllowOrDeny" -Encoding UTF8 
     
    ###########################################################
    # DH 8-14-2020 Replaced $objUsers with a query that returns shared mailboxes
    # $objUsers = get-mailbox -ResultSize Unlimited | select UserPrincipalName 
    ###########################################################
    $objUsers = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited | select UserPrincipalName
    $x = 0
     
    #Iterate through all users     
    Foreach ($objUser in $objUsers) 
    {     
        $x = $x + 1
        #Prepare UserPrincipalName variable 
        $strUserPrincipalName = $objUser.UserPrincipalName 
 
        write-host "#############################################################################"
        write-host "$strUserPrincipalName ($x of $($objUsers.Count))"
        write-host "#############################################################################"
        
        # Connect to the users mailbox
        # DH - replaced with new get-exomailboxpermission 
        # $objUserMailbox = get-mailboxpermission -Identity $($objUser.UserPrincipalName) | Select User,AccessRights,Deny,IsInherited 
        $objUserMailbox = get-exomailboxpermission -Identity $strUserPrincipalName | Select User,AccessRights,Deny,IsInherited 
         
         
        #Loop through each permission 
        foreach ($objPermission in $objUserMailbox) 
        {             
            #Get the remaining permission details (We're only interested in real users, not built in system accounts/groups) 
            if (($objPermission.user.tolower().contains("\domain admin")) -or ($objPermission.user.tolower().contains("\enterprise admin")) -or ($objPermission.user.tolower().contains("\organization management")) -or ($objPermission.user.tolower().contains("\administrator")) -or ($objPermission.user.tolower().contains("\exchange servers")) -or ($objPermission.user.tolower().contains("\public folder management")) -or ($objPermission.user.tolower().contains("nt authority")) -or ($objPermission.user.tolower().contains("\exchange trusted subsystem")) -or ($objPermission.user.tolower().contains("\discovery management")) -or ($objPermission.user.tolower().contains("s-1-5-21")) -or ($objPermission.user.tolower().contains("jitusers")) -or ($objPermission.user.tolower().contains("managed availability servers"))) 
            {} 
            Else  
            { 
                $objRecipient = (get-recipient $($objPermission.user)  -EA SilentlyContinue)  
                 
                if ($objRecipient) 
                { 
                    $strUserWithAccess = $($objRecipient.DisplayName) + " (" + $($objRecipient.PrimarySMTPAddress) + ")" 
                    $strObjectType = $objRecipient.RecipientType 
                } 
                else 
                { 
                    $strUserWithAccess = $($objPermission.user) 
                    $strObjectType = "Other" 
                } 
                 
                $strAccessType = $($objPermission.AccessRights) -replace ",",";" 
                 
                if ($objPermission.Deny -eq $true) 
                { 
                    $strAllowOrDeny = "Deny" 
                } 
                else 
                { 
                    $strAllowOrDeny = "Allow" 
                } 
                 
                $strInherited = $objPermission.IsInherited 
                                 
                #Prepare the user details in CSV format for writing to file 
                $strUserDetails = "$strUserPrincipalName,$strUserWithAccess,$strObjectType,$strAccessType,$strInherited,$strAllowOrDeny" 
                 
                Write-Host $strUserDetails 
                 
                #Append the data to file 
                Out-File -FilePath $OutputFile -InputObject $strUserDetails -Encoding UTF8 -append 
            } 
        } 
    } 
} 
 
# Start script 
. Main
& Notepad $outputfile
 
