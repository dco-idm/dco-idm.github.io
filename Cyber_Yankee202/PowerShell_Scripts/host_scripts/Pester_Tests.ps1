# make a test directory
New-Item -ItemType Directory "pester_test" > $null

# start the vagrant machine
Set-Location .\vagrant
vagrant up

# ip in the vagrant file
$vagrant_ip = "172.28.128.3"

Set-Location ..

# save the credentials so they work on this machine
# this output is the same as the secret_snacktime.ps1 script
$Username = 'vagrant'
$Password = 'vagrant'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$SecureString = $pass
$MySecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString

$MySecureCreds | Export-Clixml -Path .\creds.xml

###############################
#        Bad Cop Test
###############################
Describe "bad_cop.ps1" {
    Start-Sleep -Seconds 1
    New-Item -ItemType Directory ..\Dumps
    .\bad_cop.ps1 -ip $vagrant_ip -cred_path .\creds.xml -proc_name lsass
    Start-Sleep -Seconds 1

    $output_file = Get-ChildItem ..\Dumps\*.dmp | Select-Object -Last 1

    # make sure there is actually data
    $lines = (gc $output_file.FullName | Measure-Object).Count
    it 'should have a dump file' {
        $lines | should BeGreaterThan 0
    }

    # clean up at the end
    Get-ChildItem ..\Dumps\ | %{ Remove-Item $_.FullName }
    Remove-Item ..\Dumps\
}

###############################
#   Directory Hasher Test
###############################
Describe "directory_hasher.ps1" {
    Start-Sleep -Seconds 1
    .\directory_hasher.ps1 -ip $vagrant_ip -cred_path .\creds.xml -out_dir .\pester_test\
    Start-Sleep -Seconds 1

    $output_file = Get-ChildItem .\pester_test\ | Select-Object -Last 1

    # make sure there is actually data
    $lines = (gc $output_file.FullName | Measure-Object).Count
    it 'should have more than one row' {
        $lines | should BeGreaterThan 1
    }

    # make sure the output file is valid CSV
    $result = (gc $output_file.FullName | ConvertFrom-Csv | %{ $_.ComputerName } | Group-Object).Name

    it 'should be valid CSV' {
        $result | should be $vagrant_ip
    }

    # clean up at the end
    Get-ChildItem .\pester_test\ | %{ Remove-Item $_.FullName }
}

###############################
#       Heavy Survey
###############################
Describe "heavy_survey.ps1" {
    Start-Sleep -Seconds 1
    .\heavy_survey.ps1 -ip $vagrant_ip -cred_path .\creds.xml -out_dir .\pester_test\
    Start-Sleep -Seconds 1

    $output_file = Get-ChildItem .\pester_test\

    # make sure there is actually data
    $lines = (gc $output_file.FullName | Measure-Object).Count
    it 'should have more than one row' {
        $lines | should BeGreaterThan 10
    }

    # make sure the output file is valid CSV
    $result = (gc $output_file.FullName | ConvertFrom-Csv | %{ $_.PSComputerName } | Group-Object).Name

    it 'should be valid CSV' {
        $result | should be $vagrant_ip
    }

    # clean up at the end
    Get-ChildItem .\pester_test\ | %{ Remove-Item $_.FullName }
}

###############################
#       Judge Dredd Test
###############################
Describe "judge_dredd.ps1" {
    Start-Sleep -Seconds 1
    New-Item -ItemType Directory ..\Dumps
    .\judge_dredd.ps1 -ip $vagrant_ip -cred_path .\creds.xml -proc_name lsass
    Start-Sleep -Seconds 1

    $output_file = Get-ChildItem ..\Dumps\*.dmp | Select-Object -Last 1

    # make sure there is actually data
    $lines = (gc $output_file.FullName | Measure-Object).Count
    it 'should have a dump file' {
        $lines | should BeGreaterThan 0
    }

    # clean up at the end
    Get-ChildItem ..\Dumps\ | %{ Remove-Item $_.FullName }
    Remove-Item ..\Dumps\
}

###############################
#      Liam Neeson Test
###############################
Describe "liam_neeson.ps1" {
    Start-Sleep -Seconds 1
    New-Item -ItemType Directory ..\Files\
    .\liam_neeson.ps1 -ip $vagrant_ip -cred_path .\creds.xml -file_name C:\Windows\System32\ntdll.dll

    Start-Sleep -Seconds 1

    $output_file = Get-ChildItem ..\Files\*.dll | Select-Object -Last 1

    # make sure there is actually data
    $lines = (gc $output_file.FullName | Measure-Object).Count
    it 'should have a dll file' {
        $lines | should BeGreaterThan 0
    }

    # clean up at the end
    Get-ChildItem ..\Files\ | %{ Remove-Item $_.FullName }
    Remove-Item ..\Files\
}

###############################
#       Proc Hunter Test
###############################
Describe "proc_hunter.ps1"{
    Start-Sleep -Seconds 1
    .\proc_hunter.ps1 -ip $vagrant_ip -cred_path .\creds.xml -out_dir .\pester_test\
    Start-Sleep -Seconds 1

    $output_file = Get-ChildItem .\pester_test\ | Select-Object -Last 1

    # make sure there is actually data
    $lines = (gc $output_file.FullName | Measure-Object).Count
    it 'should have more than one row' {
        $lines | should BeGreaterThan 1
    }

    # make sure the output file is valid CSV
    $result = (gc $output_file.FullName | ConvertFrom-Csv | %{ $_.host } | Group-Object).Name

    it 'should be valid CSV' {
        $result | should be $vagrant_ip
    }

    # clean up at the end
    Get-ChildItem .\pester_test\ | %{ Remove-Item $_.FullName }
}

###############################
#     Service Hunter Test
###############################
Describe "service_hunter.ps1"{
    Start-Sleep -Seconds 1
    .\service_hunter.ps1 -ip $vagrant_ip -cred_path .\creds.xml -out_dir .\pester_test\
    Start-Sleep -Seconds 1

    $output_file = Get-ChildItem .\pester_test\ | Select-Object -Last 1

    # make sure there is actually data
    $lines = (gc $output_file.FullName | Measure-Object).Count
    it 'should have more than one row' {
        $lines | should BeGreaterThan 1
    }

    # make sure the output file is valid CSV
    $result = (gc $output_file.FullName | ConvertFrom-Csv | %{ $_.PSComputerName } | Group-Object).Name

    it 'should be valid CSV' {
        $result | should be $vagrant_ip
    }

    # clean up at the end
    Get-ChildItem .\pester_test\ | %{ Remove-Item $_.FullName }
}

###############################
#         Trogdor Test
###############################
Describe "trogdor.ps1" {
    Start-Sleep -Seconds 1
    New-Item -ItemType Directory ..\Dumps
    .\trogdor.ps1 -ip $vagrant_ip -cred_path .\creds.xml
    Start-Sleep -Seconds 1

    $output_file = Get-ChildItem ..\Dumps\*.dmp

    # make sure there is actually data
    $lines = ($output_file | Measure-Object).Count
<<<<<<< HEAD
    it 'should have dump files' {
=======
    it 'should have a dump file' {
>>>>>>> 1dc4275a6bccf330b9381a4bed1c51a9871e3aa1
        $lines | should BeGreaterThan 20
    }

    # clean up at the end
    Get-ChildItem ..\Dumps\ | %{ Remove-Item $_.FullName }
    Remove-Item ..\Dumps\
}

# tear down the vagrant
Set-Location .\vagrant
vagrant halt

Remove-Item "..\pester_test"

cd ..