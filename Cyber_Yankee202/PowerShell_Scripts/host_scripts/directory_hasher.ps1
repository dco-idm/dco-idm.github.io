# push to the fileHasher Kafka topic (probably through the csv to json topic)

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
    $sesh = New-PSSession -ComputerName $ip -Credential $creds -ErrorAction Stop
    }
Catch{
    Write-Host "PSSession failed, is the host down?  Are the credentials correct? `nCheck the WinRM Service status and make sure you Enable-PSRemoting."
    exit
}

Write-Host "Session created, hashing files..." -ForegroundColor Green

$hash_survey = Invoke-Command -Session $sesh -ScriptBlock {
    param($ip) $OFS=',';

    $file_array = New-Object System.Collections.ArrayList

    $ErrorActionPreference = "Stop"

    $directory = "C:\Windows\System32\"

    # dir walk the specified directory
    #$files = Get-ChildItem $directory -Recurse -File -ErrorAction SilentlyContinue #-Include *.exe,*.dll,*.dmp,*.mdmp,*.jar,*.ps1,*.vbs,*.vb,*.bin,*.sys,*.msi,*.jar,*.bat,*.js

    $file_array.Add("ComputerName,FileName,FilePath,FileCreateTime,FileWriteTime,FileAccessTime,FileExtension,Hash,FileSize,SignerManualVerification,SignerSignatureStatus,SignerSignatureNotBeforeDate,SignerSignatureNotAfterDate,SignerSignatureIssuer,SignerSignatureSubject,SignerX509Status,TimeManualVerification,TimeStamperNotBeforeDate,TimeStamperNotAfterDate,TimeStamperIssuer,TimeStamperSubject,TimeX509Status") > $null

    Get-ChildItem $directory -Recurse -File -Include *.exe,*.dll,*.dmp,*.mdmp,*.jar,*.ps1,*.vbs,*.vb,*.bin,*.sys,*.msi,*.jar,*.bat,*.js -ErrorAction SilentlyContinue | %{
        $file_path = $_.FullName
        $name = $_.Name
        Try{
            $create = [Math]::Floor([decimal](Get-Date($_.CreationTimeUtc).ToUniversalTime()-uformat "%s"))
            $write = [Math]::Floor([decimal](Get-Date($_.LastWriteTimeUtc).ToUniversalTime()-uformat "%s"))
            $access = [Math]::Floor([decimal](Get-Date($_.LastAccessTimeUtc).ToUniversalTime()-uformat "%s"))
            }Catch{
                $create = ""
                $write = ""
                $access = ""
            }
        $extension = $_.Extension
        Try{
            $md5 = (Get-FileHash -Path $file_path -Algorithm SHA1).Hash
            }Catch{
                $md5 = "Could not hash"
            }
        $size = $_.Length

        # signature verification
        Try{
            $sig_check = Get-AuthenticodeSignature -FilePath $file_path
            $status = $sig_check.Status
            }Catch{
                $status = "File in use; could not verify status"
            }

        Try{
            # signer certificate stuffs
            $sc_cert = $sig_check.SignerCertificate
            $sc_manual_verified = "Not Verified"
            $s_notbefore = [Math]::Floor([decimal](Get-Date($sc_cert.NotBefore).ToUniversalTime()-uformat "%s"))
            $s_notafter = [Math]::Floor([decimal](Get-Date($sc_cert.NotAfter).ToUniversalTime()-uformat "%s"))
            $s_issuer = $sc_cert.Issuer.ToString().Replace(",", ";")
            $s_subject = $sc_cert.Subject.ToString().Replace(",", ";")
            
            # get the x.509 chain status
            $sc_chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
            if($sc_chain.Build($sc_cert)){
                $sc_manual_verified = "Verified"
            }
            $sc_chain_status = "Valid"
            if($sc_chain.ChainStatus.Length -gt 0){ 
                $sc_chain_status = ""
                $sc_chain.ChainStatus.Status | %{
                    $sc_chain_status+=$_.ToString()+";"
                }
            }

            # time stamper certificate stuffs
            $ts_cert = $sig_check.TimeStamperCertificate
            $ts_manual_verified = "Not Verified"
            $t_notbefore = [Math]::Floor([decimal](Get-Date($ts_cert.NotBefore).ToUniversalTime()-uformat "%s"))
            $t_notafter = [Math]::Floor([decimal](Get-Date($ts_cert.NotAfter).ToUniversalTime()-uformat "%s"))
            $t_issuer = $ts_cert.Issuer.ToString().Replace(",", ";")
            $t_subject = $ts_cert.Subject.ToString().Replace(",", ";")
            
            # get the x.509 chain status
            $t_chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
            if($t_chain.Build($ts_cert)){
                $ts_manual_verified = "Verified"
            }
            $t_chain_status = "Valid"
            if($t_chain.ChainStatus.Length -gt 0){ 
                $t_chain_status = ""
                $t_chain.ChainStatus.Status | %{
                    $t_chain_status+=$_.ToString()+";"
                }
            }

            }Catch{
                $sc_cert = ""
                $s_notbefore = ""
                $s_notafter = ""
                $s_issuer = ""
                $s_subject = ""
                $ts_cert = ""
                $t_notbefore = ""
                $t_notafter = ""
                $t_issuer = ""
                $t_subject = ""
                $sc_chain_status = ""
                $t_chain_status = ""
                $sc_manual_verified = ""
                $ts_manual_verified = ""
            }

        $file_array.Add("$ip,$name,$file_path,$create,$write,$access,$extension,$md5,$size,$sc_manual_verified,$status,$s_notbefore,$s_notafter,$s_issuer,$s_subject,$sc_chain_status,$ts_manual_verified,$t_notbefore,$t_notafter,$t_issuer,$t_subject,$t_chain_status") > $null
    }
    $file_array
    } -ArgumentList $ip

$sesh | Remove-PSSession

# generate filename
$current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString()
$filepath = $out_dir+"directory_hash_"+$current_time+"_"+$ip+".txt"

$hash_survey | Out-File $filepath -Append