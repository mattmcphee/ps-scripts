function mass-convert-policies {
    param (
        # folder path
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $FolderPath,
        # output path
        [Parameter(Mandatory=$false)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $OutputPath = $FolderPath
    )
    $xmlFiles = Get-ChildItem -Path $FolderPath -Filter '*.xml'
    foreach ($xmlFile in $xmlFiles) {
        $xmlContent = [xml](Get-Content $xmlFile)
        $policyID = $xmlContent.SiPolicy.PolicyID
        $binaryFilePath = $OutputPath + $policyID + '.cip'
        ConvertFrom-CIPolicy -XmlFilePath $xmlFile.FullName `
            -BinaryFilePath $binaryFilePath
        $null = New-Item -ItemType File `
            -Path $OutputPath `
            -Name ($PolicyID + '-' + $xmlFile.BaseName + '.info')
    }
}