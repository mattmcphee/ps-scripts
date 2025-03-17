function New-SCCMApplication {
    param (
        # ApplicationName
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationName,
        # Publisher
        [Parameter(Mandatory=$true)]
        [string]
        $Publisher,
        # Version
        [Parameter(Mandatory=$true)]
        [string]
        $Version,
        # Owner
        [Parameter(Mandatory=$true)]
        [string]
        $Owner,
        # Description
        [Parameter(Mandatory=$true)]
        [string]
        $Description,
        # IconPath - path to icon file on network drive
        [Parameter(Mandatory=$true)]
        [string]
        $IconPath,
        # ContentLocation - path to content on network drive
        [Parameter(Mandatory=$true)]
        [string]
        $ContentLocation,
        # Uninstall content location
        [Parameter(Mandatory=$false)]
        [string]
        $UninstallContentLocation,
        # Free space required (MB)
        [Parameter(Mandatory=$true)]
        [string]
        $SpaceRequired,
        # Folder where application gets installed
        [Parameter(Mandatory=$true)]
        [string]
        $InstallFolder,
        # Name of the installed file, including file extension
        [Parameter(Mandatory=$true)]
        [string]
        $InstalledFile,
        # is64bit - whether or not the application is 64bit
        [Parameter(Mandatory=$false)]
        [switch]
        $Is64Bit,
        # Max run time
        [Parameter(Mandatory=$true)]
        [string]
        $MaxRunTime,
        # Estimated run time
        [Parameter(Mandatory=$true)]
        [string]
        $EstimatedRunTime
    )

    Set-Location -Path 'A00:\'

    # if app doesn't exist, create it
    if (-not(Get-CMApplication -Name $ApplicationName -Fast)) {
        New-CMApplication `
            -Owner $Owner `
            -SupportContact $Owner `
            -DefaultLanguageId 3081 <# en-AU #> `
            -IconLocationFile $IconPath `
            -LocalizedDescription $Description `
            -LocalizedName $ApplicationName `
            -Name $ApplicationName `
            -Publisher $Publisher `
            -SoftwareVersion $Version
    }

    $app = Get-CMApplication -Name $ApplicationName

    # if publisher folder doesn't exist, create it
    if (-not(Test-Path -Path ".\Application\$Publisher")) {
        New-CMFolder -Name $Publisher -ParentFolderPath '.\Application'
    }

    # move app into folder
    $app | Move-CMObject -FolderPath ".\Application\$Publisher"

    # create requirement rules
    $freeSpaceRule = Get-CMGlobalCondition -Name "Free disk space" |
        New-CMRequirementRuleFreeDiskSpaceValue `
            -PartitionOption 'System' `
            -RuleOperator 'GreaterThan' `
            -Value1 $SpaceRequired
    $x64Rule = Get-CMGlobalCondition -Name "Supported Workstation OS x64" |
        New-CMRequirementRuleBooleanValue -Value $true

    # check to see if application has deployment type
    # if app has no deployment types, create one
    if ($app.NumberOfDeploymentTypes -lt 1) {
        if ($Is64Bit) {
            $fileDetClause = New-CMDetectionClauseFile `
            -FileName $InstalledFile `
            -Path $InstallFolder `
            -Existence `
            -Is64Bit
        } else {
            $fileDetClause = New-CMDetectionClauseFile `
            -FileName $InstalledFile `
            -Path $InstallFolder `
            -Existence
        }

        # if uninstall location has been provided then set the uninstall
        # if not then set same for install and uninstall
        if ($UninstallContentLocation) {
            Add-CMScriptDeploymentType `
            -DeploymentTypeName $ApplicationName `
            -ApplicationName $ApplicationName `
            -InstallationBehaviorType 'InstallForSystem' `
            -LogonRequirementType 'WhetherOrNotUserLoggedOn' `
            -MaximumRuntimeMins $MaxRunTime `
            -EstimatedRuntimeMins $EstimatedRunTime `
            -AddRequirement @($freeSpaceRule,$x64Rule) `
            -ContentLocation $ContentLocation `
            -UninstallOption 'Different' `
            -UninstallContentLocation $UninstallContentLocation `
            -InstallCommand "Deploy-Application.exe -AllowRebootPassThru -DeploymentType 'Install'" `
            -UninstallCommand "Deploy-Application.exe -AllowRebootPassThru -DeploymentType 'Uninstall'" `
            -AddDetectionClause $fileDetClause
        } else {
            Add-CMScriptDeploymentType `
            -DeploymentTypeName $ApplicationName `
            -ApplicationName $ApplicationName `
            -InstallationBehaviorType 'InstallForSystem' `
            -LogonRequirementType 'WhetherOrNotUserLoggedOn' `
            -MaximumRuntimeMins $MaxRunTime `
            -EstimatedRuntimeMins $EstimatedRunTime `
            -AddRequirement @($freeSpaceRule,$x64Rule) `
            -ContentLocation $ContentLocation `
            -InstallCommand "Deploy-Application.exe -AllowRebootPassThru -DeploymentType 'Install'" `
            -UninstallCommand "Deploy-Application.exe -AllowRebootPassThru -DeploymentType 'Uninstall'" `
            -AddDetectionClause $fileDetClause
        }
    } else {
        # app already has deployment types, let's exit
        throw -Message "This app already has at least one deployment type. Exiting..."
    }
}
