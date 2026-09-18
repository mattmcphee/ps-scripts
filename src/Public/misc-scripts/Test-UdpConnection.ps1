function Test-UdpPort {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    Write-Host "Testing UDP port $Port on $ComputerName..."

    try {
        # Create a new UDP Client object
        $UdpClient = New-Object System.Net.Sockets.UdpClient

        # Set a short timeout for the check
        $UdpClient.Client.ReceiveTimeout = 2000  # 2 seconds

        # Attempt to connect (bind to the port)
        $UdpClient.Connect($ComputerName, $Port)
        
        Write-Host "UDP Port $Port on $ComputerName appears to be OPEN." -ForegroundColor Green
    } catch {
        Write-Host "UDP Port $Port on $ComputerName appears to be CLOSED or UNREACHABLE." -ForegroundColor Red
    } finally {
        # Clean up the object
        if ($UdpClient) { $UdpClient.Close() }
    }
}
