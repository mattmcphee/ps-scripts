for ($i = 1; $i -lt 100; $i++) {
    Write-Progress -Activity "testing" -Status "hey" -PercentComplete $i
    Start-Sleep -Milliseconds 100
}