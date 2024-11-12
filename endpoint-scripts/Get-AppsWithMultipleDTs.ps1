function Get-AppsWithMultipleDTs {
    $apps = Get-CMApplication -Fast
    $target = $apps | Where-Object {$_.NumberOfDeploymentTypes -gt 1} | 
        Select-Object LocalizedDisplayName
    $target
}