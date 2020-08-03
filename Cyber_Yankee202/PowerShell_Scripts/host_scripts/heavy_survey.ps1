param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$cred_path,
    [Parameter(Mandatory=$true)][string]$out_dir
 )

# see if specified credential file and out directory exist
if((Test-Path $cred_path) -eq $false){
    Write-Host "Specified credential file does not exist." -ForegroundColor Red
    exit
}
if((Test-Path $out_dir) -eq $false){
    Write-Host "Specified out directory does not exist." -ForegroundColor Red
    exit
}

# read the securely stored PSCredentials, if this step fails you may need to run the "secret_snacktime.ps1" script and save your credentials
Try{
    $creds = Import-CliXml -Path $cred_path -ErrorAction Stop
    }
Catch{
    Write-Host "Problem reading credentials, is the file XML?" -ForegroundColor Red
    exit
}

# attempt an invoke-command
Try{
    Invoke-Command -ScriptBlock { hostname } -ComputerName $ip -Credential $creds -ErrorAction Stop
    }
Catch{
    Write-Host "Invoke-Command failed, is the host down?  Are the credentials correct?"
    exit
}

# add any other wmi-objects of interest to this list, the script will collect it, format it as a csv, and save it to the specified out directory
$wmi_objects = "win32_startupcommand","win32_networkloginprofile","win32_systemdriver","win32_mappedlogicaldisk","win32_environment","win32_useraccount","win32_group","win32_computersystem","win32_networkadapterconfiguration","win32_share","win32_logicaldisk","win32_computersystem","win32_quickfixengineering","win32_group","win32_operatingsystem","win32_pointingdevice","win32_service","win32_printerdriver","win32_printer","win32_networkconnection","win32_networkadapter","win32_bios"

# perform survey collecting each of the wmi objects, and formatting as csv
$wmi_objects | %{
    Write-Host $_
    $current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()
    $filepath = $out_dir+$_+"_"+$current_time+"_"+$ip+".csv"
    Invoke-Command -Credential $creds -ScriptBlock { param($obj) Get-WmiObject -Class $obj } -ArgumentList $_ -ComputerName $ip | select * | Export-CSV $filepath -NoTypeInformation
}

# scheduled tasks
$current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()
$filepath = $out_dir+"Scheduled_Tasks_"+$current_time+"_"+$ip+".txt"
'"HostName","TaskName","Next Run Time","Status","Logon Mode","Last Run Time","Last Result","Author","Task To Run","Start In","Comment","Scheduled Task State","Idle Time","Power Management","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Schedule","Schedule Type","Start Time","Start Date","End Date","Days","Months","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running"' | Out-File $filepath
Invoke-Command -Credential $creds -ScriptBlock {schtasks /QUERY /V /FO CSV /NH} -ComputerName $ip | Out-File $filepath -Append

# list of local admins
$current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()
$filepath = $out_dir+"local_admins_"+$current_time+"_"+$ip+".csv"
Invoke-Command -Credential $creds -ScriptBlock { Get-LocalgroupMember Administrators } -ComputerName $ip |select * | Export-CSV $filepath -NoTypeInformation

