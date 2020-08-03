# This script saves credentials to disk securely
# this only works on devices with a Trusted Platform Module (TPM)

# create secure credential object
$credentials = Get-Credential

# choose where the credentials will be saved
$cred_path = Read-Host -Prompt 'Input the file name and location'

# save the credentials
$credentials | Export-CliXml -Path $cred_path