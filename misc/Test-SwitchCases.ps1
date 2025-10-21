Write-Host "switch on hey"
switch ("hey") {
    "hey" {
        Write-Host "hey"
    }

    default {
        Write-Host "default case"
    }
}

Write-Host "switch on empty array"
switch (@()) {
    "hey" {
        Write-Host "hey"
    }

    default {
        Write-Host "default case"
    }
}

Write-Host "switch on blah"
switch ("blah") {
    "hey" {
        Write-Host "hey"
    }

    default {
        Write-Host "default case"
    }
}

Write-Host "switch on [System.Management.Automation.Internal.AutomationNull]"
switch ([System.Management.Automation.Internal.AutomationNull]::Value) {
    "hey" {
        Write-Host "hey"
    }

    default {
        Write-Host "default case"
    }
}

Write-Host "switch on null"
switch ($null) {
    "hey" {
        Write-Host "hey"
    }

    default {
        Write-Host "default case"
    }
}

Write-Host 'switch on empty get-itempropertyvalue variable'
$profileValue = Get-ItemPropertyValue -Path HKLM:\Software\GMD\OpenVPN -Name "Profile" -ErrorAction SilentlyContinue
switch ($profileValue) {
    "hey" {
        Write-Host "hey"
    }

    default {
        Write-Host "default case"
    }
}

Write-Host 'switch on undefined variable'
switch ($adsfjgskjdhgagf) {
    "hey" {
        Write-Host "hey"
    }

    default {
        Write-Host "default case"
    }
}