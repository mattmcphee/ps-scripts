function Set-BasePolicyID {
    param (
        # folder path
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $FolderPath,
        # base policy ID
        [Parameter(Mandatory=$true)]
        [string]
        $BasePolicyID
    )
    $xmlFiles = Get-ChildItem -Path $FolderPath -Filter '*.xml'
    foreach ($xmlFile in $xmlFiles) {
        $xmlContent = [xml](Get-Content $xmlFile)
        Write-Host "Current BasePolicyID for $($xmlFile): $($xmlContent.SiPolicy.BasePolicyID)"
        $xmlContent.SiPolicy.BasePolicyID = $BasePolicyID
        Write-Host "BasePolicyID has been changed to $($xmlContent.SiPolicy.BasePolicyID)"
        $xmlContent.Save($xmlFile)
    }
}