<#
    Author: Brandon Dudley 
	brandon.m.dudley.mil@mail.mil
#>

<#
	.SYNOPSIS
	This script collects and merges data related to processes from three sources on a host:
        Get-NetTCPConnection
        Get-WmiObject Win32_Process
        Get-Process

	.PARAMETER ip
	Specify the remote ip to survey (required)
	
	.PARAMETER cred_path
	Specify the path of the credentials to use, these must be XML.  If there are issues here, create
    and save a PSCredential Object to disk.
	
	.PARAMETER out_dir
	Specify the directory to save the file, do not include a file name, the file name is generated based
    on the data collected.

    .DESCRIPTION
    This script quickly connects to a host on a network of interest and collects data about processes.  It
    then saves the data to a local specified directory where one of the sister scripts can perform rudimentary
    local analysis or stream it to Kafka for more robust analysis.

    .LINK
    https://github.com/deptofdefense/jyn2-host-scripts
    https://github.com/deptofdefense/jyn2-infrastructure
	
	.NOTES
	Written by Brandon Dudley for the Jyn2 Spy vs. Spy project
	This script is tested on Windows 10 domains.
	
	.Example
	.\proc_hunter.ps1 -ip 192.168.1.2 -cred_path C:\my_creds.xml -out_dir C:\my_scan_results\
#>



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


# attempt the first pssession, if that does not work end the script
Try{
    $sesh = New-PSSession -ComputerName $ip -Credential $creds -ConfigurationName microsoft.powershell32 -ErrorAction Stop
    }
Catch{
    Write-Host "PSSession failed, is the host down?  Are the credentials correct?"
    exit
}

# collect all of the dlls loaded into the 32 bit processes
$first_survey = Invoke-Command -Session $sesh -ScriptBlock {
    param($ip) $OFS=',';
    $procs = New-Object System.Collections.ArrayList
    $netstat = Get-NetTCPConnection
    $wmi_procs = Get-WmiObject Win32_Process
    Get-Process -IncludeUserName | %{
        Try{
            $mod_names = $_ | Select-Object -ExpandProperty modules -ErrorAction Stop | %{ $_.ModuleName }
            $a = $_.Name
            $b = $_.UserName
            $c = $_.Id
            $d = (Get-Date ($_.StartTime).ToUniversalTime() -UFormat %s).ToString()
            $j = $_.Path
            $ct = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()
            # get the netstat and enrich the host data with ports and IPs
            $e = ""
            $f = ""
            $g = ""
            $h = ""
            $i = ""
            # enrich with wmi data
            $k = ""
            $l = ""
            ForEach($entry in $netstat){
                if($entry.OwningProcess -eq $c){
                    $e = $entry.LocalAddress
                    $f = $entry.LocalPort
                    $g = $entry.RemoteAddress
                    $h = $entry.RemotePort
                    $i = $entry.State
                }
            }
            ForEach($entry in $wmi_procs){
                if($entry.ParentProcessId -eq $c){
                    $k = $entry.ProcessId
                    $l = $entry.CommandLine
                }
            }

            $z = [string]::Join(",",$mod_names)
            $procs.Add("$ip,$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$ct,$k,$l,`"$z`"") > $null
        }Catch{
            # do nothing yet, this will fail with 64 bit processes
        }
      }
      $procs
    } -ArgumentList $ip
$sesh | Remove-PSSession

# collect all of the dlls loaded into the 64 bit processes
$sesh = New-PSSession -ComputerName $ip -Credential $creds
$second_survey = Invoke-Command -Session $sesh -ScriptBlock {
    param($ip) $OFS=',';
    $procs = New-Object System.Collections.ArrayList
    $netstat = Get-NetTCPConnection
    $wmi_procs = Get-WmiObject Win32_Process
    Get-Process -IncludeUserName | %{
        Try{
            $mod_names = $_ | Select-Object -ExpandProperty modules -ErrorAction Stop | %{ $_.ModuleName }
            $a = $_.Name
            $b = $_.UserName
            $c = $_.Id
            $d = (Get-Date ($_.StartTime).ToUniversalTime() -UFormat %s).ToString()
            $j = $_.Path
            $ct = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()

            # get the netstat and enrich the host data with ports and IPs
            $e = ""
            $f = ""
            $g = ""
            $h = ""
            $i = ""
            # enrich with wmi data
            $k = ""
            $l = ""
            ForEach($entry in $netstat){
                if($entry.OwningProcess -eq $c){
                    $e = $entry.LocalAddress
                    $f = $entry.LocalPort
                    $g = $entry.RemoteAddress
                    $h = $entry.RemotePort
                    $i = $entry.State
                }
            }
            ForEach($entry in $wmi_procs){
                if($entry.ProcessId -eq $c){
                    $k = $entry.ParentProcessId
                    $l = $entry.CommandLine
                }
            }
            $z = [string]::Join(",",$mod_names)
            $procs.Add("$ip,$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$ct,$k,$l,`"$z`"") > $null
        }Catch{
            # do nothing yet
        }
      }
      $procs    
    } -ArgumentList $ip
$sesh | Remove-PSSession

# generate filename
$current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()
$filepath = $out_dir+"process_"+$current_time+"_"+$ip+".txt"

"host,processName,privilege,pid,startTime,localIp,localPort,remoteIp,remotePort,state,path,collectTime,parentProcessId,commandLine,modules" | Out-File $filepath -Append
$first_survey | Out-File $filepath -Append
$second_survey | Out-File $filepath -Append