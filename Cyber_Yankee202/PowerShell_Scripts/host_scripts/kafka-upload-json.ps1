# command line arguments
param (
    [string]$server_ip = "10.0.1.34",
    [string]$kafka_topic = "dll",
    [string]$server_port = "8082",
    [string]$file_path = "foo.json"
 )

# header
$h = @{"Accept" = "application/vnd.kafka.v2+json"}

# kafka Uri
$kafka = "http://$server_ip`:$server_port/topics/$kafka_topic"

# Content type
$content = "application/vnd.kafka.json.v2+json"

# read a local file, upload json to specified topic
$json_from_file = (Get-Content $file_path) -replace "[^\u0000-\u009f]","_JYN2_Unicode_"

# Format the data this way for kafka
$data = "{`"records`":[{`"value`": $json_from_file                                 }]}"

# the "curl" command
Invoke-RestMethod -Uri $kafka -ContentType $content -Method Post -Headers $h -Body $data

# to run the command on a directory of JSON files, use the following command
#                            file name like this                    run script on each file
# gci | Where-Object -Property Name -Like "zindproc*" | %{ .\upload_json_old.ps1 -file_path $_.Name }
