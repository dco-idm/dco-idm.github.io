# services
# Get-WmiObject win32_service | Select * | Export-Csv test.csv

param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$cred_path,
    [string]$out_dir='..\Data\'
 )

# add comma-separated event_ids to this list if you want to collect them with PowerShell
$event_ids = 1102,4719,4618,4649,4765,4766,4794,4897,4964,5124,4706,4713,4724

$creds = Import-CliXml -Path $cred_path

$sesh = New-PSSession -ComputerName $ip -Credential $creds

ForEach($event_id in $event_ids){
    $data = Invoke-Command -Session $sesh -ScriptBlock {
        param($eid)
        Get-EventLog Security | ? EventID -EQ $eid | %{ $_ }
        } -ArgumentList $event_id
    $current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()
    $filepath = $out_dir+$event_id+"_"+$current_time+"_"+$ip+".csv"
    $data | select * | Export-CSV $filepath -NoTypeInformation
}

$sesh | Remove-PSSession

