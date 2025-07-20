function Set-NoBMDProfile {
    Rename-Item -Path "$env:USERPROFILE\Documents\PowerShell\profile.ps1" -NewName "profileBMD.ps1"
    Rename-Item -Path "$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1" -NewName "profileBMD.ps1"
}
