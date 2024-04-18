$NewAcl = Get-Acl -Path "C:\Pets\Dog.txt"

# Set properties
$Identity = "BUILTIN\Administrators"
$FileSystemRights = "FullControl"
$Type = "Allow"

# Create new rule
$FileSystemAccessRuleArgumentList = $Identity, $FileSystemRights, $Type
$FileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $FileSystemAccessRuleArgumentList

# Apply new rule
$NewAcl.SetAccessRule($FileSystemAccessRule)
Set-Acl -Path "C:\Pets\Dog.txt" -AclObject $NewAcl

