function Set-RegistryKey {
    <#
    .SYNOPSIS
    Creates a registry key or updates it with new data if it already exists.
    .DESCRIPTION
    Creates a registry key or updates it with new data if it already exists.
    .NOTES
    This was taken from Powershell App Deployment Toolkit and modified to be a standalone function.
    .PARAMETER Key
    The path to the location containing the registry item
    .PARAMETER Name
    The name of the registry item
    .PARAMETER Value
    The value to set the registry item to
    .PARAMETER Type
    The type of the registry item - must be one of a number of types
    #>
    param (
        # the path to the registry key containing registry items
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key,
        # the name of the registry item
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        # the value of the registry item
        [Parameter()]
        [string]
        $Value,
        # the registry item type - defaults to string
        [Parameter()]
        [ValidateSet('Binary','DWord','ExpandString','MultiString','None','QWord','String','Unknown')]
        [Microsoft.Win32.RegistryValueKind]
        $Type = 'String'
    )

    process {
        try {
            # create registry key if it doesn't exist
            if (-not (Test-Path -LiteralPath $Key -ErrorAction 'Stop')) {
                New-Item -Path $Key -Force -ErrorAction 'Stop'
            }

            # if name supplied, set the value if it doesn't exist or update it if it does exist
            if ($Name) {
                if (-not(Get-ItemProperty -LiteralPath $Key -Name $Name -ErrorAction 'SilentlyContinue')) {
                    New-ItemProperty -LiteralPath $Key -Name $Name -Value $Value -PropertyType $Type -ErrorAction 'Stop'
                } else {
                    Set-ItemProperty -LiteralPath $Key -Name $Name -Value $Value -ErrorAction 'Stop'
                }
            }
        } catch {
            throw "Failed to create or set registry key [$Key]: $($_.Exception.Message)"
        }
    }
}
