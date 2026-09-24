function Get-RegistrySnapshotValue {
    [CmdletBinding()]
    param (
        # Snapshot - returned by Get-RegistrySnapshot function
        [Parameter(Mandatory,ValueFromPipeline)]
        [PSCustomObject]$Snapshot,

        # Name - name of the property whose value you wish to get
        [Parameter(Mandatory)]
        [string]$Name
    )

    begin {
        $results = [PSCustomObject]@{}
    }

    process {
        $propNames = $Snapshot.PSObject.Properties.Name
        foreach ($propName in $propNames) {
            if ($propName -like $Name) {
                $results | Add-Member -MemberType NoteProperty -Name $propName -Value $_.$propName
            }
        }
    }

    end {
        $results
    }
}
