function ConvertTo-RegistryPath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # Path - registry path input
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]]$Path
    )

    begin {
        $hiveMap = @{
            HKLM = 'HKEY_LOCAL_MACHINE'
            HKCU = 'HKEY_CURRENT_USER'
            HKU  = 'HKEY_USERS'
        }
    }

    process {
        $path = $Path.Trim()

        if ($path -like "Registry::*") {
            $path = $path.Substring(10)
        }

        $path = $path -replace ':',''

        $hive,$subkey = $path -split '\\', 2

        if ($hiveMap.ContainsKey($hive.ToUpperInvariant())) {
            $hive = $hiveMap[$hive.ToUpperInvariant()]
        } elseif ($hive -notmatch '^HKEY_(LOCAL_MACHINE|CURRENT_USER|USERS)$') {
            throw "'$Path' is not a valid registry path. $_"
        }

        if ($subkey) {
            return "Registry::$hive\$subkey"
        }

        return "Registry::$hive"
    }
}
