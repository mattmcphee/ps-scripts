function Add-CompToADGroup {
  [CmdletBinding()]
  param (
    # Identity of computer
    [Parameter(Mandatory)]
    [string]
    $ComputerName,
    # Group to add user to - will use wildcards to search if asterisks entered
    [Parameter(Mandatory)]
    [string]
    $Group
  )

  try {
    $ADComputer = Get-ADComputer -Identity $ComputerName
  } catch {
    Write-Host "Could not find a computer with that identity." -ForegroundColor Red
    break
  }

  #-SearchBase 'OU=au_groups,OU=Locations,DC=bmd,DC=com,DC=au'
  $ADGroup = Get-ADGroup -Filter {Name -like $Group} | Select-Object Name
  if ($ADGroup.Count -eq 0) {
    Write-Host "`nNo groups found matching that name. Try using wildcards.`n" -ForegroundColor Red
  } elseif ($ADGroup.Count -gt 1) {
    Write-Host "`nFound multiple groups, be more specific:`n" -ForegroundColor Red
    $ADGroup
  } else {
    Add-ADGroupMember -Identity $ADGroup.Name -Members $ADComputer
    Write-Host
    $successMsg = "$($ADComputer.Name) added to $($ADgroup.Name)"
    Write-Host $successMsg
    Set-Clipboard $successMsg
  }
}
