function Add-MITLicence {
    [CmdletBinding()]
    param (
        # Path
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Path: '$_' not found."
            }
            if (-not (Test-Path $_ -PathType Container)) {
                throw "Path: '$_' is not a directory."
            }
            $true
        })]
        [string]
        $FolderPath,
        # Name
        [Parameter(Mandatory)]
        [string]
        $Name
    )
    
    # get licence content
    $licenceContent = (Invoke-RestMethod -Uri 'https://api.github.com/licenses/mit').body
    
    # replace year in the content with current year
    $licenceContent = $licenceContent -replace '\[year\]', (Get-Date -Format yyyy)
    
    # replace name in content with name param
    $licenceContent = $licenceContent -replace '\[fullname\]', $Name
    
    # put LICENSE file (no extension) in path
    $licenceContent | Out-File -FilePath "$FolderPath\LICENSE" -Encoding 'utf8' | Out-Null
}
