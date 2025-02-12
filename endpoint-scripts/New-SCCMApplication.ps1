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
        $IconPath
    )

    Set-Location -Path 'A00:\'

    $appArgs = @{
        Owner = $Owner
        SupportContact = $Owner
        DefaultLanguageId = 3081 # en-AU
        Description = $Description
        IconLocationFile = $IconPath
        LocalizedDescription = $Description
        LocalizedName = $ApplicationName
        Name = $ApplicationName
        Publisher = $Publisher
        SoftwareVersion = $Version
    }
    New-CMApplication @appArgs -ErrorAction Stop

    $app = Get-CMApplication -Name $ApplicationName

    if (-not(Test-Path -Path ".\Application\$Publisher")) {
        New-CMFolder -Name $Publisher -ParentFolderPath '.\Application'
    }

    $app | Move-CMObject -FolderPath ".\Application\$Publisher" -ErrorAction Stop
}
