function Import-VMToSCCM {
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # MacAddress
        [Parameter(Mandatory)]
        [string]
        $MacAddress,
        # SMBiosGuid
        [Parameter(Mandatory)]
        [string]
        $SMBiosGuid
    )

    $OsdPromptCollectionId = "A000005E"

    Import-CMComputerInformation -ComputerName $ComputerName `
        -MacAddress $MacAddress `
        -SMBiosGuid $SMBiosGuid `
        -CollectionId $OsdPromptCollectionId
}
