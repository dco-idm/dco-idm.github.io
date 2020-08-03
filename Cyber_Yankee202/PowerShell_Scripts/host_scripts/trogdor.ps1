param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$cred_path
 )

$procdump_file = [io.file]::ReadAllBytes((gci | ? -Property Name -Like "*procdump.exe*").FullName)

$creds = Import-CliXml -Path $cred_path

$sesh = New-PSSession -ComputerName $ip -Credential $creds

$collect = $true

# dump all relevant processes
Invoke-Command -Session $sesh -ScriptBlock {
    # get the arguments from local machine
    param($procdump_file,$ip) $OFS=',';

    # see the number of processes found
    $procs = Get-Process
    
    if(($procs | Measure-Object).Count -gt 0){
        $num = ($procs | Measure-Object).Count
        Write-Host "Found $num processes, attempting to dump memory..." -ForegroundColor Yellow
        # move to the correct directory
        cd ~
        mkdir jyn_dump
        cd jyn_dump
        $my_dir = (Get-Location).Path

        # write the files to disk
        $prd_name = $my_dir+"\procdump.exe"
        [io.file]::WriteAllBytes($prd_name,$procdump_file)

        # dump each process
        Get-CimInstance Win32_Process | ? ParentProcessID -NotLike $pid | ? ProcessId -NotLike $pid | %{
            Try{
                if($_.Name -notlike "*System Idle Process*"){
                    .\procdump.exe -accepteula $_.ProcessId -ma -accepteula -nobanner
                    Write-Host "Finished dump"$_.Name -ForegroundColor Yellow
                    Write-Host "----------------------------------------------------------------------------------"
                    }
            }Catch{
                Write-Host "Could not dump "$_.Name -ForegroundColor Red
            }
        }

        # prepend files with ip address
        gci -Filter *.dmp | %{
            $new_name = $ip+"_"+$_.Name
            Rename-Item $_.Name $new_name
        }

        # clean up executables
        Remove-Item -Path $prd_name

        Write-Host "Dump complete, transferring files..." -ForegroundColor Green
    }

} -ArgumentList $procdump_file,$ip

$collect = Invoke-Command -Session $sesh -ScriptBlock { cd ~; Test-Path jyn_dump }
# find and transfer the files back
if($collect){
    $files_to_transfer = Invoke-Command -Session $sesh -ScriptBlock { cd ~; cd jyn_dump; gci }
    $total_files = ($files_to_transfer | Measure-Object).Count
    $counter = 1
    $files_to_transfer | %{
        $megabytes = ((($_.Length)/1024)/1024)
        Write-Host "$counter of $total_files, $megabytes megabytes"
        Copy-Item -FromSession $sesh -Path $_.FullName -Destination ..\Dumps\$_
        $counter+=1
        }

    # remove the folder on the remote system
    Invoke-Command -Session $sesh -ScriptBlock { cd ~; Remove-Item -Recurse jyn_dump }
    }

# tear down the session
$sesh | Remove-PSSession