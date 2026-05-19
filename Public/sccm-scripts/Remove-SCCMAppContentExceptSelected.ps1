<#
.SYNOPSIS
Removes SCCM application content from all Distribution Points for apps you do NOT select.

.DESCRIPTION
Searches for applications using a localized display name wildcard.
It opens an Out-GridView window where you select the apps you want to KEEP the content for.
For any matching applications you do NOT select, it will purge their content from all standalone
Distribution Points and Distribution Point Groups

.EXAMPLE
Remove-CMAppContentExceptSelected -AppNameWildcard "*Google Chrome*"

.NOTES
Author: Matt McPhee
Date: 2026-05-20
Changelog:
- 2026-05-20 Matt McPhee: Initial script creation
#>
function Remove-SCCMAppContentExceptSelected {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, HelpMessage="Enter the app name with wildcards, e.g. *Adobe*")]
        [string]$AppNameWildcard
    )

    $ogLoc = Get-Location

    # fetch matching applications
    Write-Verbose "Querying SCCM for applications matching '$AppNameWildcard'..."
    $allApps = Get-CMApplication -Name $AppNameWildcard
    if (-not $allApps) {
        Set-Location $ogLoc
        throw "No applications found matching '$AppNameWildcard'."
    }

    # get selections from gridview
    Write-Verbose "Found $($allApps.Count) application(s). Opening GridView for selection..."

    $appsToKeep = $allApps | 
        Select-Object LocalizedDisplayName, SoftwareVersion, Manufacturer, DateCreated, CreatedBy, DateLastModified, LastModifiedBy | 
        Out-GridView -Title "Select apps to KEEP (Unselected apps will have content DELETED from ALL DPs!)" -PassThru

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
    $allDps = (Get-CMDistributionPoint).Name
    if (-not $allDps) {
        Set-Location $ogLoc
        throw "No Distribution Points found in SCCM."
    }

    $allDpGroups = (Get-CMDistributionPointGroup).Name
    if (-not $allDpGroups) {
        Set-Location $ogLoc
        throw "No Distribution Point Groups found in SCCM."
    }

    # remove content
    foreach ($app in $appsToRemove) {
        $target = "Application: $($app.LocalizedDisplayName)"
        $action = "Remove content from all Distribution Points and DP Groups"

        if ($PSCmdlet.ShouldProcess($target, $action)) {
            Write-Verbose "Removing content from all DPs for: $($app.LocalizedDisplayName)"
            try {
                Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName -DistributionPointName $allDps -Force -ErrorAction Stop
                Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName -DistributionPointGroupName $allDpGroups -Force -ErrorAction Stop
            } catch {
                Set-Location $ogLoc
                throw "Failed to remove content for '$($app.LocalizedDisplayName)'. Error: $_"
            }
        }
    }

    Write-Output "Content removal process completed successfully!"

    Set-Location $ogLoc
}
