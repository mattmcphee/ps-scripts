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

    # format xml helper function
    function Format-Xml {
        param (
            # XmlString
            [Parameter(Mandatory)]
            [string]
            $XmlString
        )

        try {
            $xml = [xml]$XmlString
        } catch {
            Write-Error "Couldn't format provided XmlString as xml - make sure it has the correct structure."
            return
        }

        # create XmlWriterSettings object to format xml
        $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
        $xmlWriterSettings.Indent = $true
        $xmlWriterSettings.IndentChars = "    "
        $xmlWriterSettings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
        $xmlWriterSettings.OmitXmlDeclaration = $true

        # create a StringWriter to capture the output as a string
        $stringWriter = New-Object System.IO.StringWriter

        # create XmlWriter using xmlwritersettings and stringwriter
        $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $xmlWriterSettings)

        # write the xml string
        $xml.WriteTo($xmlWriter)

        # close the writer to flush it out
        $xmlWriter.Close()

        # return formatted output
        return $stringWriter.ToString()
    }
    
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