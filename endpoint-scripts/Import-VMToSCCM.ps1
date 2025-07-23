function Import-VMToSCCM {
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # MacAddress
        [Parameter(Mandatory)]
        [string]
        $MacAddress
    )

    $OsdPromptCollectionId = "A000005E"

    Import-CMComputerInformation -ComputerName $ComputerName `
        -MacAddress $MacAddress `
        -CollectionId $OsdPromptCollectionId
}
