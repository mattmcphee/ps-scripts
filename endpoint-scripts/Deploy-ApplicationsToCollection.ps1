function Deploy-ApplicationsToCollection {
    <#
    .SYNOPSIS
        Deploys a list of applications to a collection. The application and the 
        collection must already exist for this function to work.
    .NOTES
        Version:        1.0
        Author:         Matt McPhee
        Creation Date:  28/08/2024
    .PARAMETER ApplicationListPath
        A filepath string to the location of the txt file containing a list of apps
    .PARAMETER CollectionName
        The CollectionName string of the collection you want to deploy the application to
    .OUTPUTS
        Application deployed to specified collection
    .EXAMPLE
        Deploy-ApplicationsToCollection `
            -ApplicationListPath C:\sources\txt\apps.txt `
            -CollectionName "WDAC-Testing-Software"
    #>
    [CmdletBinding()]
    param (
        # Filepath to a list of application names in txt format
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]
        $ApplicationListPath,
        # Name of the collection to deploy the application to
        [Parameter(Mandatory=$true)]
        [string]
        $CollectionName
    )
    
    Import-MEMModule A00

    $apps = Get-Content -Path $ApplicationListPath
    $collObj = Get-CMCollection -Name $CollectionName

    # throw terminating error if no collection found with provided name
    if (!$collObj) {
        throw "No collection found with name: $CollectionName"
    }

    foreach($app in $apps) {
        New-CMApplicationDeployment -Name $app `
            -Collection $collObj `
            -DeployAction Install `
            -DeployPurpose Available |
            Out-Null
        # check if previous command succeeded
        if ($?) {
            Write-Host "$app successfully deployed to $CollectionName"
        } else {
            throw "$app failed to deploy to $CollectionName"
        }
    }
}