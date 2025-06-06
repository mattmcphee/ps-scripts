function Open-CMLog {
    param (
        # ComputerName
        [Parameter()]
        [string]
        $ComputerName,
        # Path
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    # edit string to use UNC
    $Path.replace(":","$")

    # process path
    $process = "C:\Program Files\CMTrace\CMTrace.exe"

    # log file to open
    Start-Process -FilePath $process -ArgumentList "\\$ComputerName\$Path"
}
