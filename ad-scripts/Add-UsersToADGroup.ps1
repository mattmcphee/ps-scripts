function Add-UsersToADGroup {
  [CmdletBinding()]
  param (
    # Identity of user or users separated by commas
    [Parameter(Mandatory)]
    [string[]]
    $Users,
    # Group to add user to - will use wildcards to search if asterisks entered
    [Parameter(Mandatory)]
    [string]
    $Group
  )
  
  $ADGroup = Get-ADGroup -Filter {Name -like $Group} | Select-Object Name

  if ($ADGroup.Count -eq 0) {
    Write-Host "`nNo groups found matching that name. Try using wildcards.`n" -ForegroundColor Red
  } elseif ($ADGroup.Count -gt 1) {
    Write-Host "`nFound multiple groups, be more specific:`n" -ForegroundColor Red
    $ADGroup
  } else {
    $sb = [System.Text.StringBuilder]::new()
    foreach ($User in $Users) {
      $ADUser = Get-ADUser -Filter {SamAccountName -like $User}
      if ($ADUser.Count -eq 0) {
        throw "Could not find a user with identity: $User"
      } elseif ($ADUser.Count -gt 1) {
        Write-Host "`nFound multiple users, be more specific.`n" -ForegroundColor Red
        $ADUser.Name
        Write-Host
        throw "Found multiple users, be more specific."
      } else {
        Add-ADGroupMember -Identity $ADGroup.Name -Members $ADUser
        $successMsg = "$($ADUser.SamAccountName) added to $($ADgroup.Name)"
        Write-Host $successMsg
        $sb.AppendLine($successMsg) | Out-Null
      }
    }
    Set-Clipboard $sb.ToString()
  }
}