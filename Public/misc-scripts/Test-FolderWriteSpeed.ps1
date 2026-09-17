function Test-FolderWriteSpeed {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [int]$SizeMB = 100
    )

    $TestFile = Join-Path $Path "SpeedTest_$([guid]::NewGuid()).tmp"
    $Buffer   = New-Object byte[] (1MB)
    $Watch    = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $Stream = [System.IO.File]::Create($TestFile)

        for ($i = 0; $i -lt $SizeMB; $i++) {
            $Stream.Write($Buffer, 0, $Buffer.Length)
        }

        $Stream.Flush()
        $Stream.Close()

        $Watch.Stop()

        [pscustomobject]@{
            Path     = $Path
            SizeMB   = $SizeMB
            Seconds  = [math]::Round($Watch.Elapsed.TotalSeconds, 2)
            'MB/s'     = [math]::Round($SizeMB / $Watch.Elapsed.TotalSeconds, 2)
        }
    }
    finally {
        if ($Stream) {
            $Stream.Dispose()
        }

        Remove-Item $TestFile -Force -ErrorAction SilentlyContinue
    }
}
