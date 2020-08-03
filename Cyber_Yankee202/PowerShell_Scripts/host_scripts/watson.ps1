param (
    [Parameter(Mandatory=$true)][string]$ComputerName,
    [Parameter(Mandatory=$true)][string]$CredentialPath
 )

$creds = Import-CliXml -Path $CredentialPath

$sesh = New-PSSession -ComputerName $ComputerName -Credential $creds

$collect = $true

Write-Host "[$ComputerName]:" -ForegroundColor Yellow -NoNewline

# dump all relevant processes
$files_to_transfer = Invoke-Command -Session $sesh -ScriptBlock {
    # see if there are any process with matching name, and pid if pid is provided
    Set-Location C:\
    $ErrorActionPreference = "SilentlyContinue"
    $dumps = Get-ChildItem -Recurse | ? Name -Like "*.mdmp"
    $ErrorActionPreference = "Continue"
    if(($dumps | Measure-Object).Count -gt 0){
        $num = ($dumps | Measure-Object).Count
        Write-Host " Found $num matching files, collecting dumps..." -ForegroundColor Green
        $dumps
    }
    Else{ Write-Host " No dump files found on host." -ForegroundColor Yellow}
}

$collect = ($files_to_transfer | Measure-Object).Count -gt 0
# find and transfer the files back
if($collect){
    $files_to_transfer | %{ $filename = $ComputerName+"_"+$_.Name.ToString(); Write-Host $_.FullName; Copy-Item -FromSession $sesh -Path $_.FullName -Destination ..\Dumps\$filename }
    }

# tear down the session
$sesh | Remove-PSSession