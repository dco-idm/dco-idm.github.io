param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$proc_name,
    [Parameter(Mandatory=$true)][string]$cred_path,
    [string]$proc_pid="*"
 )

$procdump_file = [io.file]::ReadAllBytes((gci | ? -Property Name -Like "*procdump.exe*").FullName)

$creds = Import-CliXml -Path $cred_path

$sesh = New-PSSession -ComputerName $ip -Credential $creds

$collect = $true

# dump all relevant processes
Invoke-Command -Session $sesh -ScriptBlock {
    # get the arguments from local machine
    param($procdump_file,$proc_name,$ip,$proc_pid) $OFS=',';

    # see if there are any process with matching name, and pid if pid is provided
    $procs = Get-Process | ? -Property Name -Like "*$proc_name*" | ? -Property Id -Like $proc_pid
    
    if(($procs | Measure-Object).Count -gt 0){
        $num = ($procs | Measure-Object).Count
        Write-Host "Found $num matching processes, dumping memory..." -ForegroundColor Yellow
        # move to the correct directory
        cd ~
        mkdir jyn_dump
        cd jyn_dump
        $my_dir = (Get-Location).Path

        # write the files to disk
        $prd_name = $my_dir+"\procdump.exe"
        [io.file]::WriteAllBytes($prd_name,$procdump_file)

        # dump each process
        ForEach($proc in $procs){
            .\procdump.exe -accepteula $proc.Id -ma
            $current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()
            $file = ((gci | ? -Property Name -Like "*.dmp")[0]).Name
            $new_name = $proc_name+"_"+$current_time+"_"+$proc.Id+"_"+$ip+".dmp"
            Rename-Item $file $new_name
        }

        # clean up executables
        Remove-Item -Path $prd_name
    }
    Else{ Write-Host "No matching processes on $ip." -ForegroundColor Yellow}

} -ArgumentList $procdump_file,$proc_name,$ip,$proc_pid

$collect = Invoke-Command -Session $sesh -ScriptBlock { cd ~; Test-Path jyn_dump }
# find and transfer the files back
if($collect){
    $files_to_transfer = Invoke-Command -Session $sesh -ScriptBlock { cd ~; cd jyn_dump; gci }

    $files_to_transfer | %{ Copy-Item -FromSession $sesh -Path $_.FullName -Destination ..\Dumps\$_ }

    # remove the folder on the remote system
    Invoke-Command -Session $sesh -ScriptBlock { cd ~; Remove-Item -Recurse jyn_dump }
    }

# tear down the session
$sesh | Remove-PSSession