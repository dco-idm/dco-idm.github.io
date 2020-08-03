<#
    Author: Brandon Dudley 
	brandon.m.dudley.mil@mail.mil
#>

<#
	.SYNOPSIS
	This script schedules and manages the running of the host collection script

	.PARAMETER ip
	Specify the remote ip to survey (required)
	
	.PARAMETER cred_path
	Specify the path of the credentials to use, these must be XML.  If there are issues here, create
    and save a PSCredential Object to disk.
	
	.PARAMETER out_dir
	Specify the directory to save the file, do not include a file name, the file name is generated based
    on the data collected.

    .PARAMETER host_list
	Specify the text file with one host per line to scan.

    .DESCRIPTION
    This script quickly connects to a host on a network of interest and collects data about processes.  It
    then saves the data to a local specified directory where one of the sister scripts can perform rudimentary
    local analysis or stream it to Kafka for more robust analysis.  This script requires a host list with one
    host per line.

    .LINK
    https://github.com/deptofdefense/jyn2-host-scripts
    https://github.com/deptofdefense/jyn2-infrastructure
	
	.NOTES
	Written by Brandon Dudley for the Jyn2 Spy vs. Spy project
	This script is tested on Windows 10 domains.
	
	.Example
	.\orchestrator.ps1 -cred_path .\my_creds.xml -out_dir ..\Data\ -host_list .\target_ips.txt

#>



param (
    [Parameter(Mandatory=$true)][string]$cred_path,
    [Parameter(Mandatory=$true)][string]$out_dir,
    [Parameter(Mandatory=$true)][string]$host_list,
    [Parameter(Mandatory=$true)][string]$sleep_seconds
)

$current_location = (Get-Location).Path

while(1){
    # check for any updates in the host list
    $computers = Get-Content $host_list
    $counter = 0
    ForEach($computer in $computers){
        $counter+=1
        $scriptBlock = {
            param ($ip,$out,$cred,$cl)
            cd $cl
            .\proc_hunter.ps1 -ip $ip -out_dir $out -cred_path $cred
        }
        Start-Job -ScriptBlock $scriptBlock -ArgumentList $computer,$out_dir,$cred_path,$current_location > $null
        Write-Host "Started process for $computer"
        
        $proc_count = (Get-Process | Where-Object -Property Name -Like "*powershell*" ).Count
        If($proc_count -gt 300){
            Write-Host "Waiting for additional resources to become available..." -ForegroundColor Yellow
        }
        While($proc_count -gt 300){
            # see how many powershell processes are still running
            $proc_count = (Get-Process | Where-Object  -Property Name -Like "*powershell*" ).Count
            # Remove any completed jobs
            Get-Job | Where-Object -Property State -eq "Completed" | %{ Remove-Job $_.Id }
            Get-Job | Where-Object -Property State -eq "Failed" | %{ Remove-Job $_.Id }
            sleep 10
        }
    }
    Write-Host "Script complete on all hosts, starting new." -ForegroundColor Green
    Get-Job | Where-Object -Property State -eq "Completed" | %{ Remove-Job $_.Id }
    Get-Job | Where-Object -Property State -eq "Failed" | %{ Remove-Job $_.Id }

    sleep $sleep_seconds
}
