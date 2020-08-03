# bash /home/brandon/test.sh directory_with_forward_slashes

$ErrorActionPreference = "Stop"

$files = gci ..\Dumps -Recurse -File -Filter *.dmp -ErrorAction SilentlyContinue

$files | %{
    Try{
        $file_path = $_.FullName
        $file_path = $file_path.ToString().Replace("\", "/")
        $file_path = $file_path.Replace("C:", "/mnt/c")
        $output = bash /home/brandon/test.sh $file_path
        $output = $output | ConvertFrom-Json

        $file_path

        # attributes
        $regex = [regex] "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"
        $filename = $_.Name.ToString()
        $ip = $regex.Matches($filename)
        $ip = $ip.Value
        
        $output | Add-Member -Name "ip" -Value $ip -MemberType NoteProperty

        $output | ConvertTo-Json
	    Write-Host $output

    }Catch{
        Write-Host "Error parsing dump! " -ForegroundColor Yellow -NoNewline
        Write-Host $_.FullName
    }
}
