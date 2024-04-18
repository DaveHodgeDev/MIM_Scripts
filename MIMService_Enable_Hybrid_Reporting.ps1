###############################################################################
# Step 1. Get the path to the MIM Service configuration file.
###############################################################################
$ImagePath = Get-ItemPropertyValue -Path HKLM:\System\CurrentControlSet\Services\FIMService -Name ImagePath
$ImagePath = $imagepath.replace("""","") + ".config"


###############################################################################
# Step 2. Get the FIMService config file.
###############################################################################
$Config = [xml] (Get-Content $imagepath)

###############################################################################
# Step 3. Set hybridReportingRequestLoggingEnabled="true"
###############################################################################
If ($Config.configuration.resourceManagementService.hybridReportingRequestLoggingEnabled -ne $true)
{
    $hybridReportingRequestLoggingEnabled = $Config.configuration.resourceManagementService.OwnerDocument.CreateAttribute("hybridReportingRequestLoggingEnabled")
    $hybridReportingRequestLoggingEnabled.Value = "true"
    $void = $Config.configuration.resourceManagementService.Attributes.Append($hybridReportingRequestLoggingEnabled)
    $Config.Save($ImagePath)
}
Else
{
    write-host "Hybrid reporting request logging is already enabled" -ForegroundColor Green
}

###############################################################################
# Step 4. Create the EventLog to store the MIM Request Events in.
###############################################################################
If ([System.Diagnostics.EventLog]::Exists('Identity Manager Request Log') -ne $true)
{
    New-EventLog -LogName "Identity Manager Request Log" -Source "Microsoft.IdentityManagement.Service"
}
Else
{
    Write-Host "Event log already exists!" -ForegroundColor Green
}

###############################################################################
# Step 5. Restart FIMService service
###############################################################################
Restart-Service FIMService 

Notepad 'C:\Program Files\Microsoft Forefront Identity Manager\2010\Service\Microsoft.ResourceManagement.Service.exe.config'
