function New-ScriptFiles {
    param (
        # Path
        [Parameter(Mandatory)]
        [string]
        $Path,
        # NumberOfScripts
        [Parameter(Mandatory)]
        [int]
        $NumberOfScripts
    )

    for ($i = 0; $i -lt $NumberOfScripts; $i++) {
        $randomFileName = "example-script{0}.ps1" -f (Get-Random -Minimum 1 -Maximum 999999)

        $filePath = "$Path\$randomFileName"

        New-Item -Path $filePath -ItemType File -Force

        Set-Content -Path $filePath -Value $filePath
    }
}
