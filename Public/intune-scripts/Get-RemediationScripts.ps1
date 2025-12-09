function Get-RemediationScripts {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"

    $healthScriptsResponse = Invoke-MgGraphRequest -Method GET -Uri $uri
    $scriptFolder = "$env:USERPROFILE\Downloads\remediation-scripts"
    if (-not(Test-Path $scriptFolder)) {
        New-Item -Path $scriptFolder -ItemType Directory
    }

    foreach ($scriptId in $healthScriptsResponse.value.id) {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$scriptId"

        $healthScriptResponse = Invoke-MgGraphRequest -Method GET -Uri $uri
        $scriptDisplayName = $healthScriptResponse.displayName

        if ($healthScriptResponse.detectionScriptContent -ne "") {
            $scriptFilePath = "$env:USERPROFILE\Downloads\remediation-scripts\$scriptDisplayName-DETECTION.ps1"
            $detScript = Convert-Base64 -Base64String $healthScriptResponse.detectionScriptContent
            Write-Host "DetectionScript:$scriptDisplayName====================="
            $detScript
            $detScript | Out-File $scriptFilePath -Force
        }

        if ($healthScriptResponse.remediationScriptContent -ne "") {
            $scriptFilePath = "$env:USERPROFILE\Downloads\remediation-scripts\$scriptDisplayName-REMEDIATION.ps1"
            $remScript = Convert-Base64 -Base64String $healthScriptResponse.remediationScriptContent
            Write-Host "RemediationScript:$scriptDisplayName==================="
            $remScript
            $remScript | Out-File $scriptFilePath -Force
        }
    }
}
