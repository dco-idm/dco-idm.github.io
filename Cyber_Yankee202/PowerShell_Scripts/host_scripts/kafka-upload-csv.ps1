# this is the script used to upload csvs

# command line arguments
param (
    [string]$server_ip = "10.0.3.10",
    [string]$kafka_topic = "host_csv",
    [string]$server_port = "8082",
    [string]$file_path = "foo.csv"
 )

# header
$h = @{"Accept" = "application/vnd.kafka.v2+json"}

# kafka Uri
$kafka = "http://$server_ip`:$server_port/topics/$kafka_topic"

# Content type
$content = "application/vnd.kafka.json.v2+json"

# read a local file, change format of csv to work with kafka
$json_from_file = (Get-Content $file_path) -replace "[^\u0000-\u009f]","_JYN2_Unicode_"
$json_from_file = $json_from_file.Replace('\', '\\')
$json_from_file = $json_from_file.Replace('"', '\"')
$json_from_file = [string]::Join("\r\n",$json_from_file)

$fn = $file_path.ToString().Split("\")[-1]
# Format the data this way for kafka
$data = "{`"records`":[{`"key`": `"$fn`", `"value`": `"$json_from_file`"}]}"

# the "curl" command
Invoke-RestMethod -Uri $kafka -ContentType $content -Method Post -Headers $h -Body $data

# to run the command on a directory of CSV files, use the following command
#                            file name like this                    run script on each file
# gci | Where-Object -Property Name -Like "zindproc*" | %{ .\upload_json_old.ps1 -file_path $_.Name }
