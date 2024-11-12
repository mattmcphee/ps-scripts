function Publish-MEMApplication {
    <#
    .SYNOPSIS
        Publish Applications to any Collection in Configuration Manager
    .DESCRIPTION
        Publish Applications to any Collection in Configuration Manager by using
        a fuzzy search for either Application Name or Publisher
    .PARAMETER ApplicationSearch
        Use to find applications named similar
    .PARAMETER PublisherSearch
        Use to find applications by publisher named similar
    .PARAMETER Purpose
        Type of deployment Forced (Required) or Available
    .INPUTS
        N/A
    .OUTPUTS
        N/A
    .NOTES
        Version:        1.0
        Author:         Bryan Bultitude
        Creation Date:  25/05/2022
        Purpose/Change: 25/05/2022 - Bryan Bultitude - Initial script development
        Purpose/Change: 27/08/2024 - Matt McPhee - added comments and restructured the script
    .EXAMPLE
        PS> Publish-MemApplication -ApplicationSearch CostX -Purpose Available
    .EXAMPLE
        PS> Publish-MemApplication -PublisherSearch ET -Purpose Required
    #>
    param(
        # ApplicationSearch
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationSearch,
        # PublisherSearch
        [Parameter(Mandatory=$true)]
        [string]
        $PublisherSearch,
        # Purpose
        [Parameter(Mandatory=$true)]
        [ValidateSet("Available", "Required")]
        [string]
        $Purpose
    )

    Import-MEMModule A00

    # set the deadline to 10pm tonight
    $DeadlineDateTime = (Get-Date -Hour 22 -Minute 00 -Second 00)
    # set the availabletime to 10pm last night
    $AvailableDateTime = $DeadlineDateTime.AddDays(-1)

    Write-Host "Importing all Device and User Collections" -ForegroundColor Cyan

    $Collections = @()

    # add device collections to collections array
    $Collections += Get-CMDeviceCollection | Select-Object Name, CollectionID, @{
        Name = "Collection Type";
        Expression = { "Device" }
    }

    # add user collections to collections array
    $Collections += Get-CMUserCollection | Select-Object Name, CollectionID, @{
        Name = "Collection Type";
        Expression = { "User" }
    }

    # applicationsearch argument is not empty and publishersearch argument is empty
    if ($ApplicationSearch -ne "" -and $PublisherSearch -eq "") {
        Write-Host "Getting list of Applications named like: $ApplicationSearch"`
            -ForegroundColor DarkGray

        # get list of applications using get-cmapplication
        # matching on localizeddisplayname
        # pass it to out-gridview to view data
        $Application = Get-CMApplication -Fast | Where-Object { 
            $_.LocalizedDisplayName -match $ApplicationSearch 
        } | Select-Object @{
            Name = "Name";
            Expression = { $_.LocalizedDisplayName }
        }, SoftwareVersion, Manufacturer |
            Sort-Object Manufacturer, LocalizedDisplayName, SoftwareVersion |
            Out-GridView -Title "Which Application is being deployed?" -PassThru
    # publishersearch argument is not empty and applicationsearch argument is empty
    } elseif ($PublisherSearch -ne "" -and $ApplicationSearch -eq "") {
        Write-Host "Getting list of Applications from Publishers named like: $PublisherSearch"`
            -ForegroundColor DarkGray

        # get list of applications using get-cmapplication
        # matching on localizeddisplayname
        # pass it to out-gridview to view data
        $Application = Get-CMApplication -Fast | Where-Object { 
            $_.Manufacturer -match $PublisherSearch
        } | Select-Object @{
            Name = "Name";
            Expression = { $_.LocalizedDisplayName }
        }, SoftwareVersion, Manufacturer | 
            Sort-Object Manufacturer,LocalizedDisplayName,SoftwareVersion | 
            Out-GridView -Title "Which Application is being deployed?" -PassThru
    # error if arguments are empty
    } else {
        Write-Host "Incorrect Action Selected" -ForegroundColor Red
    }

    # if there are applications in $application
    if ($Application -ne "") {
        # loop through each application
        foreach ($App in $Application) {
            # store the application name
            $ApplicationName = $App.Name

            Write-Host "Processing $($App.Name)"

            $Selection = $Collections | Sort-Object Name | `
                Out-GridView -Title "Deploy $($App.Name) to which Collections?" -PassThru
            
            if ($Selection -ne "") {
                foreach ($Coll in $Collections) {
                    if ($Coll.Name -ne "Applications for Workstations") {
                        Write-Host "Deploying to $($Coll.Name)" `
                            -ForegroundColor DarkGray

                        $Deployed = New-CMApplicationDeployment `
                            -CollectionId $Coll."Collection ID" `
                            -DeployAction Install `
                            -DeployPurpose $Purpose `
                            -Name $ApplicationName `
                            -UpdateSupersedence $true `
                            -AvailableDateTime $AvailableDateTime `
                            -DeadlineDateTime $DeadlineDateTime `
                            -TimeBaseOn LocalTime

                            Write-Host "Deployed $($Deployed.LocalizedDisplayName) to $($Coll.Name)" `
                            -ForegroundColor Green
                    } elseif ($Coll.Name -eq "Applications for Workstations") {
                        Write-Host "Deploying to $($Coll.Name) with Approval Required" `
                            -ForegroundColor DarkGray
                        
                        $Deployed = New-CMApplicationDeployment `
                            -CollectionId $Coll."Collection ID" `
                            -DeployAction Install `
                            -DeployPurpose Available `
                            -Name $ApplicationName `
                            -UpdateSupersedence $true `
                            -AvailableDateTime $AvailableDateTime `
                            -DeadlineDateTime $DeadlineDateTime `
                            -TimeBaseOn LocalTime `
                            -ApprovalRequired $true
                        
                        $str = "Deployed $($Deployed.LocalizedDisplayName)" + `
                            "to $($Coll.Name) with Approval Required"
                        Write-Host $str -ForegroundColor Green
                    }

                    $Selection = ""
                }
            } else { 
                throw "No collections selected" 
            }
        }
    } else { 
        throw "No applications selected" 
    }
}