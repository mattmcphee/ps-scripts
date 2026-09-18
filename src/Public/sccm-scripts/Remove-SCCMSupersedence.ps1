function Remove-SCCMSupersedence {
    [CmdletBinding(DefaultParameterSetName = 'ByApplicationName')]
    param (
        # ApplicationName
        [Parameter(Mandatory = $true, ParameterSetName = 'ByApplicationName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCreationDateRange')]
        [string]
        $ApplicationName,
        # CreationDateRangeStart
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCreationDateRange')]
        [datetime]
        $CreationDateRangeStart,
        # CreationDateRangeEnd
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCreationDateRange')]
        [datetime]
        $CreationDateRangeEnd
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
            Write-Warning "Could not remove supersedence for $($app.LocalizedDisplayName). Error: $_"
        }
        Write-Host "Removed supersedence for $($app.LocalizedDisplayName)"
    }

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    switch ($PSCmdlet.ParameterSetName) {
        'ByApplicationName' {
            try {
                Remove-SCCMSupersedenceHelper -ApplicationName $ApplicationName
            } catch {
                throw $_
            }
        }

        'ByCreationDateRange' {
            try {
                # get array of apps e.g. 'Zoom Workplace*' will return around 18 app objects
                $apps = Get-CMApplication -Name $ApplicationName -Fast
                if ($apps.Count -lt 1) {
                    throw "Could not find any application objects with application name: $ApplicationName"
                } elseif ($apps.Count -eq 1) {
                    $msg = "Found only one application object using application name: $ApplicationName - " +
                    "try running this cmdlet again without any CreationDateRange parameters."
                    throw $msg
                }

                # filter the array based on creationdaterange params
                $filteredDateApps = $apps | Where-Object { $_.DateCreated -gt $CreationDateRangeStart -and $_.DateCreated -lt $CreationDateRangeEnd }
                if ($filteredDateApps.Count -le 1) {
                    $msg = "Only found 1 or less application objects between those CreationDateRange parameters. " +
                    "Try widening the range."
                    throw $msg
                } 

                foreach ($app in $filteredDateApps) {
                    Remove-SCCMSupersedenceHelper -ApplicationName $app.LocalizedDisplayName
                }
            } catch {
                throw $_
            }
        }
    }

    Set-Location $ogLoc
}
