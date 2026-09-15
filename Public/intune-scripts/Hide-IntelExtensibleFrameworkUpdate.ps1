function Hide-IntelExtensibleFrameworkUpdate {
    $UpdateSession  = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $Updates = @($UpdateSearcher.Search("IsHidden=0").Updates)

    foreach ($u in $Updates) {
        if ($u.Title -like "*Intel*Extension*2.1.10103.24*") {
            $u.IsHidden = $true
        }
    }
}
