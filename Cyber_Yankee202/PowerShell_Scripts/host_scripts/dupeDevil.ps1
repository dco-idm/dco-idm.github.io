param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$cred_path,
    [int]$max_ads_bytes=2500,
    [string]$out_dir='..\Data\'
 )
$ErrorActionPreference = "SilentlyContinue"
$creds = Import-CliXml -Path $cred_path

$sesh = New-PSSession -ComputerName $ip -Credential $creds

$data = Invoke-Command -Session $sesh -ScriptBlock {
    param($max_ads_bytes)
    $files = Get-ChildItem -Path \ -Recurse -File -ErrorAction SilentlyContinue
    $files | % { 
        $streams = Get-Item $_.FullName -Stream * | ? Stream -notlike "*:$DATA*" | ? Stream -notlike "*Zone.Identifier*" 
        $streams | % { 
            if($_.length -lt $max_ads_bytes) { 
                $ads_content = Get-Content $_.FileName -Stream $_.Stream
                $_ | Add-Member -NotePropertyName ADS_Content -NotePropertyValue $ads_content
            }
            else {
                $ads_content = "ADS size greater than $max_ads_bytes bytes, and will not be displayed" 
                $_ | Add-Member -NotePropertyName ADS_Content -NotePropertyValue $ads_content
            }
        $_ | Select Filename,Stream,PSPath,Length,ADS_Content    
        }
    }
} -ArgumentList $max_ads_bytes 

$sesh | Remove-PSSession
$data
$current_time = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).ToString().Replace(".", "")
$filepath = $out_dir+"ads_"+$current_time+"_"+$ip+".json"

$data | ConvertTo-Json | Out-File $filepath -Encoding utf8
$ErrorActionPreference = "Continue"