function ConvertTo-HexHResult {
    [CmdletBinding()]
    param (
        # Value - error code to convert to a hex result
        [Parameter(Mandatory)]
        $Value
    )

    try {
        $bytes = [BitConverter]::GetBytes([int32]$Value)
        $unsigned = [BitConverter]::ToUInt32($bytes, 0)

        return ('0x{0:X8}' -f $unsigned)
    } catch {
        throw $_
    }
}
