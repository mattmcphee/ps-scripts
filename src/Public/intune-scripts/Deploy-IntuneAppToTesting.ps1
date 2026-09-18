function Deploy-IntuneAppToTesting {
    [CmdletBinding()]
    param (
        # DisplayName - displayname of app in intune
        [Parameter(Mandatory=$true)]
        [string]$DisplayName
    )

    try {
        $win32App = Get-IntuneWin32App | Where-Object DisplayName -like $DisplayName
    } catch {
        throw "Encountered error when retrieving app from intune with displayname: '$DisplayName'"
    }

    if ($null -eq $win32App) {
        throw "Could not find app with DisplayName: '$DisplayName'"
    } elseif ($win32App.Count -gt 1) {
        throw "Found more than 1 app with DisplayName: '$DisplayName'. Be more specific."
    }

    try {
        $intuneWin32AppAssignmentArgs = @{
            Include         = $true
            ID              = $win32App.id
            GroupID         = "9deb0e98-7051-4279-9e7a-31ec1daae2b9"
            Intent          = "available"
            Notification    = "showAll"
        }
        Add-IntuneWin32AppAssignmentGroup @intuneWin32AppAssignmentArgs
    } catch {
        throw "Encountered error when assigning '$DisplayName' to mem-device-app-testing_gs with ID '9deb0e98-7051-4279-9e7a-31ec1daae2b9'"
    }
}
