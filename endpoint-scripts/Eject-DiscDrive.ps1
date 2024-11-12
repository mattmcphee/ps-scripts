function Eject-DiscDrive {
    param (
        [string[]]$computerName = $env:COMPUTERNAME
    )

    foreach ($computer in $computerName) {
        if ($computer -eq $env:COMPUTERNAME) {
            $sh = New-Object -ComObject "Shell.Application"
            $items = $sh.namespace(17).Items()
            foreach ($item in $items) {
                if ($item.type -eq "CD Drive") {
                    $item.InvokeVerb("Eject")
                }
            }
        } else {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                $sh = New-Object -ComObject "Shell.Application"
                $items = $sh.namespace(17).Items()
                foreach ($item in $items) {
                    if ($item.type -eq "CD Drive") {
                        $item.InvokeVerb("Eject")
                    }
                }
            }
        }
    }
}

