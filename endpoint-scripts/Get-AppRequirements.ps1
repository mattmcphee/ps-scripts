function Get-AppRequirements {
    param(
        # ApplicationName
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationName
    )
    $apps = Get-CMApplication -ApplicationName $ApplicationName -Fast |
        Where-Object {($_.IsDeployed -like 'True') -and ($_.IsSuperseded -like 'False')}
    foreach ($app in $apps) {
        $dt = $app | Get-CMDeploymentType
        $requirements = $dt | Get-CMDeploymentTypeRequirement | 
            Select-Object RuleId,Name
        $output = [PSCustomObject]@{
            "AppName" = $app.LocalizedDisplayName
            "Requirements" = $requirements.Name
        }
        $output
    }
}