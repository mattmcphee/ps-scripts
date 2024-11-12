function Set-SMBforHelpdesk {
    [CmdletBinding()]
    param (
        # Sam Account Name or UPN of the shared mailbox
        [Parameter(Mandatory = $true)]
        [string]
        $Identity,
        # Desired display name of shared mailbox
        [Parameter(Mandatory = $true)]
        [string]
        $DisplayName,
        # Desired email address of shared mailbox
        [Parameter(Mandatory = $true)]
        [string]
        $EmailAddress
    )
    
    try {
        Get-RemoteMailbox $Identity -ErrorAction Stop | Out-Null
        if ($?) {
            Set-RemoteMailbox -Identity $Identity -DisplayName $DisplayName `
            -PrimarySmtpAddress $EmailAddress -EmailAddressPolicyEnabled $false
        }
    } catch {
        throw "Mailbox: $Identity was not found. Stopping..."
    }
}
