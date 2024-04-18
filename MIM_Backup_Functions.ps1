#####################################################################################
# Written by: Dave Hodge, MCS
# Purpose: 
#####################################################################################



#######################################
# Variables
#######################################
$Backup_Location = "C:\Code"
$FIMSYNC_InstallDir = "C:\Program Files\Microsoft Forefront Identity Manager\2010"

$MIM_Environment = "Source"

$Domain = "CONTOSO"
$SVC_FIMSYNC = "SVC_MIMSYNC"
$PWD = ""


Function Create_Folder
{ Param([string]$Path)

    if((test-path "$Path") -eq $false)
    {
        write-host "Create Folder: $Path"
        mkdir $Path | out-null 
    } 
}

Function ZipFolder
{ PARAM([string]$strPath)

    #######################################
    #Get the Date for Stamping the files...
    #######################################
    $a = Get-Date -format d
    $a = $a.Replace("/","_")

    #######################################
    #Remove the UNC Formatting....
    #######################################
    if ($($strPath.subString(0,2)) -eq "\\")
    {
        $strFile = $strPath.ToUpper().Substring(2,$strPath.Length -2)
    }
    else
    {
        $strFile = $strPath.ToUpper().Replace("C:\","C_")
    }
    
    $strFile = "$strFile" + "_" + "$a" 
    $strFile = "$strFile.zip"
    $strFile = $strFile.Replace("\","_")
    #write-host "$strfile"

    Compress-Archive -Path "$strPath" -DestinationPath "$Backup_Location\$strFile" -CompressionLevel Optimal -Force
}

Function Export_MIM_Configuration
{
    Param([string]$Environment,[string]$Type, [string[]]$params)

    # ExportSchema.ps1
    # Copyright © 2009 Microsoft Corporation

    # The purpose of this script is to export the current schema configuration
    # in the pilot environment.

    # The script stores the configuration into file "schema.xml" in the current directory.
    # Please note you will need to rename the file to pilot_schema.xml or production_schema.xml.
    # See the documentation for more information.

    # Dave Hodge - Modified from original example to provide remoting capabilities & current folder capabilities

    if(@(get-pssnapin | where-object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {add-pssnapin FIMAutomation}

    #$curDir = (get-location).path
    $filename = "$($Backup_Location)\MIM_SERVICE_CONFIG\$($Environment)_$($type).xml"

    write-host ""
    write-host "############################################" -foregroundcolor green
    Write-Host "Exporting $Type objects from $Environment..." -foregroundcolor green
    write-host "############################################" -foregroundcolor green
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""

    $ProgressPreference = "SilentlyContinue"
    $strCommand = "Export-FIMConfig $params"
    $objects = invoke-expression "$strCommand"

    $ProgressPreference = "Continue"

    if ($objects -eq $null)
    {
        Write-Host "Export did not successfully retrieve configuration from FIM.  Please review any error messages and ensure that the arguments to Export-FIMConfig are correct."
    }
    else
    {
        $objects | ConvertFrom-FIMResource -file $filename
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host "Exported " $objects.Count " objects from $Environment"
        Write-Host "File is saved as: " $filename

        if($objects.Count -gt 0)
        {
            Write-Host "Export complete."
            Write-Host ""
            Write-Host "Note: The percentage exported may remain on the screen at less than 100%, but the export is complete...." -Foregroundcolor Red
        }
        else
        {
            Write-Host "While export completed, there were no resources.  Please ensure that the arguments to Export-FIMConfig are correct." 
        }
    }
}

Function Export_Schema
{ 
    $ArgumentList = New-Object System.Collections.ArrayList
    [void]$ArgumentList.Add("-schemaConfig")
    [void]$ArgumentList.Add("-customConfig ""/SynchronizationFilter""")
    [void]$ArgumentList.Add("-uri http://localhost:5725")

    Export_MIM_Configuration $MIM_Environment "Schema" "$ArgumentList"
}

Function Export_Config
{
    $ArgumentList = New-Object System.Collections.ArrayList
    [void]$ArgumentList.Add("-portalConfig")
    [void]$ArgumentList.Add("-MessageSize 9999999")
    [void]$ArgumentList.Add("-uri http://localhost:5725")

    Export_MIM_Configuration $MIM_Environment "Config" "$ArgumentList"
}

Function Export_Policy
{
    $ArgumentList = New-Object System.Collections.ArrayList
    [void]$ArgumentList.Add("-policyConfig")
    [void]$ArgumentList.Add("-MessageSize 9999999")
    [void]$ArgumentList.Add("-uri http://localhost:5725")

    Export_MIM_Configuration $MIM_Environment "Policy" "$ArgumentList"
}

#########################################################
# Get Current Directory
#########################################################
$dir = (get-location).path

#######################################
# Cleanup previous runs...
#######################################
if((test-path "$Backup_Location") -eq $false)
{
    write-host "Remove old runs"
    Remove-Item -Path "$Backup_Location" -Recurse -Force | out-null 
} 

#######################################
# Create folder locations
#######################################
Create_Folder "$Backup_Location"
Create_Folder "$Backup_Location\MIM_SERVICE_CONFIG"
Create_Folder "$Backup_Location\MIM_SYNC_CONFIG"
Create_Folder "$Backup_Location\MIM_SYNC_DB_KEY"
Create_Folder "$Backup_Location\MIM_SYNC_TASK_SCHEDULER"

Start-sleep -milliseconds 1000

#######################################
# Back Script files
#######################################
#ZipFolder \\SERVER01\c$\code\scripts
#ZipFolder "C:\code\MIM Foundation - Resources"


#########################################################
# Switch to the Sync Engine Bin Folder
#########################################################
c:
cd "$FIMSYNC_InstallDir\Synchronization Service\Bin"

#########################################################
#Export Encryption Key
#https://technet.microsoft.com/en-us/library/jj590361(v=ws.10).aspx
#########################################################
Write-host "###############################################" -foregroundcolor green
Write-host "# Exporting MIM Sync Encryption Key............" -foregroundcolor green
Write-host "###############################################" -foregroundcolor green

###################################################################
# Get Password for service account...
###################################################################
$PWD = Read-Host -Prompt "Enter the password for $SVC_FIMSYNC account"
.\miiskmu.exe /e "$Backup_Location\MIM_SYNC_DB_KEY\MIM_SYNC_ENCRYPTION_KEY.bin" /u:"$($Domain)\$($SVC_FIMSYNC)" "$PWD" /q

Write-host "###############################################" -foregroundcolor green
Write-host "# Creating zip file for MIM Sync Encryption Key" -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
ZipFolder "$Backup_Location\MIM_SYNC_DB_KEY"

#########################################################
# Export MIM Sync Config
#########################################################
Write-host "###############################################" -foregroundcolor green
Write-host "# Exporting for MIM Sync Config................" -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
.\svrexport "$Backup_Location\MIM_SYNC_CONFIG"
sleep 1

Write-host "###############################################" -foregroundcolor green
Write-host "# Creating zip file for MIM Sync Config Files.." -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
ZipFolder "$Backup_Location\MIM_SYNC_CONFIG"

cd "D:\MIM\Config Backup"

#########################################################
# Export MIM Sync Source Code
#########################################################
Write-host "###############################################" -foregroundcolor green
Write-host "# Creating zip file for MIM SourceCode folder.." -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
ZipFolder "$FIMSYNC_InstallDir\Synchronization Service\SourceCode"

#########################################################
# Export MIM Sync Compiled Binaries
#########################################################
Write-host "###############################################" -foregroundcolor green
Write-host "# Creating zip file for MIM Compiled Binaries.." -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
ZipFolder "$FIMSYNC_InstallDir\Synchronization Service\Extensions"

#######################################
# Export MIM Service Configuration files
#######################################
Write-host "###############################################" -foregroundcolor green
Write-host "# Exporting MIM Service configuration.........." -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
Export_Schema
Export_Config
Export_Policy

Write-host "###############################################" -foregroundcolor green
Write-host "# Creating zip file for MIM Service files......" -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
ZipFolder "$Backup_Location\MIM_SERVICE_CONFIG"

Write-host "###############################################" -foregroundcolor green
Write-host "# Exporting Scheduled Task......" -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
Export-ScheduledTask -taskname "synchronization jobs" -taskpath "\" | Out-File -FilePath "D:\MIM\Config Backup\MIM_SYNC_TASK_SCHEDULER\Synchronization Jobs.Xml"

Write-host "###############################################" -foregroundcolor green
Write-host "# Creating zip file for Scheduled Task......" -foregroundcolor green
Write-host "###############################################" -foregroundcolor green
ZipFolder "$Backup_Location\MIM_SYNC_TASK_SCHEDULER"

Exit


#######################################
# FIM Sync Jobs
#     - Scripts
#     - Export of Scheduled Task
#######################################
#export-scheduledtask
#    #schtasks /Query /XML /TN "Test Task" > "$Backup_Location\Sync_SyncJobs_Tasks\Task.xml"
#    #schtasks /Query /XML /TN "Test Task" > "$Backup_Location\Sync_SyncJobs_Tasks\Task2.xml"
#    "Get-ChildItem D:\Scripts\Sync\Sync_Jobs | ""$Backup_Location\Sync_SyncJobs_$a.zip"""
