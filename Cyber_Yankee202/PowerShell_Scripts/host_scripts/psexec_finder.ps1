param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$cred_path,
    [string]$out_dir='..\Data\'
 )

$creds = Import-CliXml -Path $cred_path

$sesh = New-PSSession -ComputerName $ip -Credential $creds

$data = Invoke-Command -Session $sesh -ScriptBlock {
    Get-EventLog Security | ? -Property Message -Like "*PSEXESVC*" | %{ "-----------------------------------------------------------------"; $_.TimeGenerated; $_.Message }
    }

$sesh | Remove-PSSession

$current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString().Replace(".", "")
$filepath = $out_dir+"psexec_"+$current_time+"_"+$ip+".txt"

$data | Out-File $filepath