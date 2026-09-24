<#
.SYNOPSIS
Removes SCCM application content from all Distribution Points for apps you do NOT select.

.DESCRIPTION
Searches for applications using a localized display name wildcard.
It opens an Out-GridView window where you select the apps you want to KEEP the content for.
For any matching applications you do NOT select, it will purge their content from all standalone
Distribution Points and Distribution Point Groups

.EXAMPLE
Remove-SCCMAppContentExceptSelected -ApplicationName "*Google Chrome*"

.NOTES
Author: Matt McPhee
Date: 2026-05-20
Changelog:
- 2026-05-20 Matt McPhee: Initial script creation
#>
function Remove-SCCMAppContentExceptSelected {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, HelpMessage="Enter the app name (supports wildcards), e.g. *Adobe*")]
        [string]$ApplicationName
    )

    $ogLoc = Get-Location
    Set-Location "A00:"

    # fetch matching applications
    Write-Verbose "Querying SCCM for applications matching '$ApplicationName'..."

    try {
        $allApps = Get-CMApplication -Name $ApplicationName -ErrorAction Stop
    } catch {
        Set-Location $ogLoc
        throw "Error fetching applications: $_"
    }

    if (-not $allApps) {
        Set-Location $ogLoc
        throw "No applications found matching '$ApplicationName'."
    }

    # get selections from gridview
    Write-Verbose "Found $($allApps.Count) application(s). Opening GridView for selection..."

    $appsToKeep = $allApps |
        Select-Object LocalizedDisplayName, SoftwareVersion, Manufacturer, DateCreated, CreatedBy, DateLastModified, LastModifiedBy, NumberOfDeployments, CI_ID |
        Sort-Object DateCreated |
        Out-GridView -Title "Select app content to KEEP (Unselected apps will have content DELETED from ALL DPs!)" -PassThru

    # handle no selection
    if (-not $appsToKeep) {
        $title = "Warning: No Apps Selected"
        $message = "You did not select any applications to keep. This means ALL matching apps will have their content removed. Are you sure you want to proceed?"
        $choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
            "&Yes, remove content for ALL",
            "&No, abort"
        )
        # 1 is the index of the default choice (No, abort)
        $decision = $Host.UI.PromptForChoice($title, $message, $choices, 1)

        if ($decision -eq 1) {
            Write-Verbose "Operation aborted by user. No content was removed."
            Set-Location $ogLoc
            return
        }
    }

    # filter out apps to remove
    if ($appsToKeep) {
        $keepIds = $appsToKeep.CI_ID
    } else {
        $keepIds = @()
    }
    $appsToRemove = $allApps | Where-Object { $_.CI_ID -notin $keepIds }

    if (-not $appsToRemove) {
        Write-Verbose "All applications were selected to be kept. No content will be removed."
        Set-Location $ogLoc
        return
    }

    # fetch all DPs and DP Groups
    Write-Verbose "Fetching all Distribution Points and Distribution Point Groups..."
    $allDps = (Get-CMDistributionPoint).NetworkOSPath.Replace('\\', '')
    if (-not $allDps) {
        Set-Location $ogLoc
        throw "No Distribution Points found in SCCM."
    }

    $allDpGroups = (Get-CMDistributionPointGroup).Name
    if (-not $allDpGroups) {
        Set-Location $ogLoc
        throw "No Distribution Point Groups found in SCCM."
    }

    # remove content if distributed
    foreach ($app in $appsToRemove) {
        $distStatus = Get-CMDistributionStatus -InputObject $app

        if ($distStatus.Targeted -eq 0) {
            Write-Verbose "Skipping '$($app.LocalizedDisplayName)' as it has no content distributed to any DPs."
            continue
        }

        $target = "Application: $($app.LocalizedDisplayName)"
        $action = "Remove content from all Distribution Points and DP Groups"

        if ($PSCmdlet.ShouldProcess($target, $action)) {
            Write-Verbose "Removing content from all DPs for: $($app.LocalizedDisplayName)"
            try {
                Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName -DistributionPointName $allDps -Force -ErrorAction SilentlyContinue
                Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName -DistributionPointGroupName $allDpGroups -Force -ErrorAction SilentlyContinue
            } catch {
                continue
            }
        }
    }

    Write-Output "Content removal process completed successfully!"

    Set-Location $ogLoc
}
