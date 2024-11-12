function Get-LastLogonUser {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [string]
      $ComputerName
  )

  Get-CMDevice -Name $ComputerName | Select-Object lastlogonuser,lastsoftwarescan
}

function Get-UserDeptAndJobTitle {
  [CmdletBinding()]
  param (
      [Parameter()]
      [string]
      $Identity
  )

  $user = Get-ADUser -Identity $Identity -Properties displayname,department,title | 
    Select-Object displayname,department,title

  $DepartmentCSV = "\\bmd\bmdapps\BI\JamesG\departments.csv"

  $Depts = Import-Csv -Path $DepartmentCSV

  $DeptsHash = @{}
  
  foreach ($r in $Depts) {
    $DeptsHash[$r.DepartmentID] = $r.Department
  }
  $userdn = $user.displayname
  $userJobTitle = $user.title
  $userDepartment = $DeptsHash[$user.department]

  $output = "In possession of $userdn, $userJobTitle for $userDepartment"
  $output | clip
  Write-Host $output
}

