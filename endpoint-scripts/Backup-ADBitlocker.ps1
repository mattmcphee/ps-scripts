function Backup-ADBitlocker {
    # use get-bitlockervolume to get the keyprotectorid for the bitlocker
    # recovery password
    $blv = Get-BitlockerVolume -MountPoint 'C:' |
        Select-Object -ExpandProperty KeyProtector |
        Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
    $id = $blv.KeyProtectorId
    # use manage-bde to upload the current bitlocker password to AD
    manage-bde -protectors -adbackup C: -id $id
}