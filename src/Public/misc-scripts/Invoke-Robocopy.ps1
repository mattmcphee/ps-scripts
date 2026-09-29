function Invoke-Robocopy {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('Source', 'FullName')]
        [string[]]$Path,

        [Parameter(Mandatory, Position = 1)]
        [string]$Destination,

        [ValidateRange(0, 100)]
        [int]$RetryCount = 2,

        [ValidateRange(0, 3600)]
        [int]$WaitSeconds = 2,

        [Parameter(Mandatory = $false)]
        [string[]]$RobocopyArgument
    )

    begin {
        $robocopy = Get-Command 'robocopy.exe' -ErrorAction Stop

        # destination doesn't have to exist yet.
        $destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
            $Destination
        )

        function Invoke-RobocopyCopy {
            param (
                [string]$SourceDirectory,
                [string]$DestinationDirectory,
                [string]$FileMask = '*'
            )

            $arguments = @(
                $SourceDirectory
                $DestinationDirectory
                $FileMask
                "/R:$RetryCount"
                "/W:$WaitSeconds"
                '/COPY:DAT'
                '/DCOPY:DAT'
                '/XJ'
                '/NP'
                '/E'
                '/S'
            )

            if ($RobocopyArgument) { $arguments += $RobocopyArgument }

            if ($PSCmdlet.ShouldProcess($DestinationDirectory, "robocopy '$SourceDirectory\$FileMask'")) {
                Write-Verbose ('robocopy.exe ' + ($arguments | ForEach-Object { '"{0}"' -f $_ }) -join ' ')

                $output = & $robocopy.Source @arguments 2>&1
                $exitCode = $LASTEXITCODE

                # robocopy exit codes 0-7 are considered successful.
                if ($exitCode -ge 8) {
                    $msg = $output -join [Environment]::NewLine

                    throw @"
robocopy failed with exit code $exitCode.

Source:      $SourceDirectory
Destination: $DestinationDirectory
File mask:   $FileMask

$msg
"@
                }

                [PSCustomObject]@{
                    Source      = $SourceDirectory
                    Destination = $DestinationDirectory
                    FileMask    = $FileMask
                    ExitCode    = $exitCode
                    Success     = $true
                }
            }
        }

        function Invoke-RobocopyLiteralItemCopy {
            param (
                [System.IO.FileSystemInfo]$item
            )

            if ($item.PSIsContainer) {
                # A literal directory includes the directory itself.
                #
                # C:\Data\Photos -> D:\Backup\Photos
                $targetDir = Join-Path $destination $item.Name

                Invoke-RobocopyCopy `
                    -SourceDirectory $item.FullName `
                    -DestinationDirectory $targetDir
            } else {
                # A literal file is copied into destination.
                #
                # C:\Data\File.txt -> D:\Backup\File.txt
                Invoke-RobocopyCopy `
                    -SourceDirectory $item.DirectoryName `
                    -DestinationDirectory $destination `
                    -FileMask $item.Name
            }
        }
    }

    process {
        foreach ($srcPath in $Path) {
            # Handle ** specially.
            # Supported:
            #   C:\Data\**
            #   C:\Data\**\*.txt
            $globStar = [regex]::Match(
                $srcPath,
                '^(?<Root>.*[\\/])\*\*(?:[\\/](?<Mask>[^\\/]+))?$'
            )

            if ($globStar.Success) {
                $root = $globStar.Groups['Root'].Value
                $mask = $globStar.Groups['Mask'].Value

                if ([string]::IsNullOrWhiteSpace($mask)) { $mask = '*' }

                if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters(
                        $root.TrimEnd('\', '/')
                    )
                ) { throw "Wildcards before '**' are not supported: $srcPath" }

                $rootItem = Get-Item -LiteralPath $root -Force -ErrorAction Stop

                if (-not $rootItem.PSIsContainer) {
                    throw "The path before '**' must be a directory: $root"
                }

                if ($mask -eq '*') {
                    # C:\Data\**
                    # Copy absolutely everything beneath C:\Data,
                    # including empty directories.
                    Invoke-RobocopyCopy `
                        -SourceDirectory $rootItem.FullName `
                        -DestinationDirectory $destination
                } else {
                    # C:\Data\**\*.txt
                    # Recursively copy matching files while preserving
                    # their relative directory structure.
                    Invoke-RobocopyCopy `
                        -SourceDirectory $rootItem.FullName `
                        -DestinationDirectory $destination `
                        -FileMask $mask
                }

                continue
            }

            # Normal PowerShell wildcard.
            # Example:
            #   C:\Data\*.txt
            #   C:\Data\Test*
            if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($srcPath)) {
                $parent = Split-Path -Path $srcPath -Parent

                if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($parent)) {
                    throw @"
Wildcards are only supported in the final part of the path.

Supported examples:
    C:\Data\*.txt
    C:\Data\Test*
    C:\Data\**
    C:\Data\**\*.txt
"@
                }

                $items = @(
                    Get-ChildItem -Path $srcPath -Force -ErrorAction Stop
                )

                if ($items.Count -eq 0) {
                    throw "No files or directories matched '$srcPath'."
                }

                foreach ($item in $items) {
                    Invoke-RobocopyLiteralItemCopy -Item $item
                }

                continue
            }

            # Normal literal file/directory.
            $item = Get-Item -LiteralPath $srcPath -Force -ErrorAction Stop
            Invoke-RobocopyLiteralItemCopy -Item $item
        }
    }
}
