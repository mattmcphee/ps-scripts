<#
.SYNOPSIS
Removes supersedence, deployments and distributed data from application(s).
.DESCRIPTION
From an input application name, lists all applications found with same name in Out-GridView
Selected applications have supersedence and or deployments and or distributed data removed
.PARAMETER ApplicationName
This will take input in the form of a application name.
This is required.
.PARAMETER Supersedence
Switch if enabled will remove all supersedence from the application.
This is optional.
.PARAMETER Deployments
Switch if enabled will remove all deployments from the application.
This is optional.
.PARAMETER Distribution
Switch if enabled will remove all distribution data for the application.
This is optional.
.INPUTS
Application name
.OUTPUTS
Configuration Manager changes and info to console/gridview.
.Notes
Version:        1.00
Author:         Victor Rodriguez
Creation Date:  08/09/2021
Changes:        Initial script development
                19-05-2022 Added IsSuperseding, IsDeployed Data to the Out-GridView
                28-11-2024 Matt McPhee cleaned up formatting and punctuation
.EXAMPLE
Remove all supersedence from selected application
PS> Remove-MEMAppDDS "12D Model" -Supersedence
.EXAMPLE
Remove All deployments from selected application
PS> Remove-MEMAppDDS "12D Model" -Deployments
.EXAMPLE
Remove All Distributed data for selected application
PS> Remove-MEMAppDDS "12D Model" -Distribution
.EXAMPLE
Remove all supersedence and all deployments and all distributed data for selected application
PS> Remove-MEMAppDDS "12D Model" -Supersedence -Deployments -Distribution
#>
function Remove-SCCMApplicationOldVersions {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $ApplicationName
    )

    function Remove-SCCMSupersedenceHelper {
        param (
            # ApplicationName
            [Parameter(Mandatory = $true)]
            [string]
            $ApplicationName
        )
        
        # find the application object
        Write-Verbose "Searching for application: '$ApplicationName'..."
        $app = Get-CMApplication -Name "$ApplicationName" -Fast
        if ($app.Count -lt 1) {
            throw "Application '$ApplicationName' not found."
        } elseif ($app.Count -gt 1) {
            throw "Found more than one application when searching for '$ApplicationName'. Be more specific."
        }

        # stop if app has more than one or less than one deployment type(s)
        if ($app.NumberOfDeploymentTypes -gt 1) {
            throw "Application '$ApplicationName' has more than one deployment type. Stopping..."
        } elseif ($app.NumberOfDeploymentTypes -lt 1) {
            throw "Application '$ApplicationName' has no deployment types."
        }

        # get current deploymenttype object of app using name of app
        $dt = Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName
        if ($dt.Count -lt 1) {
            throw "Could not find deployment type for application: $($app.LocalizedDisplayName)"
        }

        # get superseded deploymenttype object using current deploymenttype object
        $supersededDt = Get-CMDeploymentTypeSupersedence -InputObject $dt
        if ($supersededDt.Count -lt 1) {
            Write-Host "Could not find superseded deployment type for application: $($app.LocalizedDisplayName) - it has no supersedence."
            return
        }

        # get superseded application object using name of superseded deploymenttype object
        $supersededApp = Get-CMApplication -Name $supersededDt.LocalizedDisplayName -Fast
        if ($supersededApp.Count -lt 1) {
            throw "Could not find superseded application: $($supersededDt.LocalizedDisplayName)"
        }

        try {
            Set-CMApplicationSupersedence `
                -InputObject $app `
                -SupersededApplication $supersededApp `
                -CurrentDeploymentType $dt `
                -OldDeploymentType $supersededDt `
                -RemoveSupersedence `
                -Force `
                -ErrorAction "Stop"
        } catch {
            throw "Could not remove supersedence for $($app.LocalizedDisplayName). Error: $_"
        }

        Write-Host "Removed supersedence for $($app.LocalizedDisplayName)"
    }

    # store current location and change dir to CM drive
    try {
        $ogLoc = Get-Location
        Set-Location "A00:\"
    } catch {
        throw $_
    }
    
    # get application
    try {
        $applications = Get-CMApplication -Fast -ApplicationName $ApplicationName -ErrorAction "Stop"
    } catch {
        throw $_
    }

    if ($applications.Count -lt 1) {
        throw "Could not find any applications using search term: $ApplicationName"
    } elseif ($applications.Count -le 10) {
        $msg = "Could not find more than 10 applications using search term: $ApplicationName" + 
            "`nNo applications to delete."
        throw $msg
    }

    # sort app list by datecreated descending and skip the first 10
    # we want to get only the apps that are NOT one of the latest 10 versions of the app
    $apps = $applications | Sort-Object DateCreated -Descending | Select-Object * -Skip 10

    # next, we want to make sure the 'tenth' oldest version isn't superseding anything
    # because after we delete all versions EXCEPT for the latest 10, this 'tenth' oldest
    # version will become the oldest version
    $tenthOldestApp = $applications | Sort-Object DateCreated -Descending | Select-Object * -Skip 9 -First 1

    if ($tenthOldestApp.isSuperseding) {
        Write-Host "Found supersedence on tenth oldest app version: $($tenthOldestApp.LocalizedDisplayName). Removing..."
        Remove-SCCMSupersedenceHelper -ApplicationName $tenthOldestApp.LocalizedDisplayName
    }

    # get distribution points to remove content from them
    $dps = Get-CMDistributionPoint | Select-Object -ExpandProperty NetworkOSPath

    # warning message
    $title    = "Warning!"
    $message  = "You are about to delete the following applications: " + 
        "`n`n$($apps.LocalizedDisplayName -join "`n")`n`nAre you sure you wish to continue?"
    $options  = "&Yes", "&No" # The ampersand defines the hotkey (Y and N)
    $default  = 1 # Sets 'No' as the default index

    $selection = $host.ui.PromptForChoice($title, $message, $options, $default)

    if ($selection -eq 0) {
        Write-Host "You chose Yes. Starting process..."
    } else {
        Write-Host "Operation aborted by user."
        return
    }

    foreach ($app in $apps) {
        Write-Host "Working on: $($app.LocalizedDisplayName)"

        # remove supersedence if present
        if ($app.isSuperseding) {
            Write-Host "Found supersedence relationship for $($app.LocalizedDisplayName). Removing..."
            Remove-SCCMSupersedenceHelper $app.LocalizedDisplayName
        }

        # remove deployments
        if ($app.NumberOfDeployments -gt 0) {
            try {
                Write-Host "Found deployments for $($app.LocalizedDisplayName)"
                Remove-CMApplicationDeployment -InputObject $app -Force -ErrorAction "Stop"
            } catch {
                throw $_
            }
            Write-Host "Removed all deployments for app: $($app.LocalizedDisplayName)"
        }

        # remove content from DPs
        foreach ($dp in $dps) {
            try {
                Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName `
                    -DistributionPointName $dp `
                    -Force `
                    -ErrorAction "Stop"
                Write-Host "Content for $($app.LocalizedDisplayName) removed from distribution point: $dp"
            } catch {
                Write-Verbose "$($app.LocalizedDisplayName) not found on: $dp"
            }
        }

        # remove application from sccm
        try {
            Remove-CMApplication -Name $app.LocalizedDisplayName -Force -ErrorAction "Stop"
        } catch {
            throw $_
        }
    }

    Write-Host "Removed these apps from SCCM (only keeping 10 most recent):"
    foreach ($app in $apps) {
        Write-Host $app.LocalizedDisplayName
    }

    Set-Location $ogLoc
}
