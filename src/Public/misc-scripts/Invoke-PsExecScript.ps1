function Invoke-PsExecScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Leaf)) {
                throw "Script file does not exist: $_"
            }

            if ([System.IO.Path]::GetExtension($_) -ne '.ps1') {
                throw "File must be a PowerShell .ps1 script."
            }

            $true
        })]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory=$false)]
        [string]$PsExecPath = 'C:\sources\staging\PSTools\PsExec.exe',

        [Parameter(Mandatory=$false)]
        [switch]$KeepRemoteScript
    )

    $scriptPath = (Resolve-Path $Path).Path

    foreach ($Computer in $ComputerName) {
        $fileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
        $fileName = '{0}_{1}.ps1' -f $fileNameNoExt, [guid]::NewGuid().ToString('N')

        $remoteDirectory = "\\$Computer\C$\ProgramData\BMD\PsExec"
        $remoteUNCPath   = Join-Path $remoteDirectory $fileName
        $remoteLocalPath = "C:\ProgramData\BMD\PsExec\$fileName"

        try {
            # Create temporary directory on remote machine
            if (-not (Test-Path $remoteDirectory)) {
                New-Item `
                    -Path $remoteDirectory `
                    -ItemType Directory `
                    -Force `
                    -ErrorAction Stop |
                    Out-Null
            }

            # Copy script to remote machine
            Copy-Item `
                -Path $scriptPath `
                -Destination $remoteUNCPath `
                -Force `
                -ErrorAction Stop

            # Build PsExec arguments
            $psExecArgs = @(
                "\\$Computer"
                '-accepteula'
                '-nobanner'
                '-s'
            )

            $psExecArgs += @(
                'powershell.exe'
                '-NoProfile'
                '-ExecutionPolicy'
                'Bypass'
                '-File'
                $remoteLocalPath
            )

            if ($ArgumentList) {
                $psExecArgs += $ArgumentList
            }

            Write-Verbose "Running $Path on $Computer"

            & $PsExecPath @psExecArgs

            $exitCode = $LASTEXITCODE

            [pscustomobject]@{
                ComputerName = $Computer
                Script       = $scriptPath
                exitCode     = $exitCode
                Success      = ($exitCode -eq 0)
            }
        } catch {
            Write-Error "Failed to run script on $Computer : $_"
        } finally {
            if (-not $KeepRemoteScript) {
                Remove-Item `
                    -Path $remoteUNCPath `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }
}
