param(
    # install type install or uninstall
    [switch]
    $Type
)
switch($Type) {
    Install {
        Write-Host "Script executed install."
    }
    Uninstall {
        Write-Host "Script executed uninstall."
    }
}