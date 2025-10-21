function Test-AutomationNullOrRegularNull {
    Write-Host 'Case 1: explicitly running switch on $null'
    switch ($null) {
        $null {
            Write-Host 'Case 1: value is $null'
        }

        default {
            Write-Host 'Case 1: default case'
        }
    }

    Write-Host 'Case 2: explicitly running switch on [System.Management.Automation.Internal.AutomationNull]::Value'
    switch ([System.Management.Automation.Internal.AutomationNull]::Value) {
        [System.Management.Automation.Internal.AutomationNull]::Value {
            Write-Host 'Case 2: value is AutomationNull'
        }

        default {
            Write-Host "Case 2: default case"
        }
    }

    Write-Host 'Case 3: running switch with Get-ItemProperty on reg key that doesnt exist'
    $profileValue = Get-ItemPropertyValue -Path HKLM:\Software\GMD\OpenVPN -Name "Profile" -ErrorAction SilentlyContinue
    switch ($profileValue) {
        $null {
            Write-Host 'Case 3: value is $null'
        }

        "hey" {
            Write-Host 'Case 3: value is hey'
        }

        default {
            Write-Host 'Case 3: default case'
        }
    }

    Write-Host 'The type of the $profileValue variable is:'
    if ($null -eq $profileValue) {
        Write-Host "Variable type of profileValue is null"
    } elseif ($profileValue.PSObject.BaseObject -is [System.Management.Automation.Internal.AutomationNull]) {
        Write-Host "Variable type of profileValue is [System.Management.Automation.Internal.AutomationNull]"
    } else {
        return $profileValue.GetType().FullName
    }
}

Test-AutomationNullOrRegularNull