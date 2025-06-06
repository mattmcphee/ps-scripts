function Test-Function {
    [CmdletBinding()]
    param (
        # Name
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]
        $Name
    )

    begin {
        Write-Host "----------"
        Write-Host "BEGIN BLOCK"
        Write-Host "----------"
    }

    process {
        Write-Host $Name
    }

    end {
        Write-Host "----------"
        Write-Host "END BLOCK"
        Write-Host "----------"
    }
}
