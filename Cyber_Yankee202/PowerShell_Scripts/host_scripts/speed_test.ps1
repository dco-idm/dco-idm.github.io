param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$cred_path,
    [Parameter(Mandatory=$true)][int]$count
 )

$script_start = Get-Date
$num = 0
While($num -lt $count){
    $start = Get-Date
    .\proc_hunter.ps1 -ip $ip -cred_path $cred_path -out_dir ..\Data\
    $total = (Get-Date) - $start
    Write-Host "Completed survey in " -NoNewline
    Write-Host $total.TotalSeconds -NoNewline -ForegroundColor Green
    Write-Host " seconds."
    $num+=1
}
$script_total_time = (Get-Date) - $script_start

Write-Host "`nStats for $count iterations:" -ForegroundColor Yellow

$script_total_time | Select *