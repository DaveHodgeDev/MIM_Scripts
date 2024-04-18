CLS

# Declare DN to 
$MA = "AD MA"
$DN = "CN=GroupA,DC=CONTOSSO,DC=COM"
$g = Get-CSObject -ma $MA -DN $dn

Write-Host "Total Members: $($g.SynchronizedHologram.DNAttributes.member.values.Count)"
Write-Host "Modified Members: $($g.UnappliedExportDelta.DNAttributes.member.values.Count)"

$holo = $g.SynchronizedHologram.DNAttributes.member.values
$members = $g.UnappliedExportDelta.DNAttributes.member.Values

########################################################
#if True - remove
#If False - add
########################################################
foreach($member in $members)
{
    if($($holo.DN) -contains $($member.DN))
    {
        if ($($member.DN.Contains("CN=Deleted Objects,")))
        {
        }
        else
        {
            $strLine = "Remove`t$($DN)`t$($member.DN)" 
            Out-File -FilePath "D:\Code\GroupMembers.txt" -InputObject $strLine -Encoding UTF8 -append 
        }
    }
    else
    {
        $strLine = "Add`t$($DN)`t$($member.DN)" #-ForegroundColor Red
        Out-File -FilePath "D:\Code\GroupMembers.txt" -InputObject $strLine -Encoding UTF8 -append 
    }
}

Notepad "D:\Code\GroupMembers.txt"
