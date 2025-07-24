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
        [Parameter(Mandatory=$false)]
        [string]
        $SMBiosGuid
    )

    $OsdPromptCollectionId = "A000005E"

    if ($SMBiosGuid) {
        Import-CMComputerInformation -ComputerName $ComputerName `
            -MacAddress $MacAddress `
            -CollectionId $OsdPromptCollectionId `
            -SMBiosGuid $SMBiosGuid
    } else {
        Import-CMComputerInformation -ComputerName $ComputerName `
            -MacAddress $MacAddress `
            -CollectionId $OsdPromptCollectionId
    }
}
