function Set-NewWinServer {
    [CmdletBinding()]
    param (
        # IPAddress
        [Parameter(Mandatory)]
        [string]
        $IPAddress,
        # DNSServerOne
        [Parameter(Mandatory)]
        [string]
        $DNSServerOne,
        # DNSServerTwo
        [Parameter(Mandatory)]
        [string]
        $DNSServerTwo
    )

    $interfaceAlias = "Ethernet"
    $prefixLength = 24
    $defaultGateway = "10.97.105.254"
    $dnsServers = @($DNSServerOne, $DNSServerTwo)

    if (-not ([System.Net.IPAddress]::TryParse($IPAddress, [ref]$null))) {
        throw "Invalid IPAddress: $IPAddress"
    }

    if (-not ([System.Net.IPAddress]::TryParse($DNSServerOne, [ref]$null))) {
        throw "Invalid IPAddress: $DNSServerOne"
    }

    if (-not ([System.Net.IPAddress]::TryParse($DNSServerTwo, [ref]$null))) {
        throw "Invalid IPAddress: $DNSServerTwo"
    }

    # set ip address
    New-NetIPAddress -InterfaceAlias $interfaceAlias `
        -IPAddress $IPAddress `
        -PrefixLength $prefixLength `
        -DefaultGateway $defaultGateway

    # set dns servers
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $dnsServers
}
