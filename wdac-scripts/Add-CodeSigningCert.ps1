function Add-CodeSigningCert {
    [CmdletBinding()]
    param (
        # Path to a script or folder containing scripts you wish to sign
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]
        $Path
    )
    $scripts = Get-ChildItem -Path $Path -Filter '*.ps1'
    foreach ($script in $scripts) {
        $cert = (Get-ChildItem -Path 'Cert:\CurrentUser\My' -CodeSigningCert)
        Set-AuthenticodeSignature -Certificate $cert `
            -FilePath $script.FullName `
            -HashAlgorithm "SHA256" `
            -IncludeChain notroot `
            -TimestampServer 'http://timestamp.digicert.com'
        Write-Host "Signed: $($script.FullName)"
        Start-Sleep 1
    }
}
