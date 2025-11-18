<#
.SYNOPSIS
    This script deploys an existing SCCM application deployment type to a target collection.

.DESCRIPTION
    The script requires the Configuration Manager PowerShell module to be loaded. It finds the specified application,
    its deployment type, and the target collection, then creates a new application deployment.

.PARAMETER ApplicationName
    The name of the application to deploy. This must match the name of an existing application in SCCM.
    If the application has more than one deployment type this cmdlet will fail.

.PARAMETER CollectionName
    The name of the target collection to which the application will be deployed. This can be a user or device collection.

.NOTES
    - This script requires the Configuration Manager console and module to be installed on the machine where it is run.
    - Run this script from a PowerShell session with administrative privileges.
    - Ensure you are connected to the CM site by running Import-MEMModule

.EXAMPLE
    Deploy-SCCMApplication -ApplicationName "7-Zip 23.01 (x64)" -DeploymentTypeName "7-Zip 23.01 (x64) - Install" -CollectionName "AaronLocker Testing"
#>
function Deploy-SCCMApplication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ApplicationName,

        [Parameter(Mandatory = $false)]
        [string[]]$CollectionName,

        [Parameter(Mandatory = $false)]
        [bool]$ApprovalRequired = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Available", "Required")]
        [string]$DeployPurpose = 'Available',

        [Parameter(Mandatory = $false)]
        [string]$SupersededApplicationName, 

        [Parameter(Mandatory = $false)]
        [bool]$Uninstall = $false,

        [Parameter(Mandatory = $false)]
        [switch]$AaronLockerTesting,
        
        [Parameter(Mandatory = $false)]
        [switch]$HasMail,

        [Parameter(Mandatory = $false)]
        [switch]$ApplicationsForWorkstations
    )

    $ogLoc = Get-Location

    Set-Location 'A00:'

    # find the application object
    Write-Verbose "Searching for application: '$ApplicationName'..."
    try {
        $app = Get-CMApplication -Name "$ApplicationName" -Fast
        if (-not $app) {
            throw "Application '$ApplicationName' not found."
        } elseif ($app.Count -gt 1) {
            throw "Found more than one application when searching for '$ApplicationName'. Be more specific."
        }
    } catch {
        throw $_
    }

    # stop if app has more than one or less than one deployment type(s)
    if ($app.NumberOfDeploymentTypes -gt 1) {
        throw "Application '$ApplicationName' has more than one deployment type. Manual deployment required."
    } elseif ($app.NumberOfDeploymentTypes -lt 1) {
        throw "Application '$ApplicationName' has no deployment types."
    }

    # set supersedence if superseded application has been provided
    if ($SupersededApplicationName) {
        try {
            $dt = Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName
            $supersededApp = Get-CMApplication -Name $SupersededApplicationName -Fast
            if (-not $supersededApp) {
                throw "Application '$SupersededApplicationName' not found."
            } elseif ($supersededApp.Count -gt 1) {
                throw "Found more than one application when searching for '$SupersededApplicationName'. Be more specific."
            }
            if ($supersededApp.NumberOfDeploymentTypes -gt 1) {
                throw "Superseded application '$SupersededApplicationName' has more than one deployment type. Set supersedence manually."
            } elseif ($supersededApp.NumberOfDeploymentTypes -lt 1) {
                throw "Superseded application '$SupersededApplicationName' has no deployment types."
            }
            $supersededAppDt = Get-CMDeploymentType -ApplicationName $supersededApp.LocalizedDisplayName
            Write-Host "Setting supersedence..."
            Set-CMApplicationSupersedence -InputObject $app `
                -SupersededApplication $supersededApp `
                -CurrentDeploymentType $dt `
                -OldDeploymentType $supersededAppDt `
                -IsUninstall $Uninstall
            Write-Host "Supersedence set. Confirming..."
            
        } catch {
            throw $_
        }
    }

    $deadlineDateTime = (Get-Date -Hour 22 -Minute 00 -Second 00)
    $availableDateTime = $deadlineDateTime.AddDays(-1)

    Write-Verbose "Creating deployment(s) for '$ApplicationName'..."

    # find the target collection object
    if ($CollectionName) {
        foreach ($collectionItem in $CollectionName) {
            Write-Verbose "Searching for collection: '$collectionItem'..."
            try {
                $coll = Get-CMCollection -Name $collectionItem
                if (-not $coll) {
                    Write-Host "Collection: '$collectionItem' not found. Skipping..." -ForegroundColor Red
                    continue
                }

                New-CMApplicationDeployment -InputObject $app `
                    -Collection $coll `
                    -DeployAction Install `
                    -DeployPurpose $DeployPurpose `
                    -TimeBaseOn LocalTime `
                    -ApprovalRequired $ApprovalRequired `
                    -AvailableDateTime $availableDateTime `
                    -DeadlineDateTime $deadlineDateTime `
                    -UpdateSupersedence $true
        
                Write-Verbose "Successfully created deployment for application '$ApplicationName' to collection '$collectionItem'."
            } catch {
                throw $_
            }
        }
    }

    if ($AaronLockerTesting) {
        try {
            New-CMApplicationDeployment -InputObject $app `
                -CollectionId 'A0000209' `
                -DeployAction Install `
                -DeployPurpose Available `
                -TimeBaseOn LocalTime `
                -AvailableDateTime $availableDateTime `
                -DeadlineDateTime $deadlineDateTime `
                -UpdateSupersedence $true
        } catch {
            throw $_
        }

        Write-Verbose "Successfully created deployment for application '$ApplicationName' to collection 'AaronLocker Testing'."
    }

    if ($HasMail) {
        try {
            New-CMApplicationDeployment -InputObject $app `
                -CollectionId 'A0000039' `
                -DeployAction Install `
                -DeployPurpose $DeployPurpose `
                -TimeBaseOn LocalTime `
                -ApprovalRequired $ApprovalRequired `
                -AvailableDateTime $availableDateTime `
                -DeadlineDateTime $deadlineDateTime `
                -UpdateSupersedence $true
        } catch {
            throw $_
        }

        Write-Verbose "Successfully created deployment for application '$ApplicationName' to collection 'HasMail'."
    }

    if ($ApplicationsForWorkstations) {
        try {
            New-CMApplicationDeployment -InputObject $app `
                -CollectionId 'A00001AF' `
                -DeployAction Install `
                -DeployPurpose $DeployPurpose `
                -TimeBaseOn LocalTime `
                -ApprovalRequired $true `
                -AvailableDateTime $availableDateTime `
                -DeadlineDateTime $deadlineDateTime `
                -UpdateSupersedence $true
        } catch {
            throw $_
        }

        Write-Verbose "Successfully created deployment for application '$ApplicationName' to collection 'Applications for Workstations'."
    }

    Set-Location $ogLoc
}
