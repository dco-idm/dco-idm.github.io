# file retriver script
param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$cred_path,
    [Parameter(Mandatory=$true)][string]$file_name,
    [string]$id
 )

 
# get the saved credentials specified in arguments
$creds = Import-CliXml -Path $cred_path

Try{
    #ping the host, if it is down, don't scan it
    $sesh = New-PSSession -ComputerName $ip -Credential $creds -ErrorAction Stop
    }
Catch{
    # write to file that host is unresponsive to ping
    $d = Get-Date -Format "yyyy-MM-dd HH:mm:SS"
    "[$d] $ip credentials failed or WIN RM is disabled." | Out-File ..\activity_log.txt -Append
    exit
}

Write-Host "Retrieving $file_name on $ip..."

# find the file of interest
# $files = Invoke-Command -Session $sesh -ScriptBlock {param ($fn); cd C:\; Get-ChildItem -File -Recurse | ? Name -Like "$fn" } -ArgumentList $file_name

# $loc = (Get-Location).Path
# $count = ($files | Measure-Object).Count

# Write-Host "Found $count matching files." -ForegroundColor Green

$file_name | %{
    $new_fn = "$ip"+"_"+$_.Replace("\", "_").Replace(":", "")
    Write-Host "Copying file from remote location: " -NoNewline -ForegroundColor Yellow
    Write-Host $_.FullName -ForegroundColor Yellow
    Copy-Item -FromSession $sesh -Path $_ -Destination ..\Files\$new_fn
    if($id.Length -gt 2){
        Compress-Archive ..\Files\$new_fn -DestinationPath ..\Files\$id
    }
}

$sesh | Remove-PSSession