function Move-SCCMAppToBin {
    param (
        # Name - name of application in sccm
        [Parameter(Mandatory)]
        [string]$Name
    )

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    $app = Get-CMApplication -Name $Name -Fast

    foreach ($application in $app) {
        try {
            $application | Move-CMObject -FolderPath ".\Application\``BIN"
        } catch {
            throw "Encountered error when moving application '$($application.LocalizedDisplayName)' to folder '.\Application\``BIN'. $_"
        }
    }

    Set-Location $ogLoc
}
