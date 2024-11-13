function Convert-WDACXML {
    param (
        # folder path
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $XmlFilePath,
        # output path
        [Parameter(Mandatory=$false)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $CipOutputPath = $XmlFilePath
    )
    $xmlFiles = Get-ChildItem -Path $XmlFilePath -Filter '*.xml'
    foreach ($xmlFile in $xmlFiles) {
        $xmlContent = [xml](Get-Content $xmlFile)
        $policyID = $xmlContent.SiPolicy.PolicyID
        $binaryFilePath = $CipOutputPath + $policyID + '.cip'
        ConvertFrom-CIPolicy -XmlFilePath $xmlFile.FullName `
            -BinaryFilePath $binaryFilePath
        $null = New-Item -ItemType File `
            -Path $CipOutputPath `
            -Name ($PolicyID + '-' + $xmlFile.BaseName + '.info')
    }
}