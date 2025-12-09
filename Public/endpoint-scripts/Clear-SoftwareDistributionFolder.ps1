function Clear-SoftwareDistributionFolder {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        try {
            # 1. Stop the Windows Update and BITS services
            Write-Host "Stopping Windows Update Services..."
            Stop-Service -Name "wuauserv" -Force
            Stop-Service -Name "bits" -Force

            # 2. Rename the SoftwareDistribution folder to clear the path
            # This is safer than directly deleting, as Windows will recreate a new, empty one.
            $SoftwareDistributionPath = "C:\Windows\SoftwareDistribution"
            $NewPath = "C:\Windows\SoftwareDistribution.old"

            if (Test-Path $SoftwareDistributionPath) {
                Write-Host "Renaming SoftwareDistribution folder..."
                Rename-Item -Path $SoftwareDistributionPath -NewName $NewPath -Force
            }
    
            # 3. Start the services again
            Write-Host "Starting Windows Update Services..."
            Start-Service -Name "wuauserv" -Passthru
            Start-Service -Name "bits" -Passthru

            # Optional: Delete the old folder after services are started and it's confirmed clear
            # This step might take a few minutes for the system to release all locks.
            Write-Host "Deleting old SoftwareDistribution folder..."
            Remove-Item -Path $NewPath -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            throw $_
        }
    }
}