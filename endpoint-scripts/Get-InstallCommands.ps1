function Get-InstallCommands {
    [CmdletBinding()]
    param (
        # Application name
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationName
    )
    # get the app object
    $app = Get-CMApplication $ApplicationName

    # explicitly cast to xml type so we can use dot notation
    [xml]$xml = $app.SDMPackageXML
    # pull out customdata so we don't have to reference the full path every time
    $customData = $xml.AppMgmtDigest.DeploymentType.Installer.CustomData
    # install line
    $installLine = $customData.InstallCommandLine
    # uninstall line
    $uninstallLine = $customData.UninstallCommandLine
    # repair line
    $repairLine = $customData.RepairCommandLine
    # dependency
    $dependency =   $xml.AppMgmtDigest.DeploymentType.Dependencies.
                    DeploymentTypeRule.Annotation.DisplayName.Text
    $msg = ""

    if ($installLine) {
        $msg += "Install Command:`n$installLine`n"
    } else {
        Write-Host "InstallCommandLine: This app doesn't have an install line."
    }

    if ($uninstallLine) {
        $msg += "Uninstall Command:`n$uninstallLine`n"
    } else {
        Write-Host "UninstallCommandLine: This app doesn't have an uninstall line."
    }

    if ($repairLine) {
        $msg += "Repair Command:`n$repairLine`n"
    } else {
        Write-Host "RepairCommandLine: This app doesn't have a repair line."
    }

    if ($dependency) {
        Write-Host "Dependencies: $dependency"
    } else {
        Write-Host "Dependencies: This app doesn't have any dependencies."
    }

    $msg | Set-Clipboard
    Write-Host $msg
}