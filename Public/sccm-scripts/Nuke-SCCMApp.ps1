function Nuke-SCCMApp {
    param (
        # Name - name of app to search for
        [Parameter(Mandatory)]
        [string]
        $Name
    )

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    $apps = Get-CMApplication -Name $Name -Fast

    if (-not $apps) {
        Write-Warning "Application '$Name' was not found."
        return
    }

    # warning message
    $title    = "Warning!"
    $message  = "You are about to NUKE the following applications: " + 
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
        Remove-SCCMDeployments -ApplicationName $app.LocalizedDisplayName
        Remove-SCCMAppContent -Name $app.LocalizedDisplayName
        Move-SCCMAppToBin -Name $app.localizedDisplayName
    }

    Set-Location $ogLoc
}