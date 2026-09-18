function Download-HPBiosHPCMSL {
    [CmdletBinding()]
    param (
        # Path - path to save .bin bios files to
        [Parameter(Mandatory)]
        [string]$Path,
        # Model - all or part of the laptop model name to search bios for using HPCMSL
        [Parameter(Mandatory)]
        [string]$Model
    )

    if (!(Test-Path $Path -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $Path -Force
    }

    # Resolve the Platform/System Board ID for the Model
    $device = Get-HPDeviceDetails -Name "*$Model*" | Select-Object -First 1

    if ($device) {
        Write-Host "Found $($device.Name) (Platform ID: $($device.SystemID))" -ForegroundColor Cyan
        Write-Host "Downloading latest BIOS..." -ForegroundColor Yellow

        # get bin filename
        $filename = (Get-HPBIOSUpdates -Platform $device.SystemID -Latest).bin

        $biosFilePath = "$Path\$filename"

        # Downloads the latest .bin firmware payload directly into the folder
        Get-HPBIOSUpdates -Platform $device.SystemID -Download -SaveAs $biosFilePath
    } else {
        Write-Warning "Could not find a platform matching: $Model"
    }

    Write-Host "`nAll BIOS downloads complete! Files saved to $biosFilePath" -ForegroundColor Green
}
