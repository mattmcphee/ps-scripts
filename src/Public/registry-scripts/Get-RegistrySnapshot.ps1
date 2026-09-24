function Get-RegistrySnapshot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $normalizedPath = ConvertTo-RegistryPath $Path

        if (-not (Test-Path $normalizedPath)) {
            throw "Could not find path '$Path'."
        }

        $itemProps = Get-ItemProperty -Path $normalizedPath -ErrorAction Stop

        $propObj = [PSCustomObject]@{}

        foreach ($itemProp in $itemProps.PSObject.Properties) {
            if ($itemProp.Name -notmatch "^PS") {
                $propObj | Add-Member -MemberType NoteProperty -Name $itemProp.Name -Value $itemProp.Value
            }
        }

        $propObj
    } catch {
        throw $_
    }
}
