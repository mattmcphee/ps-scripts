function Add-SCCMDeviceToCollection {
    [CmdletBinding()]
    param (
        # ComputerName - the name of the computer you'd like to add
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        # CollectionName - the name of the collection to add to
        [Parameter(Mandatory)]
        [string]$CollectionName
    )

    begin {
        $ogLoc = Get-Location
        Set-Location "A00:"
    }

    process {
        foreach ($device in $ComputerName) {
            try {
                $deviceResourceId = (Get-CMDevice -Fast -Name $device -ErrorAction "Stop").ResourceId
            } catch {
                Set-Location $ogLoc
                throw "Encountered error: $_"
            }
    
            if ($null -eq $deviceResourceId) {
                Set-Location $ogLoc
                throw "'$device' could not be found."
            }
    
            try {
                Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $deviceResourceId -ErrorAction "Stop"
            } catch {
                Set-Location $ogLoc
                throw "Encountered error when adding '$device' to '$CollectionName': '$CollectionName' could not be found. $_"
            }
        }
    }

    end {
        Set-Location $ogLoc
    }
}
