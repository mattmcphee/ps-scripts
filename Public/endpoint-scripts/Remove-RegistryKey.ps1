function Remove-RegistryKey {
    param (
        # the path to the location containing registry items
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key,
        # the name of the registry item
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        # recurse - specify to delete all items in path
        [Parameter()]
        [switch]
        $Recurse
    )

    try {
        if (-not $Name) {
            if (Test-Path -LiteralPath $Key -ErrorAction 'Stop') {
                if ($Recurse) {
                    Remove-Item -LiteralPath $Key -Force -Recurse -ErrorAction 'Stop'
                } else {
                    if ($null -eq (Get-ChildItem -LiteralPath $Key -ErrorAction 'Stop')) {
                        Remove-Item -LiteralPath $Key -Force -ErrorAction 'Stop'
                    } else {
                        throw "Unable to delete child keys of $Key without recurse switch."
                    }
                }
            }
        } else {
            if (Test-Path -LiteralPath $Key -ErrorAction 'Stop') {
                Remove-ItemProperty -LiteralPath $Key -Name $Name -Force -ErrorAction 'Stop'
            } else {
                Write-Host "Unable to delete registry value $Key $Name because registry key does not exist."
            }
        }
    } catch {
        throw "Failed to delete registry key $Key. $($_.Exception.Message)"
    }
}
