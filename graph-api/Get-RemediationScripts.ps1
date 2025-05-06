function Get-RemediationScripts {
    function Convert-Base64 {
        [CmdletBinding()]
        param (
            # base 64 string
            [Parameter(Mandatory,ValueFromPipeline)]
            [string]
            $Base64String
        )

        process {
            $bytes = [System.Convert]::FromBase64String($Base64String)
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
            return $content
        }
    }

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
