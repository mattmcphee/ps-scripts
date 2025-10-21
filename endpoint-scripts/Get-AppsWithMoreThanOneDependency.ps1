function Get-AppsWithMoreThanOneDependency {
    $apps = Get-CMApplication -Fast

    $result = @()

    foreach ($app in $apps) {
        $appDepCount = (Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName).NumberOfDependedDTs

        if ($appDepCount -gt 1) {
            $appWithDeps = [PSCustomObject]@{
                ApplicationName = $app.localizeddisplayname
                DependencyCount = $appDepCount
            }
            Write-Host $appWithDeps

            $result += $appWithDeps
        }
    }

    if ($result.Count -eq 0) {
        Write-Host "No applications with more than one dependency found."
    } else {
        Write-Host "`nApplications with more than one dependency:`n"
        $result | Format-Table -AutoSize
    }
}
