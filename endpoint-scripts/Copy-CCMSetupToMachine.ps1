function Copy-CCMSetupToMachine {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )
    
    try {
        $startLoc = Get-Location
        Set-Location "C:\"
        $ccmSetupHostPath = "C:\sources\staging\ccmsetup"
        $ccmSetupDestinationPath = "\\$ComputerName\c$\Windows"
        Copy-Item -Path $ccmSetupHostPath -Destination $ccmSetupDestinationPath -Recurse -Force -ErrorAction Stop
        Write-Host "Success!" -ForegroundColor Green
        Set-Location $startLoc

    } catch {
        throw $_
    }
}
