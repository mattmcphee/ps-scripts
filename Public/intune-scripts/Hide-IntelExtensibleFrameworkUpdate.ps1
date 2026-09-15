function Hide-IntelExtensibleFrameworkUpdate {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )

    foreach ($computer in $ComputerName) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $script = @'
$UpdateSession  = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$Updates = @($UpdateSearcher.Search("IsHidden=0").Updates)

foreach ($u in $Updates) {
    if ($u.Title -like "*Intel*Extension*2.1.10103.24*") {
        $u.IsHidden = $true
    }
}
'@

            # Encode the script so we don't have to fight quoting
            $Bytes   = [Text.Encoding]::Unicode.GetBytes($Script)
            $Encoded = [Convert]::ToBase64String($Bytes)

            $Action = New-ScheduledTaskAction `
                -Execute 'powershell.exe' `
                -Argument "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $Encoded"

            $Principal = New-ScheduledTaskPrincipal `
                -UserId 'SYSTEM' `
                -LogonType ServiceAccount `
                -RunLevel Highest

            $null = Register-ScheduledTask `
                -TaskName 'HideIntelUpdate' `
                -Action $Action `
                -Principal $Principal `
                -Force

            Start-ScheduledTask -TaskName 'HideIntelUpdate'
        }
    }
}
