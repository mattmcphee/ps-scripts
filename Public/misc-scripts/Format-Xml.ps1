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