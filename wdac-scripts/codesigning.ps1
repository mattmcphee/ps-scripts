$arguments = @{
    "Certificate"     = (Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert)
    "FilePath"        = "C:\DevOps\endpoint_01-1\PowerShell\Intune_Scripts\Intune-Remeditation-Disable-PowerShellV2-Remediation.ps1"
    "HashAlgorithm"   = "SHA256"
    "IncludeChain"    = "NotRoot"
    "TimestampServer" = "http://timestamp.digicert.com" #or your favorite
}
Set-AuthenticodeSignature @arguments

