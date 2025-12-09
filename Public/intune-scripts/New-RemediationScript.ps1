function New-RemediationScript {
    [CmdletBinding()]
    param (

    )

    # vars
    $AssignmentGroup = 'gp_co-management_usg'
    $DisplayName = "Update Adobe Apps"
    $Description = "This script will detect if RemoteUpdateManager.exe exists " +
    "on the target machine and then runs it. This downloads and " +
    "installs any updates available for Adobe Creative Cloud Desktop Application apps."
    $Publisher = "Matt McPhee"
    $RunAs = 'SYSTEM'
    $RunAs32 = $false
    $ScheduleType = "Daily"
    $ScheduleFrequency = "1"
    $StartTime = "01:00"
    $DetectionScriptPath = "C:\sources\repos\ps-scripts\intune-scripts\Update-AdobeAppsDetection.ps1"
    $detectionScriptContent = Get-Content $detectionScriptPath
    $detectionScriptContentBytes = [System.Text.Encoding]::UTF8.GetBytes($detectionScriptContent)
    $RemediationScriptPath = "C:\sources\repos\ps-scripts\intune-scripts\Update-AdobeAppsRemediation.ps1"
    $remediationScriptContent = Get-Content $remediationScriptPath
    $remediationScriptContentBytes = [System.Text.Encoding]::UTF8.GetBytes($remediationScriptContent)

    $scriptParams = @{
        displayName = $DisplayName
        description = $Description
        publisher = $Publisher
        runAs32Bit = $RunAs32
        runAsAccount = $RunAs
        enforceSignatureCheck = $false
        detectionScriptContent = $detectionScriptContentBytes
        remediationScriptContent = $remediationScriptContentBytes
        roleScopeTagIds = @("10", "7", "9")
    }

    $graphApiVersion = "beta"
    $resource = "deviceManagement/deviceHealthScripts"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$resource"

    try {
        $remediationScriptResponse = Invoke-MGGraphRequest -Uri $uri `
            -Method POST -Body $scriptParams -ContentType 'application/json' `
            -ErrorAction Stop
    } catch {
        Write-Error "$_"
    }

    $intuneGroupId = (Get-MgBetaGroup -Filter "DisplayName eq '$AssignmentGroup'").Id

    $assignmentParams = @{
        DeviceHealthScriptAssignments = @(
            @{
                Target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    GroupId = $intuneGroupId
                }
                RunRemediationScript = $true
                RunSchedule = @{
                    "@odata.type" = "#microsoft.graph.deviceHealthScriptDailySchedule"
                    Interval = $ScheduleFrequency
                    Time = $StartTime
                    UseUtc = $false
                }
            }
        )
    }

    $scriptId = $remediationScriptResponse.Id
    $uri = "https://graph.microsoft.com/$graphApiVersion/$resource/$scriptId/assign"

    try {
        $scriptAssignmentResponse = Invoke-MGGraphRequest -Uri $uri `
            -Method POST -Body $assignmentParams -ContentType 'application/json' `
            -ErrorAction Stop
    } catch {
        Write-Error "$_"
    }
}
