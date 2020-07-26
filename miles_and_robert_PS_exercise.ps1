#Top10 will get all the items in the path requested, sort them by the most recent access time as recorded by Windows, and then select the 10 most recent items. 
#Hard coded to my documents folder because I have Sharepoint mapped to my profile.
Write-Output "Most recent (10) accessed items."
$Top10 = Get-ChildItem -File -Recurse C:\users\robert\Documents | Sort-OBject LastAccessTime -Descending | Select-Object -First 10
$count = 1
ForEach ($obj in $Top10)
{
    Write-Output "$count : "
    $obj | fl Name,LastAccessTime
    $count++
}

#Loop to go through each object and print their NTFS permissions.
Write-Output "Next we will retrieve NTFS permissions"
Pause
cls
Write-Output "NTFS permissions for those (10) items."
$count = 1
ForEach ($obj in $Top10)
{
    write-output "$count : $obj.name"
    $obj.directory.GetAccessControl() | fl
    $count++
}

#Outputs first 5 values of any System log values with id of 1074 (system restart)
Get-WinEvent -FilterHashTable @{logname='System'; id=1074} | Select-Object -First 5

#Writes the start up items from registry for the system and the specific user to the output.
Write-output "Next we will retrieve start up keys from the registry."
Pause
cls
Write-output "`nSystem wide start up programs"
Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | fl
Write-output "User specific start up programs"
Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run | fl

#Displays some system security info
Write-output "Next we will retrieve some security items for this machine."
Pause
cls
Write-output "Sending firewall rules and Windows Defender Settings to %USERPROFILE%\Enabled_Inbound_Rules.txt, %USERPROFILE%\Firewall_Rules_W_Ports.txt & %USERPROFILE%\WinDefSettings"

#Outputs Windows Defender settings. Calls twice to display to output and then to file. 
Write-Output "Windows Defender Settings"
Get-MpPreference
Get-MpPreference > WinDefSettings.txt

#Outputs the enabled inbound rules of your Windows Firewall to %USERPROFILE%\Enabled_Inbound_Rules.txt
Get-NetFirewallRule | Where { $_.Enabled –eq ‘True’ –and $_.Direction –eq ‘Inbound’ } > Enabled_Inbound_Rules.txt
#Outputs the active firewall rules with associated IPs (if applicable) and Ports. This takes a considerable amount of time. 
Show-NetFirewallRule -PolicyStore ActiveStore | fl > Firewall_Rules_W_Ports.txt