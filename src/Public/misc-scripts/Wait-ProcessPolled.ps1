function Wait-ProcessPolled {
    [CmdletBinding()]
    param (
        # ProcessName - process to wait for
        [Parameter(Mandatory)]
        [string]
        $ProcessName,
        # MaxAttempts - number of times to poll the process
        [Parameter(Mandatory)]
        [ValidateRange("Positive")]
        [int]
        $MaxAttempts,
        # WaitSeconds - seconds to wait between polling
        [Parameter(Mandatory)]
        [ValidateRange("Positive")]
        [int]
        $WaitSeconds,
        # LogPath - path to write logs to. This is mandatory because this function is specifically to be used with no-touch scripts.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                $dir = Split-Path $_ -Parent
                if (Test-Path $dir) {
                    return $true
                } else {
                    throw "LogPath: The folder path '$dir' does not exist."
                }
            })]
        [string]
        $LogPath
    )

    $curAttempts = 0
    while ($curAttempts -lt $MaxAttempts) {
        $curAttempts++
        try {
            $proc = Get-Process -Name $ProcessName
            if ($proc) {
                $msg = "$ProcessName is still running. Waiting $waitSecs seconds. This is attempt $curAttempts out of $maxAttempts."
                Write-Log -Message $msg -Level Info -Path $LogPath
            }
        } catch {
            Write-Log "Process not found. Proceeding..." -Level Info -Path $LogPath
            break
        }
        Start-Sleep -Seconds $waitSecs
    }
}
