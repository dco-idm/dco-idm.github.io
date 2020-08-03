# runs one big scan with all host scripts on file specified
param (
    [Parameter(Mandatory=$true)][string]$cred_path,
    [Parameter(Mandatory=$true)][string]$out_dir,
    [Parameter(Mandatory=$true)][string]$host_file
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

# read the host file, prompt user for verification
$computers = Get-Content $host_file
$computer_count = ($computers | Measure-Object).Count
$input = 'y'
#$input = Read-Host -Prompt "This script is about to scan $computer_count computers, do you want to continue? (y/n)"
if($input -notlike "y" -and $input -notlike "Y"){
    Write-Host "Canceling..." -ForegroundColor Yellow
    exit
}

Write-Host "Beginning network scan..." -ForegroundColor Green

$current_location = (Get-Location).Path

$counter = 0
ForEach($computer in $computers){
    $counter+=1
    $scriptBlock = {
        param ($ip,$out,$cred,$cl)
        cd $cl
        Function Write-Log($message){
            $log_again = $true
            $scan_time = (Get-Date).ToString()
            $log_path = $out+"scan_log.txt"
            While($log_again){
                Try{
                    $log_again = $false
                    $message+" "+$scan_time | Out-file $log_path -Append -ErrorAction Stop
                }Catch{
                    $log_again = $true
                }
            }
        }
        # test to see if the host is up, and make sure it is not linux (ping TTL above 64)
        $ping_response = ping -w 1000 -n 1 $ip 
        $is_windows = [int]($ping_response | select-string "TTL" | % { $_.toString().split("=")[3]}) -gt 64 
        if(($ping_response  -like "*TTL*").Count -gt 0 -and $is_windows){

            Write-Log("[$ip]: SCAN BEGIN at")
            $start = Get-Date
            Write-Log("[$ip]: Proc Hunter started at")
            .\proc_hunter.ps1 -ip $ip -out_dir $out -cred_path $cred
            Write-Log("[$ip]: Proc Hunter finished at")
            Write-Log("[$ip]: Event Log Checker started at")
            .\event_log_checker.ps1 -ip $ip -out_dir $out -cred_path $cred
            Write-Log("[$ip]: Event Log Checker finished at")
            Write-Log("[$ip]: Service Hunter started at")
            .\service_hunter.ps1 -ip $ip -cred_path $cred -out_dir $out
            Write-Log("[$ip]: Service Hunter finished at")
            Write-Log("[$ip]: PSExec Finder started at")
            .\psexec_finder.ps1 -ip $ip -cred_path $cred -out_dir $out
            Write-Log("[$ip]: PSExec Finder finished at")
            Write-Log("[$ip]: Heavy Survey started at")
            .\heavy_survey.ps1 -ip $ip -cred_path $cred -out_dir $out
            Write-Log("[$ip]: Heavy Survey finished at")
            Write-Log("[$ip]: ADS Search started at")
            .\dupeDevil.ps1 -ip $ip -cred_path $cred -out_dir $out
            Write-Log("[$ip]: ADS Search finished at")
            Write-Log("[$ip]: Directory Hasher started at")
            .\directory_hasher.ps1 -ip $ip -cred_path $cred -out_dir $out
            Write-Log("[$ip]: Directory Hasher finished at")
            Write-Log("[$ip]: Crash Dump Finder started at")
            .\watson.ps1 -ComputerName $ip -CredentialPath $cred
            Write-Log("[$ip]: Crash Dump Finder finished at")
            $end = Get-Date
            $elapsed = $end - $start
            $hours = $elapsed.Hours
            $minutes = $elapsed.Minutes
            $seconds = $elapsed.Seconds
            Write-Log("[$ip]: SCAN COMPLETE in $hours`:$minutes`:$seconds at")
        }
        else{
            Write-Log("[$ip]: HOST UNRESPONSIVE at")
        }
    }
    Start-Job -ScriptBlock $scriptBlock -ArgumentList $computer,$out_dir,$cred_path,$current_location > $null
    Write-Host "Started process for $computer"
        
    $proc_count = (Get-Process | Where-Object -Property Name -Like "*powershell*" ).Count
    If($proc_count -gt 200){
        Write-Host "Waiting for additional resources to become available..." -ForegroundColor Yellow
        Write-Host "Completed $counter of $computer_count"
    }
    While($proc_count -gt 200){
        # see how many powershell processes are still running
        $proc_count = (Get-Process | Where-Object  -Property Name -Like "*powershell*" ).Count
        # Remove any completed jobs
        Get-Job | Where-Object -Property State -eq "Completed" | %{ Remove-Job $_.Id }
        Get-Job | Where-Object -Property State -eq "Failed" | %{ Remove-Job $_.Id }
        sleep 5
    }
}
Get-Job | Where-Object -Property State -eq "Completed" | %{ Remove-Job $_.Id }
Get-Job | Where-Object -Property State -eq "Failed" | %{ Remove-Job $_.Id }
$num_jobs = (Get-Job | Measure-Object).Count
Write-Host "Scripts scheduled on all hosts, $num_jobs jobs still running." -ForegroundColor Green
