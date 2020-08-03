# services
# Get-WmiObject win32_service | Select * | Export-Csv test.csv

param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$cred_path,
    [string]$out_dir='..\Data\'
 )

$creds = Import-CliXml -Path $cred_path

$sesh = New-PSSession -ComputerName $ip -Credential $creds

$data = Invoke-Command -Session $sesh -ScriptBlock {
    Get-WmiObject win32_service | Select PSComputerName,Name,Status,ExitCode,DesktopInteract,ErrorControl,PathName,ServiceType,StartMode,AcceptPause,AcceptStop,Caption,CheckPoint,CreationClassName,DelayedAutoStart,Description,DisplayName,InstallDate,ProcessId,ServiceSpecificExitCode,Started,StartName,State,SystemCreationClassName,SystemName,Scope,Path,ClassPath
    }

$sesh | Remove-PSSession

$current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString().Replace(".", "")
$filepath = $out_dir+"services_"+$current_time+"_"+$ip+".csv"

$data | Export-Csv $filepath -NoTypeInformation