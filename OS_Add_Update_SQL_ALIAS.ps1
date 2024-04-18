####################################################################################
# Written By:Dave Hodge, MCS
# Purpose: Create new SQL Alias or update existing SQL Alias entries based on logged 
# in domain
####################################################################################

Function UpdateAlias
{
    Param([string]$Key,[string]$Value,[string]$Description)

    write-host "******************************************************"
    write-host "SQL Alias Function"
    write-host "Key: $Key"
    write-host "Value: $Value"
    write-host "Description: $Description"
    
      $Path = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo"
      
      if(-NOT (Test-Path $Path)) 
      {
          New-Item $Path
      }
      
      if(-NOT (Get-ItemProperty -Path $Path -Name "$Key")) 
      {   
        WRITE-HOST "------------------------------------------------------------"
        WRITE-HOST "Creating entry..."
        New-ItemProperty -Path $Path -Name $Key -PropertyType String -Value "DBMSSOCN,$Value,15001"
      }
      ELSE
      {
          WRITE-HOST "------------------------------------------------------------"
          $oldValue = Get-ItemProperty -Path "$Path" -Name $Key 

          if($($oldvalue.$Key).Tostring().toUpper() -ne ("DBMSSOCN,$Value,15001").Tostring().toUpper())
          {
              WRITE-HOST "Updating entry..."
              write-host "Changing $Key from '$($oldvalue.$Key)' to 'DBMSSOCN,$Value,1433'" -ForegroundColor Green
              Set-ItemProperty -Path "$Path" -Name "$Key" -Value "DBMSSOCN,$Value,1433"
          }
          else
          {
              WRITE-HOST "Entries match, no changes made..." -ForegroundColor Red
          }
      }
} 
