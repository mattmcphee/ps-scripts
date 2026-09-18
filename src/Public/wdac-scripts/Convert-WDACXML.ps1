function Convert-WDACXML {
    param (
        # folder path (no backslash at the end)
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $XmlFilePath,
        # output folder path (no backslash at the end)
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $CipOutputPath
    )
    $xmlFiles = Get-ChildItem -Path $XmlFilePath -Filter '*.xml'
    foreach ($xmlFile in $xmlFiles) {
        $xmlContent = [xml](Get-Content $xmlFile)
        $policyID = $xmlContent.SiPolicy.PolicyID
        $binaryFilePath = $CipOutputPath + '\' + $policyID + '.cip'
        ConvertFrom-CIPolicy -XmlFilePath $($xmlFile.FullName) `
            -BinaryFilePath $binaryFilePath
        $null = New-Item -ItemType File `
            -Path $CipOutputPath `
            -Name ($PolicyID + '-' + $xmlFile.BaseName + '.info') `
            -Force
    }
}
