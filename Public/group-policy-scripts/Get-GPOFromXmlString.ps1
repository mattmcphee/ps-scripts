function Get-GPOFromXmlString {

    [CmdletBinding()]
    param (
        # XmlString
        [Parameter(Mandatory)]
        [string]
        $XmlString
    )
        
    $tempPath = 'C:\sources\xml\gpo_report.xml'

    if (-not (Test-Path -Path (Split-Path $tempPath -Parent))) {
        New-Item -Path (Split-Path $tempPath -Parent) -ItemType Directory -Force
    }

    Write-Host "Searching GPOs using search term: $XmlString" -ForegroundColor 'Yellow'

    $allGPOs = Get-GPO -All

    foreach ($GPO in $allGPOs) {
        Get-GPOReport -Guid $GPO.Id -ReportType Xml -Path $tempPath

        [xml]$GPOXml = Get-Content -Path $tempPath

        if ($GPOXml) {
            $result = $GPOXml.GPO.Computer.ExtensionData | Where-Object { $_.Name -like $XmlString }

            if ($result) {
                Write-Host "Found: $($GPO.DisplayName) with ID: $($GPO.Id)" -ForegroundColor 'Green'
            }
        }
    }

    Remove-Item -Path $tempPath -Force
    Write-Host "Scan complete." -ForegroundColor 'Yellow'
}
