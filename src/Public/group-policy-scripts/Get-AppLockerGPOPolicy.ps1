function Get-AppLockerGPOPolicy {
    [CmdletBinding()]
    param (
        # GpoName
        [Parameter(Mandatory)]
        [string]
        $GpoName,
        # FilePath
        [Parameter(Mandatory = $false)]
        [ValidateScript({
            $dir = Split-Path $_ -Parent
            if (Test-Path $dir) {
                return $true
            } else {
                throw "LogPath: The folder path '$dir' does not exist."
            }
        })]
        [string]
        $FilePath,
        # Formatted
        [Parameter(Mandatory = $false)]
        [switch]
        $Formatted
    )
    
    try {
        # Get the GPO path
        $actualGpo = Get-GPO -Name $GpoName
        if ($actualGpo.Count -lt 1) {
            throw "Could not find GPO with name: $GpoName"
        }
        if ($actualGpo.Count -gt 1) {
            throw "Found more than one group name. Be more specific."
        }

        $gpoPath = $actualGpo.Path

        # get the applocker policy
        $applockerPolicy = Get-AppLockerPolicy -Ldap "LDAP://$gpoPath" -Domain -Xml

        if ($Formatted) {
            $applockerPolicy = Format-Xml -XmlString $applockerPolicy
        }

        if ($FilePath) {
            $applockerPolicy | Out-File -FilePath $FilePath -Force -Encoding utf8
            return
        }

        $applockerPolicy
    } catch {
        throw $_
    }
}