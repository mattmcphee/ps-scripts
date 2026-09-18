# ============================================================================
# GENERATED FILE - DO NOT EDIT
# Run .\build.ps1 to regenerate this file from .\src
# This file was built on 18-Sept-2026 13:02:53
# ============================================================================

#region Add-CompToADGroup.ps1
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

#endregion

#region Add-UsersToADGroup.ps1
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

#endregion

#region Compare-ComputersADGroups.ps1
function Compare-ComputersADGroups {
    [CmdletBinding()]
    param (
        # First object to compare
        [Parameter(Mandatory)]
        [string]
        $ADComputer1,
        # Second object to compare
        [Parameter(Mandatory)]
        [string]
        $ADComputer2
    )

    # CN=bne_it_gs,OU=Level 2 - Access - General,OU=au_groups,OU=Locations,DC=bmd,DC=com,DC=au

    $ADGroups1 = (Get-ADComputer $ADComputer1 -Properties MemberOf).MemberOf
    $formattedList1 = [System.Collections.ArrayList]::new()
    $ADGroups1 | ForEach-Object {
        $splitString = $_.split(",")
        $CNItem = $splitString[0]
        $groupName = $CNItem.SubString(3)
        $formattedList1.add($groupName) | Out-Null
    }

    $ADGroups2 = (Get-ADComputer $ADComputer2 -Properties MemberOf).MemberOf
    $formattedList2 = [System.Collections.ArrayList]::new()
    $ADGroups2 | ForEach-Object {
        $splitString = $_.split(",")
        $CNItem = $splitString[0]
        $groupName = $CNItem.SubString(3)
        $formattedList2.add($groupName) | Out-Null
    }

    $duplicates = [System.Collections.ArrayList]::new()
    $ADComputer1Uniques = [System.Collections.ArrayList]::new()
    $ADComputer2Uniques = [System.Collections.ArrayList]::new()

    foreach ($group in $formattedList1) {
        if ($formattedList2.Contains($group)) {
            $duplicates.add($group) | Out-Null
        }
        else {
            $ADComputer1Uniques.add($group) | Out-Null
        }
    }

    foreach ($group in $formattedList2) {
        if (-not $formattedList1.Contains($group)) {
            $ADComputer2Uniques.Add($group) | Out-Null
        }
    }

    Write-Host "`nBoth users are in these groups:" -ForegroundColor Green
    foreach ($group in $duplicates) {
        Write-Host $group
    }

    Write-Host "`n$ADComputer1 is in these unique groups:" -ForegroundColor Green
    foreach ($group in $ADComputer1Uniques) {
        Write-Host $group
    }

    Write-Host "`n$ADComputer2 is in these unique groups:" -ForegroundColor Green
    foreach ($group in $ADComputer2Uniques) {
        Write-Host $group
    }
}

#endregion

#region Compare-UsersADGroups.ps1
function Compare-UsersADGroups {
    [CmdletBinding()]
    param (
        # First object to compare
        [Parameter(Mandatory)]
        [string]
        $ADUser1,
        # Second object to compare
        [Parameter(Mandatory)]
        [string]
        $ADUser2
    )

    # CN=bne_it_gs,OU=Level 2 - Access - General,OU=au_groups,OU=Locations,DC=bmd,DC=com,DC=au

    $ADGroups1 = (Get-ADUser $ADUser1 -Properties MemberOf).MemberOf
    $formattedList1 = [System.Collections.ArrayList]::new()
    $ADGroups1 | ForEach-Object {
        $splitString = $_.split(",")
        $CNItem = $splitString[0]
        $groupName = $CNItem.SubString(3)
        $formattedList1.add($groupName) | Out-Null
    }

    $ADGroups2 = (Get-ADuser $ADUser2 -Properties MemberOf).MemberOf
    $formattedList2 = [System.Collections.ArrayList]::new()
    $ADGroups2 | ForEach-Object {
        $splitString = $_.split(",")
        $CNItem = $splitString[0]
        $groupName = $CNItem.SubString(3)
        $formattedList2.add($groupName) | Out-Null
    }

    $duplicates = [System.Collections.ArrayList]::new()
    $ADUser1Uniques = [System.Collections.ArrayList]::new()
    $ADUser2Uniques = [System.Collections.ArrayList]::new()

    foreach ($group in $formattedList1) {
        if ($formattedList2.Contains($group)) {
            $duplicates.add($group) | Out-Null
        }
        else {
            $ADUser1Uniques.add($group) | Out-Null
        }
    }

    foreach ($group in $formattedList2) {
        if (-not $formattedList1.Contains($group)) {
            $ADUser2Uniques.Add($group) | Out-Null
        }
    }

    Write-Host "`nBoth users are in these groups:" -ForegroundColor Green
    foreach ($group in $duplicates) {
        Write-Host $group
    }

    Write-Host "`n$ADUser1 is in these unique groups:" -ForegroundColor Green
    foreach ($group in $ADUser1Uniques) {
        Write-Host $group
    }

    Write-Host "`n$ADUser2 is in these unique groups:" -ForegroundColor Green
    foreach ($group in $ADUser2Uniques) {
        Write-Host $group
    }
}

#endregion

#region Get-ADComputerMembership.ps1
function Get-ADComputerMembership {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )
    
    try {
        Get-ADComputer -Identity $ComputerName -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    } catch {
        throw $_
    }
}

#endregion

#region Get-ADGroupMemberInfo.ps1
function Get-ADGroupMemberInfo {
    param (
        # GroupName
        [Parameter(Mandatory = $true)]
        [string]
        $GroupName
    )

    $memberList = @()

    $members = Get-ADGroupMember -Identity $GroupName

    foreach ($member in $members) {
        $memberInfo = [PSCustomObject]@{
            Name           = $member.Name
            ObjectClass    = $member.ObjectClass
            SamAccountName = $member.SamAccountName
            ParentGroup    = $GroupName
        }

        $memberList += $memberInfo

        if ($member.ObjectClass -eq 'group') {
            Get-ADGroupMemberInfo -GroupName $member.Name
        }
    }

    $memberList | Select-Object ObjectClass, Name, SamAccountName, ParentGroup
}

#endregion

#region Get-ADUserMembership.ps1
function Get-ADUserMembership {
    [CmdletBinding()]
    param (
        # Username
        [Parameter(Mandatory)]
        [string]
        $Username
    )
    
    try {
        Get-ADUser -Identity $Username -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    } catch {
        throw $_
    }
}

#endregion

#region Add-CodeSignature.ps1
<#
.SYNOPSIS
Gets scripts using Get-ChildItem to get files with ps1 extension in a specified
folder then signs scripts using a codesigning certificate.

.PARAMETER Path
The path to a .ps1 script or folder containing .ps1 scripts.

.PARAMETER Thumbprint
The thumbprint of the codesigning certificate to use to sign the script(s).

.PARAMETER Recurse
This switch will recursively search folders when looking for scripts to sign.

.INPUTS
[string]
File paths to a script file or a folder containing scripts can be piped to this function.
[object]
An object with a FullName property (e.g. objects from Get-ChildItem) can be piped to this function.

.OUTPUTS
N/A

.EXAMPLE
PS> Add-CodeSignature -Path "C:\sources\repos\example-script.ps1"

.EXAMPLE
PS> Add-CodeSignature -Path "C:\sources\repos\WDAC" -Recurse

.EXAMPLE
PS> Add-CodeSignature -Path "C:\sources\repos\example-script.ps1" -Thumbprint "abcdefg"

.EXAMPLE
PS> Get-ChildItem -Path "C:\wdac\Example-Scripts.ps1" | Add-CodeSignature

.NOTES
Author:     Matt McPhee
Version:    1.1
Created:    13/09/2025
Updated:    23/07/2025
#>
function Add-CodeSignature {
    [CmdletBinding()]
    param (
        # Path - script or folder containing scripts you wish to sign
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({ Test-Path -Path $_ })]
        [Alias("FullName")]
        [string]
        $Path,
        # Thumbprint - thumbprint of a certificate
        [Parameter(Mandatory=$false)]
        [string]
        $Thumbprint,
        # Recurse - recurse through folders when looking for scripts to sign
        [Parameter(Mandatory=$false)]
        [switch]
        $Recurse
    )

    begin {
        # retrieve codesigning cert
        # we select the certificate based on the extension format starting with desired template name
        # then if we find multiple certs, sort based on expiry date and select the one with latest expiry
        if ($Thumbprint) {
            $cert = Get-ChildItem -Path "Cert:\" -Recurse | Where-Object { $_.Thumbprint -eq $Thumbprint }
        } else {
            $cert = Get-ChildItem -Path "Cert:\CurrentUser\My" |
                Where-Object { $_.Extensions.Format(0)[0].StartsWith("Template=Code Signing - 3 Year Validity") } |
                Sort-Object -Property NotAfter -Descending |
                Select-Object -First 1
        }

        # throw error if no codesigning cert found
        if ($cert.Count -eq 0) {
            throw "Unable to find CodeSigning certificate."
        }

        # set up empty array to hold found scripts
        $allScripts = @()
    }

    process {
        # get scripts for each path that comes down the pipe
        if ($Recurse) {
            $scripts = Get-ChildItem -Path $Path -Include '*.ps1' -Recurse -ErrorAction Stop
        } else {
            $scripts = Get-ChildItem -Path $Path -Include '*.ps1' -ErrorAction Stop
        }

        # add scripts to array
        $allScripts += $scripts
    }

    end {
        # throw error if no scripts found
        if ($allScripts.Count -eq 0) {
            throw "No script files found in provided path(s)."
        }

        Write-Verbose "Found $($allScripts.Count) scripts to sign."

        # loop through and sign each script found
        # use multithreading if ps7+
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $allScripts | ForEach-Object -Parallel {
                $cert = $using:cert

                try {
                    Set-AuthenticodeSignature -Certificate $cert `
                        -FilePath $_.FullName `
                        -TimestampServer 'http://timestamp.digicert.com' `
                        -ErrorAction 'Stop'

                    Write-Verbose "Successfully signed: $($_.Name)"
                } catch {
                    Write-Error "Failed to sign $($_.Name): $_"
                }
            }
        } else {
            for ($i = 0; $i -lt $allScripts.Count; $i++) {
                Write-Progress -Activity "Signing scripts..." `
                    -Status "Processing $($allScripts[$i].Name)" `
                    -PercentComplete (($i / $allScripts.Count) * 100)

                try {
                    Set-AuthenticodeSignature -Certificate $cert `
                        -FilePath $allScripts[$i].FullName `
                        -TimestampServer 'http://timestamp.digicert.com' `
                        -ErrorAction 'Stop'

                    Write-Verbose "Successfully signed: $($allScripts[$i].Name)"
                } catch {
                    Write-Error "Failed to sign $($allScripts[$i].Name): $_"
                }
            }
        }
    }
}

#endregion

#region Backup-ADBitlocker.ps1
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

#endregion

#region Clear-SoftwareDistributionFolder.ps1
function Clear-SoftwareDistributionFolder {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        try {
            # 1. Stop the Windows Update and BITS services
            Write-Host "Stopping Windows Update Services..."
            Stop-Service -Name "wuauserv" -Force
            Stop-Service -Name "bits" -Force

            # 2. Rename the SoftwareDistribution folder to clear the path
            # This is safer than directly deleting, as Windows will recreate a new, empty one.
            $SoftwareDistributionPath = "C:\Windows\SoftwareDistribution"
            $NewPath = "C:\Windows\SoftwareDistribution.old"

            if (Test-Path $SoftwareDistributionPath) {
                Write-Host "Renaming SoftwareDistribution folder..."
                Rename-Item -Path $SoftwareDistributionPath -NewName $NewPath -Force
            }
    
            # 3. Start the services again
            Write-Host "Starting Windows Update Services..."
            Start-Service -Name "wuauserv" -Passthru
            Start-Service -Name "bits" -Passthru

            # Optional: Delete the old folder after services are started and it's confirmed clear
            # This step might take a few minutes for the system to release all locks.
            Write-Host "Deleting old SoftwareDistribution folder..."
            Remove-Item -Path $NewPath -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            throw $_
        }
    }
}

#endregion

#region Compare-ADBitLockerToActualBitLocker.ps1
<#
.SYNOPSIS
    Gets a list of computers then compares the computer's actual BitLocker key to
    the key listed in ActiveDirectory.
    Uses ADComputer object information and information from Get-BitLockerVolume
    to compare.
.NOTES
    Version:        1.1
    Author:         Matt McPhee
    Creation Date:  08/08/2024
.PARAMETER ComputerListPath
    A file path to a list of computers in .txt format
.PARAMETER ExportCsvPath
    A file path to the desired output location of the .csv file
.INPUTS
    A file path to a list of computer names in .txt format
.OUTPUTS
    Information to the console about the computer's AD bitlocker key and the
    actual key from manage-bde.
    If the ExportCsvPath parameter is set it will output a csv to the location
    specified.
    If the computer is offline at the time of script execution then it will skip
    that computer.
.EXAMPLE
    Compare-ADBitLockerToActualBitLocker -ComputerListPath 'C:\sources\computers.csv'
#>
function Compare-ADBitLockerToActualBitLocker {
    [CmdletBinding()]
    param (
        # Filepath to a text file containing a list of machines
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]
        $ComputerListPath,
        # Filepath you'd like to export the csv to
        [Parameter(Mandatory=$true)]
        [string]
        $ExportCsvPath
    )
    # get list of machines from txt file
    $computerListFromTxt = Get-Content -Path $ComputerListPath
    # loop through each machine in the list
    foreach ($computer in $computerListFromTxt) {
        # see if the computer is online by running an invoke command on it
        Invoke-Command -ComputerName $computer -ScriptBlock {} -ErrorAction Ignore
        # if previous command succeeded then proceed, if not then computer is offline
        if ($?) {
            # get the AD computer object
            $ADComputer = Get-ADComputer -Identity $computer
            # get the bitlocker info using get-adobject and the adcomputer obj
            $ADRecoveryObj = `
                Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} `
                    -SearchBase $ADComputer -Properties *
            # sort the list of bitlocker items by name
            # the first part of the name has the date so it will show the latest key
            # first in the list
            $ADBitlockerItemsSorted = $ADRecoveryObj | Sort-Object Name -Descending
            # create an array to add the recovery items to
            $ADRecoveryItems = @()
            # loop through each bitlockeritem and pull out the info we want
            foreach ($blItem in $ADBitlockerItemsSorted) {
                # use substring to get the actual keyId
                $ADBitlockerKeyId = $blItem.Name.ToString().Substring(25,38)
                # get the key creation date
                $ADBitlockerKeyCreationDate = $blItem.Name.ToString().Substring(0,25)
                # add object to object array
                $ADRecoveryItems += [PSCustomObject]@{
                    "RecoveryKeyId"     = $ADBitlockerKeyId
                    "CreationDate"      = $ADBitlockerKeyCreationDate
                }
            }
            # get the current ad bitlocker key and creation date
            $ADCurrentBitlocker = $ADRecoveryItems[0]
            $ADCurrentBitlockerId = $ADCurrentBitlocker.RecoveryKeyId
            $ADCurrentBitlockerCreationDate = $ADCurrentBitlocker.CreationDate
            # run get-bitlockervolume on machine to get bitlocker object
            # containing the keyID and the actual password
            $actualBitlockerKeyObj = `
                Invoke-Command -ComputerName $computer -ScriptBlock {
                    $blv = Get-BitLockerVolume 'C:'
                    return $blv.KeyProtector
                }
            $actualRecoveryObj = $actualBitlockerKeyObj[0]
            $actualRecoveryType = $actualRecoveryObj.KeyProtectorType
            $actualRecoveryId = $actualRecoveryObj.KeyProtectorId
            $actualRecovery

            Write-Host "Actual BitLocker key on $($computer):"
            Write-Host $actualBitlockerKeyId

            # check if keys match
            $keysMatch = ""

            if ($ADBitlockerKeyId -like $actualBitlockerKeyId) {
                Write-Host "Keys match!" -BackgroundColor DarkGreen
                Write-Host $ADBitlockerKeyId -BackgroundColor DarkGreen
                Write-Host $actualBitlockerKeyId -BackgroundColor DarkGreen
                $keysMatch = "Yes"
            } else {
                $errorString = "The current BitLocker key on the device" +
                " does not match the latest key in Active Directory."
                Write-Host $errorString -BackgroundColor Red
                Write-Host $ADBitlockerKeyId -BackgroundColor Red
                Write-Host $actualBitlockerKeyId -BackgroundColor Red
                $keysMatch = "No"
            }

            # add info to csv object
            $machineBitlockerInfo = [PSCustomObject]@{
                "ComputerName"          = $computer
                "ADBitlockerKeyId"      = $ADBitlockerKeyId
                "ActualBitlockerKeyId"  = $actualBitlockerKeyId
                "Status"                = "Online"
                "KeysMatch?"            = $keysMatch
                "RecoveryItems"         = $ADRecoveryItems
            }

            $machineBitlockerInfo | Export-Csv $ExportCsvPath `
                -Append -NoTypeInformation -Force
        } else {
            Write-Host "`n$computer is not online at the moment."

            $machineBitlockerInfo = [PSCustomObject]@{
                "ComputerName"          = $computer
                "ADBitlockerKeyId"      = ""
                "ActualBitlockerKeyId"  = ""
                "Status"                = "Offline"
                "KeysMatch?"            = ""
                "RecoveryItems"         = ""
            }

            $machineBitlockerInfo | Export-Csv $ExportCsvPath `
                -Append -NoTypeInformation -Force
        }
    }
}

#endregion

#region Confirm-BuggedSupersedence.ps1
function Confirm-BuggedSupersedence {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $ComputerName
    )

    begin {
        # requires filesystem provider
        $startLoc = Get-Location
        Set-Location "C:\"

        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $csvFileName = "C:\sources\csv\12d-ss-bug-$timestamp.csv"
        $null = New-Item -Path $csvFileName -Force
    }

    process {
        $result = [PSCustomObject]@{
            ComputerName      = $null
            "Has The Issue?"  = $null
            "Last Error Date" = $null
            "Last Error Time" = $null
        }
        
        if (-not (Test-Connection $ComputerName -Quiet -Count 2)) {
            $result = [PSCustomObject]@{
                ComputerName   = $ComputerName
                "HasTheIssue?" = "Machine is offline"
            }
            Write-Host "$ComputerName is offline" -ForegroundColor Yellow
            $result | Export-Csv -Path $csvFileName -Append -NoTypeInformation
            return
        }

        $appIntentLogPath = "\\$ComputerName\c$\Windows\CCM\Logs\AppIntentEval.log"

        if (-not (Test-Path $appIntentLogPath)) {
            $result = [PSCustomObject]@{
                ComputerName   = $ComputerName
                "HasTheIssue?" = "AppIntentEval.log not found"
            }
            Write-Host "AppIntentEval.log not found on $ComputerName" -ForegroundColor Yellow
            $result | Export-Csv -Path $csvFileName -Append -NoTypeInformation
            return
        }

        # this is the error we are searching for
        $pattern = "Superseded DT ScopeId_CAB634EA-40F0-4556-B4B6-A21E63677A80/DeploymentType_030e37ca-ed56-42dc-8380-e74a2be79fe2/2 selected for installation. Returning error 0x87d00266"

        $lastLogLineMatch = Get-Content $appIntentLogPath |
        Sort-Object -Descending |
        Select-String -Pattern $pattern |
        Select-Object -First 1

        if ($lastLogLineMatch) {
            $lastLogLineWithError = $lastLogLineMatch.ToString()

            $datePattern = 'date="(\d{2})-(\d{2})-(\d{4})"'
            $dateMatch = $lastLogLineWithError | Select-String -Pattern $datePattern
            $day = $dateMatch.Matches.Groups[2].Value
            $month = $dateMatch.Matches.Groups[1].Value
            $year = $dateMatch.Matches.Groups[3].Value
            $formattedDate = "$year-$month-$day"

            $timePattern = 'time="(\d{2}:\d{2}:\d{2})\.\d+-\d+"'
            $timeMatch = $lastLogLineWithError | Select-String -Pattern $timePattern
            $formattedTime = $timeMatch.Matches.Groups[1].Value

            $result = [PSCustomObject]@{
                ComputerName    = $ComputerName
                "HasTheIssue?"  = "Yes"
                "Last Log Date" = $formattedDate
                "Last Log Time" = $formattedTime
            }
            Write-Host "$ComputerName has the issue!" -ForegroundColor Red
            $result | Export-Csv -Path $csvFileName -Append -NoTypeInformation
        } else {
            $result = [PSCustomObject]@{
                ComputerName   = $ComputerName
                "HasTheIssue?" = "No"
            }
            Write-Host "$ComputerName does not have the issue. Phew!" -ForegroundColor Green
            $result | Export-Csv -Path $csvFileName -Append -NoTypeInformation
        }
    }

    end {
        Set-Location $startLoc
    }
}

#endregion

#region Confirm-CCMSQLIssue.ps1
function Confirm-CCMSQLIssue {
    param(
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )

    # logpath
    $logPath = "C:\sources\logs\Confirm-CCMSQLIssue.log"

    # test if machine is online and psremoting is working by testing invoke-command
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {} -ErrorAction Ignore
    $machineOnlineTestFailed = (-not $?)
    if ($machineOnlineTestFailed) {
        $errorMsg = "$ComputerName is offline or psremoting/winrm is cooked."
        Write-Log -Message $errorMsg -Level Error -Path $logPath
    }
    $sql = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-Content 'C:\Windows\CCM\Logs\CCMSQLCE.log'
    }
    $count = ([regex]::matches($sql,"active concurrent sessions")).count
    $outputMsg = "There were $count instances of the phrase " + `
        "'active concurrent sessions' found in CCMSQLCE.log on $ComputerName"
    Write-Log -Message $outputMsg -Level Warning -Path $logPath
    Write-Output $outputMsg
}

#endregion

#region Convert-WmiDateTime.ps1
function Convert-WmiDateTime {
    param (
        # WmiDateTime string
        [Parameter(Mandatory)]
        [string]
        $WmiDateTime
    )
    # 20250402133057.000000+***
    $dotIndex = $WmiDateTime.IndexOf(".")
    $WmiDateTime = $WmiDateTime.Substring(0,$dotIndex)
    $year = $WmiDateTime.Substring(0,4)
    $month = $WmiDateTime.Substring(4,2)
    $day = $WmiDateTime.Substring(6,2)
    $hour = $WmiDateTime.Substring(8,2)
    $minute = $WmiDateTime.Substring(10,2)
    $second = $WmiDateTime.Substring(12,2)

    return "$year/$month/$day $($hour):$($minute):$($second)"
}

#endregion

#region Copy-BypassAppsToSource.ps1
function Copy-BypassAppsToSource {
    $appList = @(
        'addinprocess.exe',
        'addinprocess32.exe',
        'addinutil.exe',
        'aspnet_compiler.exe',
        'bash.exe',
        'bginfo.exe',
        'cdb.exe',
        'cscript.exe',
        'csi.exe',
        'dbghost.exe',
        'dbgsvc.exe',
        'dbgsrv.exe',
        'dnx.exe',
        'dotnet.exe',
        'fsi.exe',
        'fsiAnyCpu.exe',
        'infdefaultinstall.exe',
        'kd.exe',
        'kill.exe',
        'lxssmanager.dll',
        'lxrun.exe',
        'Microsoft.Build.dll',
        'Microsoft.Workflow.Compiler.exe',
        'msbuild.exe',
        'msbuild.dll',
        'mshta.exe',
        'ntkd.exe',
        'ntsd.exe',
        'powershellcustomhost.exe',
        'rcsi.exe',
        'runscripthelper.exe',
        'texttransform.exe',
        'visualuiaverifynative.exe',
        'system.management.automation.dll',
        'webclnt.dll/davsvc.dll',
        'wfc.exe',
        'windbg.exe',
        'wmic.exe',
        'wscript.exe',
        'wsl.exe',
        'wslconfig.exe',
        'wslhost.exe'
    )

    foreach ($app in $appList) {
        $result = Get-ChildItem -Path 'C:\Windows' -Filter "*$app" -Recurse -Depth 2 -ErrorAction SilentlyContinue |
        Select-Object -First 1
        Write-Log -Message $result.FullName -Level Info -Path "C:\source\log\Copy-BypassAppsToSource.log"
        $result | Copy-Item -Destination "C:\source\bypassapps"
    }

    $apps = Get-ChildItem

    foreach ($app in $apps) {
        Start-Process $app.FullName
        Read-Host -Prompt "Enter to continue"
    }
}

#endregion

#region Copy-Dlls.ps1
function Copy-Dlls {
    [CmdletBinding()]
    param (
        # DestinationFolder
        [Parameter(Mandatory)]
        [string]
        $DestinationFolder,
        # RemoteMachineFolder
        [Parameter(Mandatory)]
        [string]
        $RemoteMachineDllUncFolder
    )
    
    if (-not (Test-Path -Path $DestinationFolder -PathType Container)) {
        New-Item -Path $DestinationFolder -ItemType Directory -Force
    }

    $dymoDlls = Get-ChildItem -Path "$RemoteMachineDllUncFolder\*.dll" -File

    if ($dymoDlls.Count -lt 1) {
        throw "No dlls were found in this folder. Ya dun goofed!"
    }

    $dymoDlls | Copy-Item -Destination $DestinationFolder -Force 
}

#endregion

#region Export-IconFromExe.ps1
function Export-IconFromExe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExePath,

        [Parameter(Mandatory=$false)]
        [string]$OutputFolder
    )

    if (-not $PSBoundParameters["OutputFolder"]) {
        $OutputFolder = $ExePath | Split-Path -Parent
    }

    # load the required .NET assembly
    Add-Type -AssemblyName System.Drawing

    # ensure the output directory exists
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }

    try {
        # 3. Extract the icon associated with the file
        # Note: This usually pulls the default large icon (32x32 or 48x48)
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ExePath)
        $bitmap = $icon.ToBitmap()

        # 4. Create a new 512x512 canvas (Bitmap)
        $newBitmap = New-Object System.Drawing.Bitmap(512, 512)
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)

        # 5. Set high-quality resizing options
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        # 6. Draw the original icon onto the new 512x512 canvas
        $graphics.DrawImage($bitmap, 0, 0, 512, 512)

        # 7. Define file names
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ExePath)
        $pngPath = Join-Path $OutputFolder "$baseName.png"
        $icoPath = Join-Path $OutputFolder "$baseName.ico"

        # 8. Save as PNG
        $newBitmap.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Verbose "Success: Saved PNG to $pngPath"

        # 9. Save as ICO
        # We convert the bitmap back to an icon handle to save in .ico format
        $hIcon = $newBitmap.GetHicon()
        $newIcon = [System.Drawing.Icon]::FromHandle($hIcon)
        $fileStream = [System.IO.File]::OpenWrite($icoPath)
        $newIcon.Save($fileStream)
        $fileStream.Close()
        
        Write-Verbose "Success: Saved ICO to $icoPath"
    } catch {
        Write-Error "Failed to extract or save icon: $($_.Exception.Message)"
    } finally {
        # Cleanup to prevent memory leaks
        if ($graphics) { $graphics.Dispose() }
        if ($newBitmap) { $newBitmap.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
        if ($icon) { $icon.Dispose() }
    }
}

#endregion

#region Find-HostName.ps1
function Find-HostName {
    $txtFiles = Get-ChildItem "C:\temp\folders" -Recurse -File
    foreach ($txtFile in $txtFiles) {
        $content = Get-Content $txtFile
        if ($content.contains("mmtask")) {
            Write-Host $txtFile
            Break
        }
    }
}

#endregion

#region Format-AaronLockerHashRule.ps1
<#
.SYNOPSIS
   Create HashRules
.DESCRIPTION
   Create HashRules for AaronLocker HashRuleData.ps1 based on "Get-AppLockerFileInformation -Directory C:\Directory -Recurse | Export-Csv C:\FileName.csv -Encoding UTF8"
.PARAMETER File
   Full path to the file to import
.PARAMETER ExportLocation
   Location to export the results. The dxport location shouldn't incude final backslash as its automatically added.
.PARAMETER Application
   Name of the Application the HashRules are for eg. "Photoshop"
.PARAMETER Description
   Description of the HashRule eg. "for Department XYZ"
.INPUTS
   N/A
.OUTPUTS
   N/A
.NOTES
   Version:        1.0
   Author:         Bryan Bultitude
   Creation Date:  22/02/2022
   Purpose/Change: 22/02/2022 - Bryan Bultitude - Initial script development
.EXAMPLE
   PS> Format-AaronLockerHashRule -File "C:\Temp\HashFile.csv" -ExportLocation "C:\Temp" -Application "Bat Cave" -Description "for Bruce Wayne"
.EXAMPLE
   PS> Format-AaronLockerHashRule "C:\Temp\HashFile.csv" "C:\Temp" "Bat Cave" "for Bruce Wayne"
#>
function Format-AaronLockerHashRule {
    param (
        [Parameter(Mandatory = $true)]
        $File,
        [Parameter(Mandatory = $true)]
        $ExportLocation,
        [Parameter(Mandatory = $true)]
        $Application,
        [Parameter(Mandatory = $true)]
        $Description
    )
    $Hash = Import-Csv $File
    $outfile = "$ExportLocation\$Application - HashRules.txt"
    "#region $Application" | Out-File -FilePath $outfile
    foreach ($item in $Hash) {
        $File = Split-Path $item.Path -Leaf
        $RuleName = "$($application): $($File) - HASH RULE"
        $Desc = "$Application $Description"
        if (([System.IO.Path]::GetExtension($File)) -in ".ocx", ".dll" ) {
            $RuleType = "Dll"
        }
        elseif (([System.IO.Path]::GetExtension($File)) -in ".com", ".exe" ) {
            $RuleType = "Exe"
        }
        elseif (([System.IO.Path]::GetExtension($File)) -in ".vbs", ".js", ".ps1", ".bat", ".cmd" ) {
            $RuleType = "Script"
        }
        elseif (([System.IO.Path]::GetExtension($File)) -in ".msi", ".msp", "mst" ) {
            $RuleType = "Msi"
        }
        "@{" | Out-File -FilePath $outfile -Append
        "RuleCollection = `"$RuleType`";" | Out-File -FilePath $outfile -Append
        "RuleName = `"$RuleName`";" | Out-File -FilePath $outfile -Append
        "RuleDesc = `"$Desc`";" | Out-File -FilePath $outfile -Append
        "HashVal  = `"$($item.Hash.Split(" ")[1])`";" | Out-File -FilePath $outfile -Append
        "FileName = `"$($File)`";" | Out-File -FilePath $outfile -Append
        "}" | Out-File -FilePath $outfile -Append


    }
    "#endregion" | Out-File -FilePath $outfile -Append
}

#endregion

#region Get-AppRequirements.ps1
function Get-AppRequirements {
    param(
        # ApplicationName
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationName
    )
    $apps = Get-CMApplication -ApplicationName $ApplicationName -Fast |
        Where-Object {($_.IsDeployed -like 'True') -and ($_.IsSuperseded -like 'False')}
    foreach ($app in $apps) {
        $dt = $app | Get-CMDeploymentType
        $requirements = $dt | Get-CMDeploymentTypeRequirement | 
            Select-Object RuleId,Name
        $output = [PSCustomObject]@{
            "AppName" = $app.LocalizedDisplayName
            "Requirements" = $requirements.Name
        }
        $output
    }
}

#endregion

#region Get-AppsWithMoreThanOneDependency.ps1
function Get-AppsWithMoreThanOneDependency {
    $apps = Get-CMApplication -Fast

    $result = @()

    foreach ($app in $apps) {
        $appDepCount = (Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName).NumberOfDependedDTs

        if ($appDepCount -gt 1) {
            $appWithDeps = [PSCustomObject]@{
                ApplicationName = $app.localizeddisplayname
                DependencyCount = $appDepCount
            }
            Write-Host $appWithDeps

            $result += $appWithDeps
        }
    }

    if ($result.Count -eq 0) {
        Write-Host "No applications with more than one dependency found."
    } else {
        Write-Host "`nApplications with more than one dependency:`n"
        $result | Format-Table -AutoSize
    }
}

#endregion

#region Get-AppsWithMultipleDTs.ps1
function Get-AppsWithMultipleDTs {
    $apps = Get-CMApplication -Fast
    $target = $apps | Where-Object {$_.NumberOfDeploymentTypes -gt 1} | 
        Select-Object LocalizedDisplayName
    $target
}

#endregion

#region Get-CCMCacheSize.ps1
function Get-CCMCacheSize {
    param(
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = ($env:ComputerName)
    )
    Invoke-Command -ComputerName $ComputerName (New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize = 100000
}

#endregion

#region Get-CMComputerInfo.ps1
function Get-CMComputerInfo {
    # --- Configuration ---
    $sccmSiteCode = 'A00'
    $sccmSiteServer = 'BNESCCM01.bmd.com.au'

    # Replace 'YOUR_TARGET_MACHINE_NAME' with the actual computer name you want to query.
    # Leave as '*' to get BIOS info for all devices in SCCM (this can be a lot of data!)
    $TargetMachineName = '1CZ01405Q4'
    # --- End Configuration ---

    Write-Host "Attempting to retrieve BIOS information for machine(s): '$TargetMachineName'..."

    # Construct the WMI namespace for the SCCM site
    $Namespace = "root\SMS\site_$($sccmSiteCode)"

    try {
        # Query the SMS_G_System_PC_BIOS WMI class
        # We need to first get the ResourceID of the device(s)
        $Devices = Get-CMDevice -Name $TargetMachineName -ErrorAction Stop

        if ($Devices) {
            $BiosInfo = @()
            foreach ($Device in $Devices) {
                Write-Host "  Querying BIOS for '$($Device.Name)' (Resource ID: $($Device.ResourceID))..."
                $DeviceBios = Get-WmiObject -ComputerName $sccmSiteServer `
                    -Namespace $Namespace `
                    -Class SMS_G_System_PC_BIOS `
                    -Filter "ResourceID = $($Device.ResourceID)" `
                    -ErrorAction SilentlyContinue

                if ($DeviceBios) {
                    # Select specific properties for clarity
                    $BiosInfo += [PSCustomObject]@{
                        ComputerName      = $Device.Name
                        SMBIOSBIOSVersion = $DeviceBios.SMBIOSBIOSVersion # The main BIOS version string
                        BIOSVersion       = $DeviceBios.Version              # Often similar to SMBIOSBIOSVersion
                        Manufacturer      = $DeviceBios.Manufacturer
                        ReleaseDate       = $DeviceBios.ReleaseDate
                        SerialNumber      = $DeviceBios.SerialNumber
                        Caption           = $DeviceBios.Caption
                    }
                } else {
                    Write-Warning "  No BIOS inventory found for '$($Device.Name)'. Ensure hardware inventory is running and includes PC BIOS class."
                }
            }

            if ($BiosInfo.Count -gt 0) {
                Write-Host "`n--- BIOS Information ---"
                $BiosInfo | Format-Table -AutoSize
                # Optional: Export to CSV
                # $BiosInfo | Export-Csv "C:\Temp\SCCM_BIOS_Info.csv" -NoTypeInformation
                # Write-Host "`nBIOS information exported to C:\Temp\SCCM_BIOS_Info.csv"
            } else {
                Write-Host "`nNo BIOS information retrieved for the specified machine(s)."
            }
        } else {
            Write-Warning "No devices found matching '$TargetMachineName' in Configuration Manager."
        }
    } catch {
        Write-Error "An error occurred during WMI query: $($_.Exception.Message)"
    }
}
#endregion

#region Get-ComputerUptime.ps1
function Get-ComputerUptime {
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]$ComputerName
    )

    if ($PSBoundParameters["ComputerName"]) {
        try {
            $uptime = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ComputerName $using:ComputerName).LastBootupTime
            }
        } catch {
            throw $_
        }
    } else {
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ComputerName $ComputerName).LastBootupTime
    }

    "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes, $($uptime.Seconds) seconds."
}

#endregion

#region Get-ConnectedDocks.ps1
function Get-ConnectedDocks {
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )

    $pnpSignedDrivers = Get-CimInstance `
                            -ClassName Win32_PnPSignedDriver `
                            -ComputerName $ComputerName
    $connectedDocks = @()

    foreach ($driver in $pnpSignedDrivers) {
        $installedDeviceID = "$($driver.DeviceID)"

        if ( ($installedDeviceID -match "HID\\VID_03F0") -or `
        ($installedDeviceID -match "USB\\VID_17E9") ) {
            switch -Wildcard ( $installedDeviceID ) {
                '*PID_0488*' { $connectedDocks += 'HP Thunderbolt Dock G4' }
                '*PID_0667*' { $connectedDocks += 'HP Thunderbolt Dock G2' }
                '*PID_484A*' { $connectedDocks += 'HP USB-C Dock G4' }
                '*PID_046B*' { $connectedDocks += 'HP USB-C Dock G5' }
                '*PID_600A*' { $connectedDocks += 'HP USB-C Universal Dock' }
                '*PID_0A6B*' { $connectedDocks += 'HP USB-C Universal Dock G2' }
                '*PID_056D*' { $connectedDocks += 'HP E24d G4 FHD Docking Monitor' }
                '*PID_016E*' { $connectedDocks += 'HP E27d G4 QHD Docking Monitor' }
                '*PID_379D*' { $connectedDocks += 'HP USB-C G5 Essential Dock' }
            } #switch
        } #if
    } #foreach

    $connectedDocks
} #function

#endregion

#region Get-DriverList.ps1
function Get-DriverList {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        if (-not (Test-Path 'C:\source')) {
            New-Item -ItemType Directory -Path 'C:\source'
        }
        Get-CimInstance -ClassName Win32_PnPSignedDriver |
        Select-Object Description, DeviceName, DriverVersion, DriverDate |
        Export-Csv -NoTypeInformation -Path 'C:\source\drivers.csv'
    }
}

#endregion

#region Get-FolderSizes.ps1
function Get-FolderSizes {
    param (
        # Path
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    $folders = Get-ChildItem -Path $Path -Directory -Recurse

    $folderSizes = foreach ($folder in $folders) {
        $size = (Get-ChildItem -Path ($folder.FullName) -File -Recurse | Measure-Object -Property Length -Sum).Sum
        $sizeInGB = $size / 1GB

        # collect data
        [PSCustomObject]@{
            FolderName = $folder.FullName
            SizeInGB = [Math]::Round($sizeInGB,2)
        }
    }

    $folderSizes
}

#endregion

#region Get-InstallCommands.ps1
function Get-InstallCommands {
    [CmdletBinding()]
    param (
        # Application name
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationName
    )
    # get the app object
    $app = Get-CMApplication $ApplicationName

    # explicitly cast to xml type so we can use dot notation
    [xml]$xml = $app.SDMPackageXML
    # pull out customdata so we don't have to reference the full path every time
    $customData = $xml.AppMgmtDigest.DeploymentType.Installer.CustomData
    # install line
    $installLine = $customData.InstallCommandLine
    # uninstall line
    $uninstallLine = $customData.UninstallCommandLine
    # repair line
    $repairLine = $customData.RepairCommandLine
    # dependency
    $dependency =   $xml.AppMgmtDigest.DeploymentType.Dependencies.
                    DeploymentTypeRule.Annotation.DisplayName.Text
    $msg = ""

    if ($installLine) {
        $msg += "Install Command:`n$installLine`n"
    } else {
        Write-Host "InstallCommandLine: This app doesn't have an install line."
    }

    if ($uninstallLine) {
        $msg += "Uninstall Command:`n$uninstallLine`n"
    } else {
        Write-Host "UninstallCommandLine: This app doesn't have an uninstall line."
    }

    if ($repairLine) {
        $msg += "Repair Command:`n$repairLine`n"
    } else {
        Write-Host "RepairCommandLine: This app doesn't have a repair line."
    }

    if ($dependency) {
        Write-Host "Dependencies: $dependency"
    } else {
        Write-Host "Dependencies: This app doesn't have any dependencies."
    }

    $msg
}

#endregion

#region Get-InstalledKB.ps1
function Get-InstalledKB {
    [CmdletBinding()]
    param (
        # KB number
        [Parameter(Mandatory)]
        [string]
        $KB,
        # ComputerName
        [Parameter(Mandatory)]
        [object[]]
        $MachineList,
        # CsvPath
        [Parameter(Mandatory)]
        [string]
        $CsvPath
    )

    foreach ($machine in $MachineList) {
        $machineOnline = Test-Connection -ComputerName $machine -Count 2 -Quiet

        if ($machineOnline) {
            $hotfix = Invoke-Command -ComputerName $machine -ScriptBlock {
                Get-Hotfix | Where-Object { $_.HotfixID -eq $KB }
            }
        } else {
            Write-Host "$machine offline. Skipping..."
            continue
        }

        $hotfixFiltered = $hotfix |
        Select-Object @{n="ComputerName";e={$machine}},description,hotfixid,installedby,installedon

        $hotfixFiltered | Export-Csv -Path $CsvPath -Encoding utf8 -Append -NoTypeInformation
    }
}

#endregion

#region Get-LastLogonUser.ps1
function Get-LastLogonUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName
    )

    Get-CMDevice -Name $ComputerName |
    Select-Object @{n="ComputerName";e=$ComputerName},lastlogonuser
}

#endregion

#region Get-MachinesOfflineOverXDays.ps1
<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

function Get-MachinesOfflineOverXDays {
    param(
        # days
        [Parameter(Mandatory=$false)]
        [int32]
        $Days = 14
    )
    Get-CMDevice -Fast | Where-Object {
        ($null -ne $_.LastDDR) -and `
        ((New-TimeSpan -Start $_.LastDDR -End (Get-Date)).Days -ge $Days) -and `
        (Test-Connection -ComputerName $_.Name -Count 2 -Quiet)
    } | Select-Object Name,LastDDR,ADLastLogonTime
}

#endregion

#region Get-SCCMDeviceQueries.ps1
function Get-SCCMDeviceQueries {
    $logPath = "C:\sources\logs\Get-SCCMDeviceQueries.log"

    $collections = Get-CMDeviceCollection

    $results = @()

    foreach ($collection in $collections) {
        Write-Log -Path $logPath -Message "Collection: $($collection.Name)"

        # get all membership rules
        $rules = Get-CMCollectionQueryMembershipRule -CollectionId $collection.CollectionID

        foreach ($rule in $rules) {
            Write-Log -Path $logPath -Message "Rule Name: $($rule.RuleName)"
            Write-Log -Path $logPath -Message "Query: $($rule.QueryExpression)"

            $result = [PSCustomObject]@{
                "Collection" = $collection.Name
                "RuleName"   = $rule.RuleName
                "Query"      = $rule.QueryExpression
            }

            $results += $result
        }
    }

    $results | Export-Csv -Path "C:\sources\csv\sccm-device-queries.csv" -NoTypeInformation
}

#endregion

#region Get-SCCMDeviceQueriesContainingOldGroups.ps1
function Get-SCCMQueriesContainingOldGroups {
    $groupList = @(
        "GW_ANZ_Online_cgs",
        "gw_microsoft_office_2007_deny_gs",
        "GW_IBM_Tivoli_CDP_ugs",
        "GW_GFI_Endpoint_Security_gs",
        "GW_BMD_Terminal_Server_gs",
        "CM_Jobpac_PR_usg",
        "CM_Asta_POBM_GS",
        "CM_Jobpac_PB_gs",
        "CM_Jobpac_TC_gs",
        "CM_Asta_PowerProject_gs",
        "CM_Asta_BMD_gs",
        "CM_Asta_Transcity_gs",
        "CM_Jobpac_T2_gs",
        "CM_IBM_Tivoli_Fastback_Workstations_gs",
        "CM_Asta_Tilos_gs",
        "CM_Expert_Terminal_server_gs",
        "CM_IBM_Iseries_Access_File_transfer_gs",
        "CM_ANZ_Gemsafe_64bit_gs",
        "CM_Estate_Master_gs",
        "CM_Asta_4178_gs",
        "CM_Asta_J005_gs",
        "CM_Exactal_CostX_gs",
        "ADLSCCM01_Administrators",
        "ADLSCCM02_Administrators",
        "au_computers_sccm_2012_deny_group_policy",
        "au_it_laps_authorized_decryptors_au_computers_sccm_2012_usg",
        "au_it_level_2_sccm_sql_ro_access_usg",
        "_Administrators",
        "BNESCCM01_Administrators",
        "BNESCCM02_Administrators",
        "BNESCCM03_Administrators",
        "BNESCCM04_Administrators",
        "BNESCCM05_Administrators",
        "BNESCCM10_Administrators",
        "certificate_template_SCCMBootMediaCertificate-1YearValidity_usg",
        "certificate_template_SCCMClient-5YearValidity_gs",
        "certificate_template_SCCMClientDPCertificate-5Year_gs",
        "certificate_template_SCCMWebServerCertificate-5YearValidity_gs",
        "gp_firewall_server_SCCM_DP_usg",
        "gp_firewall_server_SCCM_MP_usg",
        "LONSCCM01_Administrators ",
        "MELSCCM01_Administrators",
        "MELSCCM02_Administrators",
        "MNLSCCM01_Administrators",
        "PERSCCM01_Administrators",
        "POBSCCM01_Administrators",
        "sccm_jobpac_gs",
        "Scope-OU-au_computers_sccm_2012_usg",
        "share_sccm_captured_os_full_gs",
        "share_sccm_captured_os_modify_gs",
        "share_sccm_captured_os_read_gs",
        "share_sccm_drivers_modify_usg",
        "share_sccm_drivers_owner_usg",
        "share_sccm_drivers_read_usg",
        "share_sccm_osd_logs_modify_gs",
        "share_sccm_packages_modify_usg",
        "share_sccm_packages_owner_usg",
        "share_sccm_packages_read_usg",
        "SYDSCCM01_Administrators",
        "SYDSCCM02_Administrators",
        "TSVSCCM01_Administrators",
        "TSVSCCM02_Administrators",
        "AgentEdition0"
    )

    $logPath = "C:\sources\logs\old-endpoint-groups.log"

    # import the csv into memory
    $deviceQueries = Import-Csv -Path "C:\sources\csv\sccm-device-queries.csv"

    $queriesContainingGroup = @()

    # loop through each group in the list and see if it's mentioned in queries
    foreach ($group in $groupList) {
        Write-Log -Path $logPath -Message "Group: $group"

        foreach ($query in $deviceQueries.Query) {
            if ($query.Contains($group)) {
                $queriesContainingGroup += [PSCustomObject]@{
                    Query = $query
                }
            }
        }
    }

    $queriesContainingGroup | Export-Csv -Path "C:\sources\csv\sccm-queries-containing-group.csv" -NoTypeInformation -Force

    Write-Log -Path $logPath -Message "=== Script completed! ==="
}

#endregion

#region Get-SCCMUserQueries.ps1
function Get-SCCMUserQueries {
    $logPath = "C:\sources\logs\Get-SCCMUserQueries.log"

    $collections = Get-CMUserCollection | Select-Object Name, CollectionID

    $results = @()

    foreach ($collection in $collections) {
        Write-Log -Path $logPath -Message "Collection: $($collection.Name)"

        # get all membership rules
        $rules = Get-CMCollectionQueryMembershipRule -CollectionId $collection.CollectionID

        foreach ($rule in $rules) {
            Write-Log -Path $logPath -Message "Rule Name: $($rule.RuleName)"
            Write-Log -Path $logPath -Message "Query: $($rule.QueryExpression)"

            $result = [PSCustomObject]@{
                "Collection" = $collection.Name
                "RuleName"   = $rule.RuleName
                "Query"      = $rule.QueryExpression
            }

            $results += $result
        }
    }

    $results | Export-Csv -Path "C:\sources\csv\sccm-user-queries.csv" -NoTypeInformation
}

#endregion

#region Get-SCCMUserQueriesContainingOldGroups.ps1
function Get-SCCMUserQueriesContainingOldGroups {
    $groupList = @(
        "GW_ANZ_Online_cgs",
        "gw_microsoft_office_2007_deny_gs",
        "GW_IBM_Tivoli_CDP_ugs",
        "GW_GFI_Endpoint_Security_gs",
        "GW_BMD_Terminal_Server_gs",
        "CM_Jobpac_PR_usg",
        "CM_Asta_POBM_GS",
        "CM_Jobpac_PB_gs",
        "CM_Jobpac_TC_gs",
        "CM_Asta_PowerProject_gs",
        "CM_Asta_BMD_gs",
        "CM_Asta_Transcity_gs",
        "CM_Jobpac_T2_gs",
        "CM_IBM_Tivoli_Fastback_Workstations_gs",
        "CM_Asta_Tilos_gs",
        "CM_Expert_Terminal_server_gs",
        "CM_IBM_Iseries_Access_File_transfer_gs",
        "CM_ANZ_Gemsafe_64bit_gs",
        "CM_Estate_Master_gs",
        "CM_Asta_4178_gs",
        "CM_Asta_J005_gs",
        "CM_Exactal_CostX_gs",
        "ADLSCCM01_Administrators",
        "ADLSCCM02_Administrators",
        "au_computers_sccm_2012_deny_group_policy",
        "au_it_laps_authorized_decryptors_au_computers_sccm_2012_usg",
        "au_it_level_2_sccm_sql_ro_access_usg",
        "_Administrators",
        "BNESCCM01_Administrators",
        "BNESCCM02_Administrators",
        "BNESCCM03_Administrators",
        "BNESCCM04_Administrators",
        "BNESCCM05_Administrators",
        "BNESCCM10_Administrators",
        "certificate_template_SCCMBootMediaCertificate-1YearValidity_usg",
        "certificate_template_SCCMClient-5YearValidity_gs",
        "certificate_template_SCCMClientDPCertificate-5Year_gs",
        "certificate_template_SCCMWebServerCertificate-5YearValidity_gs",
        "gp_firewall_server_SCCM_DP_usg",
        "gp_firewall_server_SCCM_MP_usg",
        "LONSCCM01_Administrators ",
        "MELSCCM01_Administrators",
        "MELSCCM02_Administrators",
        "MNLSCCM01_Administrators",
        "PERSCCM01_Administrators",
        "POBSCCM01_Administrators",
        "sccm_jobpac_gs",
        "Scope-OU-au_computers_sccm_2012_usg",
        "share_sccm_captured_os_full_gs",
        "share_sccm_captured_os_modify_gs",
        "share_sccm_captured_os_read_gs",
        "share_sccm_drivers_modify_usg",
        "share_sccm_drivers_owner_usg",
        "share_sccm_drivers_read_usg",
        "share_sccm_osd_logs_modify_gs",
        "share_sccm_packages_modify_usg",
        "share_sccm_packages_owner_usg",
        "share_sccm_packages_read_usg",
        "SYDSCCM01_Administrators",
        "SYDSCCM02_Administrators",
        "TSVSCCM01_Administrators",
        "TSVSCCM02_Administrators"
    )

    $logPath = "C:\sources\logs\old-endpoint-groups.log"

    # import the csv into memory
    $deviceQueries = Import-Csv -Path "C:\sources\csv\sccm-user-queries.csv"

    $queriesContainingGroup = @()

    # loop through each group in the list and see if it's mentioned in queries
    foreach ($group in $groupList) {
        Write-Log -Path $logPath -Message "Group: $group"

        foreach ($query in $deviceQueries.Query) {
            if ($query.Contains($group)) {
                $queriesContainingGroup += [PSCustomObject]@{
                    Query = $query
                }
            }
        }
    }

    $queriesContainingGroup | Export-Csv -Path "C:\sources\csv\sccm-user-queries-containing-groups.csv" -NoTypeInformation -Force

    Write-Log -Path $logPath -Message "=== Script completed! ==="
}

#endregion

#region Get-SCCMWmiQueryResult.ps1
function Get-SCCMWmiQueryResult {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # Class - wmi class to use in the query
        [Parameter(Mandatory)]
        [string]
        $Class
    )

    $sccmComputerName = "bnesccm01"
    $sccmWmiNamespace = "root\SMS\site_A00"
    $resId = (Get-CMDevice -Name $ComputerName -Fast).ResourceID

    Get-WmiObject -ComputerName $sccmComputerName `
        -Namespace $sccmWmiNamespace `
        -Class $Class |
    Where-Object { $_.ResourceID -eq $resId } |
    Select-Object -First 1
}

#endregion

#region Get-SystemEnvironmentVariable.ps1
function Get-SystemEnvironmentVariable {
    [CmdletBinding()]
    param (
        # Name
        [Parameter(Mandatory)]
        [string]$Name,

        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]$ComputerName
    )

    if ($PSBoundParameters["ComputerName"]) {
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                [Environment]::GetEnvironmentVariable($using:Name, "Machine")
            }
        } catch {
            throw $_
        }
    } else {
        [Environment]::GetEnvironmentVariable($Name, "Machine")
    }
}

#endregion

#region Get-SystemEnvironmentVariables.ps1
function Get-SystemEnvironmentVariables {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]$ComputerName
    )

    if ($PSBoundParameters["ComputerName"]) {
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                [Environment]::GetEnvironmentVariables("Machine")
            }
        } catch {
            throw $_
        }
    } else {
        [Environment]::GetEnvironmentVariables("Machine")
        return
    }
}

#endregion

#region Get-TeamsVersion.ps1
function Get-TeamsVersion {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = $env:COMPUTERNAME
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        (Get-ChildItem "C:\Program Files\WindowsApps\MSTeams*").Name
    }
}

#endregion

#region Get-UserDeptAndJobTitle.ps1
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

#endregion

#region Get-WDACEventLogs.ps1
function Get-WDACEventLogs {
    [CmdletBinding()]
    param (
        # Number of minutes to go back in time to retrieve logs
        [Parameter(Mandatory=$true)]
        [string]
        $MinutesBackInTime,
        # Whether or not to include exe and dll logs (many many of these)
        [Parameter()]
        [switch]
        $IncludeExeDll
    )

    $PastDate = (Get-Date).AddMinutes(-$MinutesBackInTime)

    Write-Host "===CodeIntegrity Operational Logs===" -ForegroundColor Green
    Get-WinEvent -LogName "Microsoft-Windows-CodeIntegrity/Operational" |
    Where-Object {$_.TimeCreated -gt $PastDate} |
    Format-Table -AutoSize | Out-String -Width 10000 #

    Write-Host "===MSI and Script Logs===" -ForegroundColor Green
    Get-WinEvent -LogName "Microsoft-Windows-AppLocker/MSI and Script" |
    Where-Object {$_.TimeCreated -gt $PastDate} |
    Format-Table -AutoSize | Out-String -Width 10000 #

    if ($IncludeExeDll) {
        Write-Host "===EXE and DLL Logs===" -ForegroundColor Green
        Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" |
        Where-Object {$_.TimeCreated -gt $PastDate} |
        Format-Table -AutoSize | Out-String -Width 10000 #
    }
}

#endregion

#region Import-VMToSCCM.ps1
function Import-VMToSCCM {
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # MacAddress
        [Parameter(Mandatory)]
        [string]
        $MacAddress,
        # SMBiosGuid
        [Parameter(Mandatory=$false)]
        [string]
        $SMBiosGuid
    )

    $OsdPromptCollectionId = "A000005E"

    if ($SMBiosGuid) {
        Import-CMComputerInformation -ComputerName $ComputerName `
            -MacAddress $MacAddress `
            -CollectionId $OsdPromptCollectionId `
            -SMBiosGuid $SMBiosGuid
    } else {
        Import-CMComputerInformation -ComputerName $ComputerName `
            -MacAddress $MacAddress `
            -CollectionId $OsdPromptCollectionId
    }
}

#endregion

#region Install-HP7740Driver.ps1
function Install-HP7740Driver {
    # vars
    $driverName = "HP OfficeJet Pro 7740 series"

    # add driver into driver store
    Write-Log -Message 'Running: pnputil.exe /a .\Basic_Webpack_x64-40.16.1234-OJ7740_Basicx64_Webpack\hpygid20.inf /i'
    try {
        Invoke-Expression "pnputil.exe /a .\Basic_Webpack_x64-40.16.1234-OJ7740_Basicx64_Webpack\hpygid20.inf /i"
        Write-Log "Success"
    } catch {
        Write-Log -Message "There was an error running pnputil. The error was: $Error"
    }

    # install the driver
    Write-Log -Message "Running: Add-PrinterDriver -Name $driverName"
    try {
        Add-PrinterDriver -Name "$driverName"
        Write-Log "Success"
    } catch {
        Write-Log -Message "There was an error running Add-PrinterDriver. The error was: $Error"
    }
}

#endregion

#region New-AppScaffold.ps1
function New-AppScaffold {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # ApplicationName
        [Parameter(Mandatory)]
        [string]
        $ApplicationName,
        # Path
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    $psadtSourcePath = "C:\sources\staging\psadt_4.1.8\*"
    $stagingDestinationPath = "$Path\$ApplicationName"
    $appScriptPath = "$stagingDestinationPath\Invoke-AppDeployToolkit.ps1"
    $appScriptDestinationPath = "C:\sources\repos\matmcp1-psadt-app-scripts\$ApplicationName\Invoke-AppDeployToolkit.ps1"

    if (Test-Path -Path $stagingDestinationPath) {
        throw "Folder already exists. Exiting..."
    } else {
        New-Item -Path $stagingDestinationPath -ItemType Directory -Force
    }

    Copy-Item -Path $psadtSourcePath `
        -Destination $stagingDestinationPath `
        -Recurse `
        -Force

    # copy invoke-appdeploytoolkit.ps1 to matmcp1-app-scripts
    $appScriptFolderPath = "C:\sources\repos\matmcp1-psadt-app-scripts\$ApplicationName"
    if (-not (Test-Path -Path $appScriptFolderPath)) {
        New-Item -Path $appScriptFolderPath -ItemType Directory -Force
    }
    Copy-Item -Path $appScriptPath -Destination $appScriptDestinationPath -Force
}

#endregion

#region New-SCCMApplication.ps1
function New-SCCMApplication {
    param (
        # ApplicationName
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationName,
        # Publisher
        [Parameter(Mandatory=$true)]
        [string]
        $Publisher,
        # Version
        [Parameter(Mandatory=$true)]
        [string]
        $Version,
        # Owner
        [Parameter(Mandatory=$true)]
        [string]
        $Owner,
        # Description
        [Parameter(Mandatory=$true)]
        [string]
        $Description,
        # IconPath - path to icon file on network drive
        [Parameter(Mandatory=$true)]
        [string]
        $IconPath,
        # ContentLocation - path to content on network drive
        [Parameter(Mandatory=$true)]
        [string]
        $ContentLocation,
        # Free space required (MB)
        [Parameter(Mandatory=$true)]
        [string]
        $SpaceRequired,
        # Folder where application gets installed
        [Parameter(Mandatory=$true)]
        [string]
        $InstallFolder,
        # Name of the installed file, including file extension
        [Parameter(Mandatory=$true)]
        [string]
        $InstalledFile,
        # Registry key path (don't include root e.g. hklm or hkey_local_machine)
        [Parameter(Mandatory=$true)]
        [string]
        $RegKeyPath,
        # Registry key name
        [Parameter(Mandatory=$true)]
        [string]
        $RegKeyName,
        # Registry key value
        [Parameter(Mandatory=$true)]
        [string]
        $RegKeyValue,
        # is64bit - whether or not the application is 64bit
        [Parameter(Mandatory=$false)]
        [switch]
        $Is64Bit,
        # Max run time
        [Parameter(Mandatory=$true)]
        [string]
        $MaxRunTime,
        # Estimated run time
        [Parameter(Mandatory=$true)]
        [string]
        $EstimatedRunTime,
        # Uninstall content location
        [Parameter(Mandatory=$false)]
        [string]
        $UninstallContentLocation
    )

    Set-Location -Path 'A00:\'

    # if app doesn't exist, create it
    if (-not(Get-CMApplication -Name $ApplicationName -Fast)) {
        New-CMApplication `
            -Owner $Owner `
            -SupportContact $Owner `
            -DefaultLanguageId 3081 <# en-AU #> `
            -IconLocationFile $IconPath `
            -LocalizedDescription $Description `
            -LocalizedName $ApplicationName `
            -Name $ApplicationName `
            -Publisher $Publisher `
            -SoftwareVersion $Version
    }

    $app = Get-CMApplication -Name $ApplicationName

    # if publisher folder doesn't exist, create it
    if (-not(Test-Path -Path ".\Application\$Publisher")) {
        New-CMFolder -Name $Publisher -ParentFolderPath '.\Application'
    }

    # move app into folder
    $app | Move-CMObject -FolderPath ".\Application\$Publisher"

    # create requirement rules
    $freeSpaceRule = Get-CMGlobalCondition -Name "Free disk space" |
        New-CMRequirementRuleFreeDiskSpaceValue `
            -PartitionOption 'System' `
            -RuleOperator 'GreaterThan' `
            -Value1 $SpaceRequired

    # check to see if application has deployment type
    # if app has no deployment types, create one
    if ($app.NumberOfDeploymentTypes -lt 1) {
        # file detection clause
        if ($Is64Bit) {
            $fileDetClause = New-CMDetectionClauseFile `
            -FileName $InstalledFile `
            -Path $InstallFolder `
            -Existence `
            -Is64Bit
        } else {
            $fileDetClause = New-CMDetectionClauseFile `
            -FileName $InstalledFile `
            -Path $InstallFolder `
            -Existence
        }

        # registry detection clause
        $regDetClause = New-CMDetectionClauseRegistryKeyValue `
        -Hive 'LocalMachine' `
        -KeyName $RegKeyPath `
        -PropertyType 'String' `
        -ValueName $RegKeyName `
        -Value `
        -ExpectedValue $RegKeyValue `
        -ExpressionOperator 'IsEquals' `
        -Is64Bit

        # if uninstall location has been provided then set the uninstall
        # if not then set same for install and uninstall
        if ($UninstallContentLocation) {
            Add-CMScriptDeploymentType `
            -DeploymentTypeName $ApplicationName `
            -ApplicationName $ApplicationName `
            -InstallationBehaviorType 'InstallForSystem' `
            -LogonRequirementType 'WhetherOrNotUserLoggedOn' `
            -MaximumRuntimeMins $MaxRunTime `
            -EstimatedRuntimeMins $EstimatedRunTime `
            -AddRequirement $freeSpaceRule `
            -ContentLocation $ContentLocation `
            -UninstallOption 'Different' `
            -UninstallContentLocation $UninstallContentLocation `
            -InstallCommand "Deploy-Application.exe -AllowRebootPassThru -DeploymentType 'Install'" `
            -UninstallCommand "Deploy-Application.exe -AllowRebootPassThru -DeploymentType 'Uninstall'" `
            -AddDetectionClause $fileDetClause,$regDetClause
        } else {
            Add-CMScriptDeploymentType `
            -DeploymentTypeName $ApplicationName `
            -ApplicationName $ApplicationName `
            -InstallationBehaviorType 'InstallForSystem' `
            -LogonRequirementType 'WhetherOrNotUserLoggedOn' `
            -MaximumRuntimeMins $MaxRunTime `
            -EstimatedRuntimeMins $EstimatedRunTime `
            -AddRequirement $freeSpaceRule `
            -ContentLocation $ContentLocation `
            -InstallCommand "Deploy-Application.exe -AllowRebootPassThru -DeploymentType 'Install'" `
            -UninstallCommand "Deploy-Application.exe -AllowRebootPassThru -DeploymentType 'Uninstall'" `
            -AddDetectionClause $fileDetClause,$regDetClause
        }
    } else {
        # app already has deployment types, let's exit
        throw -Message "This app already has at least one deployment type. Exiting..."
    }
}

#endregion

#region New-SCCMApplicationPSADT4.1.x.ps1
function New-SCCMApplicationPSADT4.1.x {
    param (
        # ApplicationName
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationName,
        # Publisher
        [Parameter(Mandatory=$true)]
        [string]
        $Publisher,
        # Version
        [Parameter(Mandatory=$true)]
        [string]
        $Version,
        # Owner
        [Parameter(Mandatory=$true)]
        [string]
        $Owner,
        # Description
        [Parameter(Mandatory=$true)]
        [string]
        $Description,
        # IconPath - path to icon file on network drive
        [Parameter(Mandatory=$true)]
        [string]
        $IconPath,
        # ContentLocation - path to content on network drive
        [Parameter(Mandatory=$true)]
        [string]
        $ContentLocation,
        # Free space required (MB)
        [Parameter(Mandatory=$true)]
        [string]
        $SpaceRequired,
        # Folder where application gets installed
        [Parameter(Mandatory=$true)]
        [string]
        $InstallFolder,
        # Name of the installed file, including file extension
        [Parameter(Mandatory=$true)]
        [string]
        $InstalledFile,
        # Registry key path (don't include root e.g. hklm or hkey_local_machine)
        [Parameter(Mandatory=$true)]
        [string]
        $RegKeyPath,
        # Registry key name
        [Parameter(Mandatory=$true)]
        [string]
        $RegKeyName,
        # Registry key value
        [Parameter(Mandatory=$true)]
        [string]
        $RegKeyValue,
        # is64bit - whether or not the application is 64bit
        [Parameter(Mandatory=$false)]
        [switch]
        $Is64Bit,
        # Max run time
        [Parameter(Mandatory=$true)]
        [string]
        $MaxRunTime,
        # Estimated run time
        [Parameter(Mandatory=$true)]
        [string]
        $EstimatedRunTime,
        # Uninstall content location
        [Parameter(Mandatory=$false)]
        [string]
        $UninstallContentLocation
    )

    $ogLoc = Get-Location

    Set-Location -Path 'A00:\'

    # if app doesn't exist, create it
    if (-not(Get-CMApplication -Name $ApplicationName -Fast)) {
        New-CMApplication `
            -Owner $Owner `
            -SupportContact $Owner `
            -DefaultLanguageId 3081 <# en-AU #> `
            -IconLocationFile $IconPath `
            -LocalizedDescription $Description `
            -LocalizedName $ApplicationName `
            -Name $ApplicationName `
            -Publisher $Publisher `
            -SoftwareVersion $Version
    }

    $app = Get-CMApplication -Name $ApplicationName

    # if publisher folder doesn't exist, create it
    if (-not(Test-Path -Path ".\Application\$Publisher")) {
        New-CMFolder -Name $Publisher -ParentFolderPath '.\Application'
    }

    # move app into folder
    $app | Move-CMObject -FolderPath ".\Application\$Publisher"

    # create requirement rules
    $freeSpaceRule = Get-CMGlobalCondition -Name "Free disk space" |
        New-CMRequirementRuleFreeDiskSpaceValue `
            -PartitionOption 'System' `
            -RuleOperator 'GreaterThan' `
            -Value1 $SpaceRequired

    # check to see if application has deployment type
    # if app has no deployment types, create one
    if ($app.NumberOfDeploymentTypes -lt 1) {
        # file detection clause
        if ($Is64Bit) {
            $fileDetClause = New-CMDetectionClauseFile `
                -FileName $InstalledFile `
                -Path $InstallFolder `
                -Existence `
                -Is64Bit
        } else {
            $fileDetClause = New-CMDetectionClauseFile `
                -FileName $InstalledFile `
                -Path $InstallFolder `
                -Existence
        }

        # registry detection clause
        $regDetClause = New-CMDetectionClauseRegistryKeyValue `
            -Hive 'LocalMachine' `
            -KeyName $RegKeyPath `
            -PropertyType 'String' `
            -ValueName $RegKeyName `
            -Value `
            -ExpectedValue $RegKeyValue `
            -ExpressionOperator 'IsEquals' `
            -Is64Bit

        # if uninstall location has been provided then set the uninstall
        # if not then set same for install and uninstall
        if ($UninstallContentLocation) {
            Add-CMScriptDeploymentType `
                -DeploymentTypeName $ApplicationName `
                -ApplicationName $ApplicationName `
                -InstallationBehaviorType 'InstallForSystem' `
                -LogonRequirementType 'WhetherOrNotUserLoggedOn' `
                -MaximumRuntimeMins $MaxRunTime `
                -EstimatedRuntimeMins $EstimatedRunTime `
                -AddRequirement $freeSpaceRule `
                -ContentLocation $ContentLocation `
                -UninstallOption 'Different' `
                -UninstallContentLocation $UninstallContentLocation `
                -InstallCommand "Invoke-AppDeployToolkit.exe -DeploymentType Install" `
                -UninstallCommand "Invoke-AppDeployToolkit.exe -DeploymentType Uninstall" `
                -AddDetectionClause $fileDetClause,$regDetClause
        } else {
            Add-CMScriptDeploymentType `
                -DeploymentTypeName $ApplicationName `
                -ApplicationName $ApplicationName `
                -InstallationBehaviorType 'InstallForSystem' `
                -LogonRequirementType 'WhetherOrNotUserLoggedOn' `
                -MaximumRuntimeMins $MaxRunTime `
                -EstimatedRuntimeMins $EstimatedRunTime `
                -AddRequirement $freeSpaceRule `
                -ContentLocation $ContentLocation `
                -InstallCommand "Invoke-AppDeployToolkit.exe -DeploymentType Install" `
                -UninstallCommand "Invoke-AppDeployToolkit.exe -DeploymentType Uninstall" `
                -AddDetectionClause $fileDetClause,$regDetClause
        }
    } else {
        # app already has deployment types, let's exit
        throw "This app already has at least one deployment type. Exiting..."
    }

    Set-Location $ogLoc
}

#endregion

#region Remove-CodeSignature.ps1
<#
.SYNOPSIS
Removes a signature from a script or folder containing scripts.

.PARAMETER Path
Path to a script or a folder containing scripts.

.PARAMETER Recurse
Will recurse through folders when searching for scripts.

.INPUTS
[string]
File paths to a script or a folder containing scripts can be piped to this function.
[object]
An object with a FullName property (e.g. objects from Get-ChildItem) can be piped to this function.

.OUTPUTS
N/A

.EXAMPLE
PS> Remove-CodeSignature -Path "C:\sources\Example-Script.ps1"

.EXAMPLE
PS> Remove-CodeSignature -Path "C:\sources\repos\WDAC" -Recurse

.EXAMPLE
PS> Get-ChildItem -Path "C:\wdac" | Remove-CodeSignature

.NOTES
Author:     Matt McPhee
Version:    1.1
Created:    22-Jul-2025
Updated:    23-Jul-2025
#>
function Remove-CodeSignature {
    [CmdletBinding()]
    param (
        # Path - a filepath to a script file or folder containing script files
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({ Test-Path -Path $_ })]
        [Alias("FullName")]
        [string]
        $Path,
        # Recurse
        [Parameter(Mandatory=$false)]
        [switch]
        $Recurse
    )

    begin {
        # set up array to hold found scripts
        $allScripts = @()
    }

    process {
        # get scripts from each path that comes down the pipe
        if ($Recurse) {
            $scripts = Get-ChildItem -Path $Path -Include '*.ps1' -Recurse -ErrorAction Stop
        } else {
            $scripts = Get-ChildItem -Path $Path -Include '*.ps1' -ErrorAction Stop
        }

        $allScripts += $scripts
    }

    end {
        # check if we have found scripts
        if ($allScripts.Count -eq 0) {
            throw "No script files found in provided path(s)."
        }

        Write-Verbose "Found $($allScripts.Count) scripts to remove signature from."

        for ($i = 0; $i -lt $allScripts.Count; $i++) {
            Write-Progress -Activity "Removing signatures from scripts..." `
                -Status "Processing $($allScripts[$i].Name)" `
                -PercentComplete (($i / $allScripts.Count) * 100)

            $content = Get-Content -Path $allScripts[$i].FullName

            # caret is start of line
            $signatureLine = $content | Select-String '^# SIG # Begin signature block'

            # check if script contains signature block
            if ($null -eq $signatureLine) {
                Write-Verbose "No signature block found in $($allScripts[$i].FullName)"
                continue
            }

            # script content ends two lines before the script signature starts
            $lineNumber = $signatureLine.LineNumber - 2

            # new content is everything from the start up to the signature
            $newContent = $content[0..$lineNumber]

            # remove blank lines from end of file
            while ( ($newContent.Count -gt 0) -and ($newContent[-1].Trim() -eq "") ) {
                $newContent = $newContent[0..($newContent.Count - 2)]
            }

            # set content adds a new line after content
            Set-Content -Path $allScripts[$i].FullName -Value $newContent
        }
    }
}

#endregion

#region Remove-RegistryKey.ps1
function Remove-RegistryKey {
    param (
        # the path to the location containing registry items
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key,
        # the name of the registry item
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        # recurse - specify to delete all items in path
        [Parameter()]
        [switch]
        $Recurse
    )

    try {
        if (-not $Name) {
            if (Test-Path -LiteralPath $Key -ErrorAction 'Stop') {
                if ($Recurse) {
                    Remove-Item -LiteralPath $Key -Force -Recurse -ErrorAction 'Stop'
                } else {
                    if ($null -eq (Get-ChildItem -LiteralPath $Key -ErrorAction 'Stop')) {
                        Remove-Item -LiteralPath $Key -Force -ErrorAction 'Stop'
                    } else {
                        throw "Unable to delete child keys of $Key without recurse switch."
                    }
                }
            }
        } else {
            if (Test-Path -LiteralPath $Key -ErrorAction 'Stop') {
                Remove-ItemProperty -LiteralPath $Key -Name $Name -Force -ErrorAction 'Stop'
            } else {
                Write-Host "Unable to delete registry value $Key $Name because registry key does not exist."
            }
        }
    } catch {
        throw "Failed to delete registry key $Key. $($_.Exception.Message)"
    }
}

#endregion

#region Repair-ConfigMGRClient.ps1
<#
.SYNOPSIS
    Runs health check on ConfigMGR Client
#>
function Repair-ConfigMGRClient {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName
    )

    # variables
    $sleepTime = 1

    # retrieve machine policy
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # retrieve user policy
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000026}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # hardware inventory
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000001}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # application deployment evaluation
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000121}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # software update scan cycle
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # software update eval cycle
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000114}" `
    -ErrorAction SilentlyContinue
}

#endregion

#region Reset-WMI.ps1
function Reset-WMI {
    Set-Service -Name Winmgmt -StartupType Disabled
    Stop-Service -Name Winmgmt -Force
    Start-Sleep 5
    $wmiDlls = Get-ChildItem -Path C:\Windows\system32\wbem\* -Include *.dll
    $wmiDlls | ForEach-Object { 
        Start-Process -FilePath "C:\Windows\system32\regsvr32.exe" `
            -ArgumentList $_.FullName
        Write-Host "$($_.FullName) has been regsvr'd."
        Start-Sleep -Milliseconds 200
    }
    Start-Sleep 5
    Start-Process -FilePath "C:\Windows\System32\wbem\WmiPrvSE.exe" `
        -ArgumentList "/regserver"
    Start-Sleep 5
    Start-Process -FilePath "C:\Windows\System32\wbem\winmgmt.exe" `
        -ArgumentList "/regserver"
    Start-Sleep 5
    Set-Service -Name Winmgmt -StartupType Automatic
    Start-Service -Name Winmgmt
    Start-Sleep 5
    $wmiMofs = Get-ChildItem -Path C:\Windows\system32\wbem\* `
        -Include *.mof, *.mfl `
        -Recurse
    $wmiMofs | ForEach-Object {
        Start-Process -FilePath "C:\Windows\System32\wbem\mofcomp.exe" `
            -ArgumentList $_.FullName
        Write-Host "$($_.FullName) has been recompiled."
        Start-Sleep -Milliseconds 200
    }
}

#endregion

#region Reset-WMINoUninstall.ps1
function Reset-WMINoUninstall {
    Set-Service -Name Winmgmt -StartupType Disabled
    Stop-Service -Name Winmgmt -Force
    Start-Sleep 5
    $wmiDlls = Get-ChildItem -Path C:\Windows\system32\wbem\* -Include *.dll
    $wmiDlls | ForEach-Object { 
        Start-Process -FilePath "C:\Windows\system32\regsvr32.exe" `
            -ArgumentList $_.FullName
        Write-Host "$($_.FullName) has been regsvr'd."
        Start-Sleep -Milliseconds 100
    }
    Start-Sleep 5
    Start-Process -FilePath "C:\Windows\System32\wbem\WmiPrvSE.exe" `
        -ArgumentList "/regserver"
    Start-Sleep 5
    Start-Process -FilePath "C:\Windows\System32\wbem\winmgmt.exe" `
        -ArgumentList "/regserver"
    Start-Sleep 5
    Set-Service -Name Winmgmt -StartupType Automatic
    Start-Service -Name Winmgmt
    Start-Sleep 5
    $wmiMofs = Get-ChildItem -Path C:\Windows\system32\wbem\* `
        -Include *.mof, *.mfl `
        -Exclude *uninstall* `
        -Recurse
    $wmiMofs | ForEach-Object {
        Start-Process -FilePath "C:\Windows\System32\wbem\mofcomp.exe" `
            -ArgumentList $_.FullName
        Write-Host "$($_.FullName) has been recompiled."
        Start-Sleep -Milliseconds 100
    }
}

#endregion

#region Resize-Image.ps1
function Resize-Image {
    [CmdletBinding()]
    param (
        # input image file
        [Parameter(Mandatory=$true)]
        [string]
        $InputFile,
        # output image file
        [Parameter(Mandatory=$true)]
        [string]
        $OutputFile,
        # a value in percentage to scale the image
        [Parameter(Mandatory=$true)]
        [Int32]
        $Scale
    )
    # add drawing assembly
    Add-Type -AssemblyName System.Drawing

    # open the image file
    $img = [System.Drawing.Image]::FromFile((Get-Item $InputFile))

    # define new res
    [Int32]$newWidth = $img.Width * ($Scale / 100)
    [Int32]$newHeight = $img.Height * ($Scale / 100)

    # create empty canvas for the new image
    $imgNew = New-Object System.Drawing.Bitmap($newWidth,$newHeight)

    # draw image on canvas
    $graphic = [System.Drawing.Graphics]::FromImage($imgNew)
    $graphic.DrawImage($img, 0, 0, $newWidth, $newHeight)

    # dispose and save
    $graphic.Dispose()
    $img.Dispose()
    $imgNew.Save($OutputFile)
    $imgNew.Dispose()
}

#endregion

#region Set-NewWinServer.ps1
function Set-NewWinServer {
    [CmdletBinding()]
    param (
        # IPAddress
        [Parameter(Mandatory)]
        [string]
        $IPAddress,
        # DNSServerOne
        [Parameter(Mandatory)]
        [string]
        $DNSServerOne,
        # DNSServerTwo
        [Parameter(Mandatory)]
        [string]
        $DNSServerTwo
    )

    $interfaceAlias = "Ethernet"
    $prefixLength = 24
    $defaultGateway = "10.97.105.254"
    $dnsServers = @($DNSServerOne, $DNSServerTwo)

    if (-not ([System.Net.IPAddress]::TryParse($IPAddress, [ref]$null))) {
        throw "Invalid IPAddress: $IPAddress"
    }

    if (-not ([System.Net.IPAddress]::TryParse($DNSServerOne, [ref]$null))) {
        throw "Invalid IPAddress: $DNSServerOne"
    }

    if (-not ([System.Net.IPAddress]::TryParse($DNSServerTwo, [ref]$null))) {
        throw "Invalid IPAddress: $DNSServerTwo"
    }

    # set ip address
    New-NetIPAddress -InterfaceAlias $interfaceAlias `
        -IPAddress $IPAddress `
        -PrefixLength $prefixLength `
        -DefaultGateway $defaultGateway

    # set dns servers
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $dnsServers
}

#endregion

#region Set-RegistryKey.ps1
<#
.SYNOPSIS
Creates a registry key or updates it with new data if it already exists.
.DESCRIPTION
Creates a registry key or updates it with new data if it already exists.
.NOTES
This was taken from Powershell App Deployment Toolkit and modified to be a standalone function.
.PARAMETER Key
The path to the location containing the registry item
.PARAMETER Name
The name of the registry item
.PARAMETER Value
The value to set the registry item to
.PARAMETER Type
The type of the registry item - must be one of a number of types
#>
function Set-RegistryKey {
    param (
        # the path to the registry key containing registry items
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key,
        # the name of the registry item
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        # the value of the registry item
        [Parameter()]
        [string]
        $Value,
        # the registry item type - defaults to string
        [Parameter()]
        [ValidateSet('Binary','DWord','ExpandString','MultiString','None','QWord','String','Unknown')]
        [Microsoft.Win32.RegistryValueKind]
        $Type = 'String'
    )

    process {
        try {
            # create registry key if it doesn't exist
            if (-not (Test-Path -LiteralPath $Key -ErrorAction 'Stop')) {
                New-Item -Path $Key -Force -ErrorAction 'Stop'
            }

            # if name supplied, set the value if it doesn't exist or update it if it does exist
            if ($Name) {
                if (-not(Get-ItemProperty -LiteralPath $Key -Name $Name -ErrorAction 'SilentlyContinue')) {
                    New-ItemProperty -LiteralPath $Key -Name $Name -Value $Value -PropertyType $Type -ErrorAction 'Stop'
                } else {
                    Set-ItemProperty -LiteralPath $Key -Name $Name -Value $Value -ErrorAction 'Stop'
                }
            }
        } catch {
            throw "Failed to create or set registry key [$Key]: $($_.Exception.Message)"
        }
    }
}

#endregion

#region Uninstall-AdobeApps.ps1
<#
.SYNOPSIS
This script will search the registry for vulnerable Adobe suite uninstallation
keys. It will then execute the registry key's UninstallString.
#>
function Uninstall-AdobeApps {
    #region vars
    $logPath = 'C:\Windows\Logs\Software\Uninstall-AdobeApps.log'
    # the below registry keys were retrieved from the security portal
    # spreadsheet located in Teams -> Endpoint -> Vulnerabilities
    $regPaths = @(
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\AME_24_6_1',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\IDSN_17_4_2',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\IDSN_18_5_4',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ILST_25_0_1',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ILST_27_7',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ILST_27_8',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\KBRG_13_0_9',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PHSP_22_2',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PHSP_26_4',
        'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\DRWV_21_4'
    )

    Write-Log -Message "***********************************************************" -Level Info -Path $logPath
    Write-Log -Message "******************** SCRIPT START ***********************" -Level Info -Path $logPath
    Write-Log -Message "***********************************************************" -Level Info -Path $logPath

    $apps = Get-InstalledApps | Where-Object { $_.DisplayName -like "*adobe*" }

    Write-Log -Message "Searching for installation of vulnerable Adobe apps..." -Level Info -Path $logPath

    $processString = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\HDBox\Setup.exe"
    if (Test-Path -Path $processString) {
        Write-Log -Message "Found uninstaller process: $processString" -Level Info -Path $logPath
    } else {
        Write-Log -Message "Uninstaller not found! Exiting script..." -Level Error -Path $logPath
        return
    }

    foreach ($app in $apps) {
        Write-Log -Message "Current app: $($app.DisplayName)" -Level Info -Path $logPath

        foreach ($regPath in $regPaths) {
            if ($app.PsPath -like "*$regPath") {
                Write-Log -Message "Found $($app.DisplayName) with reg key $regPath that matches:" -Level Info -Path $logPath
                Write-Log -Message $app.PsPath -Level Info -Path $logPath
                # build our own uninstall parameters
                $sapCodeIndex = $app.UninstallString.IndexOf('sapCode=')
                $sapCode = $app.UninstallString.substring(($sapCodeIndex + 'sapCode='.Length), 4)
                Write-Log -Message "sapCode: $sapCode" -Level Info -Path $logPath

                $baseVersionIndex = $app.UninstallString.IndexOf('productVersion=')
                $baseVersion = $app.UninstallString.substring(($baseVersionIndex + 'productVersion='.Length), 2)
                $baseVersion = "$baseVersion.0"
                Write-Log -Message "baseVersion: $baseVersion" -Level Info -Path $logPath

                $paramString = "--uninstall=1 --sapCode=$sapCode --baseVersion=$baseVersion --platform=win64 --deleteUserPreferences=false"

                $uninstallString = "$processString $paramString"

                Write-Log -Message "The process string is: $processString" -Level Info -Path $logPath
                Write-Log -Message "The param string is: $paramString" -Level Info -Path $logPath

                Write-Log -Message "Proceeding to uninstall using uninstall string:" -Level Info -Path $logPath
                Write-Log -Message $uninstallString -Level Info -Path $logPath

                Start-Process -FilePath $processString -ArgumentList $paramString -WindowStyle Hidden

                if (Test-Path -Path "Registry::$regPath") {
                    Write-Log -Message "Something went wrong! $($app.DisplayName) not uninstalled!" -Level Error -Path $logPath
                } else {
                    Write-Log -Message "Successfully uninstalled $($app.DisplayName)" -Level Info -Path $logPath
                }
            }
        }
    }

    Write-Log -Message "***********************************************************" -Level Info -Path $logPath
    Write-Log -Message "********************* SCRIPT END ************************" -Level Info -Path $logPath
    Write-Log -Message "***********************************************************" -Level Info -Path $logPath
    Write-Log -Message "" -Level Info -Path $logPath
}

#endregion

#region Uninstall-HP7740Driver.ps1
function Uninstall-HP7740Driver {
    # vars
    $driverName = "HP OfficeJet Pro 7740 series"

    # remove driver from driver store
    Write-Log -Message "Running: pnputil.exe /d .\Basic_Webpack_x64-40.16.1234-OJ7740_Basicx64_Webpack\hpygid20.inf /f"
    try {
        Invoke-Expression "pnputil.exe /d .\Basic_Webpack_x64-40.16.1234-OJ7740_Basicx64_Webpack\hpygid20.inf /f"
        Write-Log "Success"
    } catch {
        Write-Log -Message "There was an error running pnputil. The error was: $Error"
    }

    # uninstall the driver
    Write-Log -Message "Running: Remove-PrinterDriver -Name $driverName"
    try {
        Remove-PrinterDriver -Name "$driverName"
        Write-Log "Success"
    } catch {
        Write-Log -Message "There was an error running Remove-PrinterDriver. The error was: $Error"
    }
}

#endregion

#region Update-AdobeApps.ps1
function Update-AdobeApps {
    $rumPath = "C:\Program Files (x86)\Common Files\Adobe\OOBE_Enterprise\RemoteUpdateManager\RemoteUpdateManager.exe"
    $logPath = "C:\Windows\Logs\Software\Update-AdobeApps.log"

    try {
        # attempt to run RemoteUpdateManager.exe
        Start-Process -FilePath $rumPath -WindowStyle 'Hidden' -ErrorAction 'Stop'
        Write-Log -Message "RemoteUpdateManager.exe launched." -Level 'Info' -Path $logPath
    } catch {
        Write-Log -Message "Encountered this error when attempting to launch RemoteUpdateManager.exe:" -Level 'Error' -Path $logPath
        Write-Log -Message "$_" -Level 'Error' -Path $logPath
    }
}

#endregion

#region Get-MailboxSizes.ps1
<#
.SYNOPSIS
    Gets a list of mailboxes using ExchangeOnline and calculates then sorts by usage
.DESCRIPTION
    Gets a list of mailboxes using ExchangeOnline and calculates then sorts by usage
.PARAMETER ResultSize
    The desired number of mailboxes to return. Defaults to unlimited.
.PARAMETER ExportCsvPath
    The desired output location of the csv file.
.OUTPUTS
    A table of data containing mailbox displayname, itemcount, totalitemsize and 
    totalcapacity
.EXAMPLE
    Get-MailboxSizes
.EXAMPLE
    Get-MailboxSizes -ResultSize 30
.EXAMPLE
    Get-MailboxSizes -ExportCsvPath C:\sources\mailbox-sizes.csv
.NOTES
    You must use Connect-ExchangeOnline before using this cmdlet instead of
    having to verify 
    
    Name: Get-MailboxSizes.ps1
    Author: Matt McPhee
    Version: 1.0 20/08/2024
#>
function Get-MailboxSizes {
    [CmdletBinding()]
    param (
        # ResultSize - defaults to unlimited
        [Parameter(Mandatory=$false)]
        [string]
        $ResultSize = "Unlimited",
        # Export-Csv filepath
        [Parameter(Mandatory=$false)]
        [string]
        $ExportCsvPath
    )
    # set up array to add objects to
    $allMailboxes = @()
    # get mailbox
    $mailboxes = Get-Mailbox -ResultSize $ResultSize
    # loop through mailboxes and pull out info we want
    for ($i = 0; $i -lt $mailboxes.Count; $i++) {
        # get mailbox upn
        $mailboxUPN = $mailboxes[$i].UserPrincipalName
        # get the capacity using prohibitsendquota as a rough estimate
        # split on the first open bracket so the string looks like: XX GB
        $mailboxCapacity = $mailboxes[$i].ProhibitSendQuota.Split("(")[0]
        # get mailbox statistics and select info we need from it
        $mailboxStats = $mailboxes[$i] | Get-MailboxStatistics | Select-Object `
        DisplayName, MailboxTypeDetail, ItemCount, @{
            # use a calculated property to get total size in MBs
            name        = "TotalItemSize (GB)";
            expression  = {
                # we have to do some splitting and replacing to get bytes
                # the string will look like this 5.844 GB (6,275,060,182 bytes)
                $totalItemSizeString = $_.TotalItemSize.ToString()
                # split on the first open bracket
                $totalItemSizeFirstSplit = $totalItemSizeString.split("(")[1]
                # string now looks like this 6,275,060,182 bytes)
                # split on the space
                $totalItemSizeSecondSplit = $totalItemSizeFirstSplit.split(" ")[0]
                # string now looks like this 6,275,060,182
                # replace commas with nothing
                $totalItemSizeBytes = $totalItemSizeSecondSplit.replace(",","")
                # string now looks like this 6275060182
                # divide it by 1 MB to get size in MBs
                $totalItemSizeGigs = $totalItemSizeBytes / 1GB
                # round it to 2 decimal places
                $totalItemSizeFormattedGB = [math]::Round($totalItemSizeGigs,2)
                return $totalItemSizeFormattedGB
            }
        }
        # add object with info to the array from earlier
        $allMailboxes += [PSCustomObject]@{
            "UserPrincipalName"         = $mailboxUPN
            "DisplayName"               = $mailboxStats.DisplayName
            "MailboxType"               = $mailboxStats.MailboxTypeDetail
            "ItemCount"                 = $mailboxStats.ItemCount
            "TotalItemSize (GB)"        = $mailboxStats."TotalItemSize (GB)"
            "TotalCapacity"             = $mailboxCapacity
        }
    }
    # sort by TotalItemSize (GB)
    $mailboxStatsSortedByGB = $allMailboxes | 
        Sort-Object "TotalItemSize (GB)" -Descending
    # display results
    $mailboxStatsSortedByGB | Out-GridView
    # if exportcsv is set, then export to csv
    if ($PSBoundParameters.ContainsKey("ExportCSVPath")) {
        $allMailboxes | Export-CSV $ExportCsvPath -NoTypeInformation -Force
    }
}
#endregion

#region Set-ArchiveAfter180.ps1
function Set-ArchiveAfter180 {
    [CmdletBinding()]
    param (
        # User list path to txt file containing users
        [Parameter(Mandatory=$true)]
        [string]
        $UserListPath
    )
    $users = Get-Content $UserListPath
    foreach ($user in $users) {
        $mailbox = Get-RemoteMailbox $user | Select-Object CustomAttribute14
        $ca14 = $mailbox.CustomAttribute14
        if ($ca14 -ne "") {
            $newCa14 = ($ca14 += ",ArchiveAfter180")
            Set-RemoteMailbox -Identity $user -CustomAttribute14 $newCa14
        } else {
            Set-RemoteMailbox -Identity $user -CustomAttribute14 "ArchiveAfter180"
        }
    }
}

#endregion

#region Convert-EdgeFavourites.ps1
function Convert-EdgeFavourites {
    [CmdletBinding()]
    param (
        
    )

    
}
#endregion

#region Get-AppLockerGPOPolicy.ps1
function Get-AppLockerGPOPolicy {
    [CmdletBinding()]
    param (
        # GpoName
        [Parameter(Mandatory)]
        [string]
        $GpoName,
        # FilePath
        [Parameter(Mandatory = $false)]
        [ValidateScript({
            $dir = Split-Path $_ -Parent
            if (Test-Path $dir) {
                return $true
            } else {
                throw "LogPath: The folder path '$dir' does not exist."
            }
        })]
        [string]
        $FilePath,
        # Formatted
        [Parameter(Mandatory = $false)]
        [switch]
        $Formatted
    )
    
    try {
        # Get the GPO path
        $actualGpo = Get-GPO -Name $GpoName
        if ($actualGpo.Count -lt 1) {
            throw "Could not find GPO with name: $GpoName"
        }
        if ($actualGpo.Count -gt 1) {
            throw "Found more than one group name. Be more specific."
        }

        $gpoPath = $actualGpo.Path

        # get the applocker policy
        $applockerPolicy = Get-AppLockerPolicy -Ldap "LDAP://$gpoPath" -Domain -Xml

        if ($Formatted) {
            $applockerPolicy = Format-Xml -XmlString $applockerPolicy
        }

        if ($FilePath) {
            $applockerPolicy | Out-File -FilePath $FilePath -Force -Encoding utf8
            return
        }

        $applockerPolicy
    } catch {
        throw $_
    }
}
#endregion

#region Get-GPOFromADGroupName.ps1
function Get-GPOFromADGroupName {
    param (
        # GroupName
        [Parameter(Mandatory = $true)]
        [string]
        $GroupName
    )
    
    try {
        # Get the actual group name
        $actualGroupName = (Get-ADGroup -Filter { Name -like $GroupName }).Name
        if ($actualGroupName.Count -lt 1) {
            throw "Could not find AD group with name: $GroupName"
        }
        if ($actualGroupName.Count -gt 1) {
            throw "Found more than one group name. Be more specific."
        }

        # Find all GPOs in the Domain
        $allGPOs = Get-GPO -All

        # Loop through each GPO and check its security filtering
        foreach ($GPO in $allGPOs) {
            # Get the security filtering settings for the current GPO
            $GPOPermissions = Get-GPPermission -Guid $GPO.Id -All

            # Check if the group is listed in the security permissions
            if ($GPOPermissions.Trustee.Name -contains $actualGroupName) {
                Write-Host "Found GPO: $($GPO.DisplayName)"
                Write-Host "It is linked to:"
        
                # Find the OUs the GPO is linked to
                Get-GPO -Guid $GPO.Id | Get-GPOReport -ReportType Xml | ConvertTo-Xml | Select-String '<LinksFrom>'
            }
        }
    } catch {
        throw $_
    }
}

#endregion

#region Get-GPOFromXmlString.ps1
function Get-GPOFromXmlString {

    [CmdletBinding()]
    param (
        # XmlString
        [Parameter(Mandatory)]
        [string]
        $XmlString
    )
        
    $tempPath = 'C:\sources\xml\gpo_report.xml'

    if (-not (Test-Path -Path (Split-Path $tempPath -Parent))) {
        New-Item -Path (Split-Path $tempPath -Parent) -ItemType Directory -Force
    }

    Write-Host "Searching GPOs using search term: $XmlString" -ForegroundColor 'Yellow'

    $allGPOs = Get-GPO -All

    foreach ($GPO in $allGPOs) {
        Get-GPOReport -Guid $GPO.Id -ReportType Xml -Path $tempPath

        [xml]$GPOXml = Get-Content -Path $tempPath

        if ($GPOXml) {
            $result = $GPOXml.GPO.Computer.ExtensionData | Where-Object { $_.Name -like $XmlString }

            if ($result) {
                Write-Host "Found: $($GPO.DisplayName) with ID: $($GPO.Id)" -ForegroundColor 'Green'
            }
        }
    }

    Remove-Item -Path $tempPath -Force
    Write-Host "Scan complete." -ForegroundColor 'Yellow'
}

#endregion

#region Add-RemediationScriptAssignment.ps1
function Add-RemediationScriptAssignment {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptId,

        [Parameter(Mandatory = $true)]
        [string]$GroupId,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Daily", "Hourly", "RunOnce")]
        [string]$ScheduleType = "Daily",

        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,

        [Parameter(Mandatory = $false)]
        [bool]$RunRemediationScript = $true,

        [Parameter(Mandatory = $false)]
        [string]$FilterId,

        [Parameter(Mandatory = $false)]
        [ValidateSet("include", "exclude")]
        [string]$FilterType = "include",

        [Parameter(Mandatory = $false)]
        [switch]$Append
    )

    # 1. Build Target Object
    $target = [ordered]@{
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
        "groupId"     = $GroupId
    }

    if ($FilterId) {
        $target["deviceAndAppManagementAssignmentFilterId"]   = $FilterId
        $target["deviceAndAppManagementAssignmentFilterType"] = $FilterType
    }

    # 2. Build Schedule Object
    switch ($ScheduleType) {
        "Daily" {
            $schedule = [ordered]@{
                "@odata.type" = "#microsoft.graph.deviceHealthScriptDailySchedule"
                "interval"    = $Interval
            }
        }
        "Hourly" {
            $schedule = [ordered]@{
                "@odata.type" = "#microsoft.graph.deviceHealthScriptHourlySchedule"
                "interval"    = $Interval
            }
        }
        "RunOnce" {
            $schedule = [ordered]@{
                "@odata.type"   = "#microsoft.graph.deviceHealthScriptRunOnceSchedule"
                "date"          = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
                "time"          = "00:00:00"
                "useUtc"        = $true
            }
        }
    }

    # 3. Create the new assignment payload item
    $newAssignment = [ordered]@{
        "@odata.type"          = "#microsoft.graph.deviceHealthScriptAssignment"
        "target"               = $target
        "runSchedule"          = $schedule
        "runRemediationScript" = $RunRemediationScript
    }

    $assignmentsList = [System.Collections.Generic.List[object]]::new()

    # 4. If appending, fetch existing assignments first
    if ($Append) {
        $existingUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assignments"

        try {
            $existing = (Invoke-MgGraphRequest -Method GET -Uri $existingUri -ErrorAction Stop).value
        } catch {
            Write-Error "Failed to retrieve existing assignments for script '$ScriptId': $_"
            return
        }

        foreach ($item in $existing) {
            # Prevent duplicate assignment to the same group ID
            if ($item.target.groupId -eq $GroupId) {
                Write-Warning "Group ID $GroupId is already assigned. Updating its configuration."
                continue
            }

            $cleanedItem = [ordered]@{
                "@odata.type"          = "#microsoft.graph.deviceHealthScriptAssignment"
                "target"               = $item.target
                "runSchedule"          = $item.runSchedule
                "runRemediationScript" = $item.runRemediationScript
            }
            $assignmentsList.Add($cleanedItem)
        }
    }

    $assignmentsList.Add($newAssignment)

    # 5. Send the assign payload to Graph API
    $assignUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assign"
    $body = @{
        "deviceHealthScriptAssignments" = $assignmentsList
    } | ConvertTo-Json -Depth 10

    $action = if ($Append) {
        "Add assignment on top of any existing assignments"
    } else {
        "Replace all assignments with this one"
    }

    if ($PSCmdlet.ShouldProcess($ScriptId, $action)) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $body -ContentType "application/json"
            Write-Information "Successfully updated assignments for Remediation Script: $ScriptId"
        }
        catch {
            Write-Error "Failed to assign script: $_"
        }
    }
}

#endregion

#region Check-IntuneAppState.ps1
function Check-IntuneAppState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogicAppUrl,
        [Parameter(Mandatory=$false)]
        [string]$StateFilePath = "C:\ProgramData\IntuneMonitor\app_state.csv"
    )

    # Ensure data directory exists
    $directory = Split-Path -Path $StateFilePath -Parent
    if (-not (Test-Path $directory)) {
        $null = New-Item -Path $directory -ItemType Directory -Force
    }

    # 1. Collect current Win32 app registry state
    $regBasePath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"
    $currentApps = @()

    if (Test-Path $regBasePath) {
        # Scan subkeys 2 levels deep: Win32Apps\<ContextGUID>\<AppGUID>
        $contextKeys = Get-ChildItem -Path $regBasePath -ErrorAction SilentlyContinue

        foreach ($context in $contextKeys) {
            $appKeys = Get-ChildItem -Path $context.PSPath -ErrorAction SilentlyContinue

            foreach ($app in $appKeys) {
                # Exclude special IME utility subkeys like GRS or Reporting
                if ($app.PSChildName -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
                    $installExCode = $app.GetValue("InstallExCode", $null)
                    $exitCode      = $app.GetValue("ExitCode", $null)

                    if ($null -ne $installExCode) {
                        $currentApps += [PSCustomObject]@{
                            AppId         = $app.PSChildName
                            ContextId     = $context.PSChildName
                            ExitCode      = [string]$exitCode
                            InstallExCode = [string]$installExCode
                            Status        = if ($installExCode -eq 0) { "Success" } else { "Failed" }
                            LastEvaluated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        }
                    }
                }
            }
        }
    }

    # 2. Check if a baseline snapshot exists
    if (-not (Test-Path $StateFilePath)) {
        # First run: Save baseline without firing historical alerts
        $currentApps | Export-Csv -Path $StateFilePath -NoTypeInformation
        Write-Host "Baseline state snapshot created with $($currentApps.Count) app entries." -ForegroundColor Cyan
        exit 0
    }

    # 3. Load previous state and detect new or changed failures
    $previousApps = Import-Csv -Path $StateFilePath
    $previousLookup = @{}
    foreach ($item in $previousApps) {
        $previousLookup[$item.AppId] = $item
    }

    foreach ($app in $currentApps) {
        if ($app.Status -eq "Failed") {
            $isNewFailure = $false

            if (-not $previousLookup.ContainsKey($app.AppId)) {
                # Brand new app targeted that failed on first attempt
                $isNewFailure = $true
            }
            elseif ($previousLookup[$app.AppId].Status -ne "Failed" -or 
                    $previousLookup[$app.AppId].InstallExCode -ne $app.InstallExCode) {
                # App previously succeeded or had a different error code
                $isNewFailure = $true
            }

            if ($isNewFailure) {
                Write-Host "New failure detected for App ID: $($app.AppId)" -ForegroundColor Red

                # Format Intune error code to Hex representation if negative
                $hexError = if ([int64]$app.InstallExCode -lt 0) {
                    "0x{0:X8}" -f ([int64]$app.InstallExCode -band 0xFFFFFFFF)
                } else {
                    $app.InstallExCode
                }

                $payload = @{
                    deviceName = $env:COMPUTERNAME
                    appName    = "Win32 App (ID: $($app.AppId))"
                    errorCode  = "Installer Exit: $($app.ExitCode) | Intune HRESULT: $hexError"
                    timestamp  = $app.LastEvaluated
                } | ConvertTo-Json

                try {
                    Invoke-RestMethod -Uri $LogicAppUrl -Method Post -ContentType "application/json" -Body $payload
                    Write-Host "Alert dispatched to Logic App." -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to send alert: $_"
                }
            }
        }
    }

    # 4. Update the CSV snapshot to the current state
    $currentApps | Export-Csv -Path $StateFilePath -NoTypeInformation
}
#endregion

#region Connect-Tenant.ps1
function Connect-Tenant {
    [CmdletBinding()]
    param (
        # Environment
        [Parameter(Mandatory)]
        [ValidateSet("Prod","Dev")]
        [string]
        $Environment,
        # Scopes
        [Parameter(Mandatory=$false)]
        [string[]]
        $Scopes
    )
    
    $curContext = Get-MgContext
    if ($curContext) {
        try {
            Disconnect-MgGraph -ErrorAction Stop | Out-Null
        } catch {
            throw "Error: $($_.Exception.Message)"
        }
    }

    $tenants = @{
        "Prod" = "9a2a4ae5-8ac1-460b-90f0-bb3c8516df35"
        "Dev" = "cab2b5b9-c306-4307-a8ae-402a7693c71e"
    }

    $targetId = $tenants[$Environment]

    try {
        Get-BlockLetters $Environment | Write-Host -ForegroundColor Green
        Connect-MgGraph -TenantId $targetId -Scopes $Scopes -ContextScope 'Process' -ErrorAction Stop | Out-Null
        Get-BlockLetters 'Connected!' -Colour Green
    } catch {
        throw "Error: $($_.Exception.Message)"
    }
}

#endregion

#region Convert-Base64.ps1
function Convert-Base64 {
    [CmdletBinding()]
    param (
        # base 64 string
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]
        $Base64String
    )

    process {
        $bytes = [System.Convert]::FromBase64String($Base64String)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        return $content
    }
}

#endregion

#region Convert-SCCMAppToIntune.ps1
function Convert-SCCMAppToIntune {
    [CmdletBinding()]
    param (
        # ApplicationName - exact name as it appears in SCCM
        [Parameter(Mandatory)]
        [string]$ApplicationName,

        # IconPath - path to image icon
        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "$_ not found or is a folder instead of a file."
            } elseif ($_ -notlike "*.png" -and $_ -notlike "*.jpg") {
                throw "$_ is not a valid image file path ending in png or jpg."
            } else {
                return $true
            }
        })]
        [string]$IconPath,

        # InstalledApplicationSizeMB
        [Parameter(Mandatory)]
        [int]$InstalledApplicationSizeMB,

        # Developer - author of the application (optional)
        [Parameter(Mandatory = $false)]
        [string]$Developer,

        # Owner - product owner of the application within the organization (optional)
        [Parameter(Mandatory = $false)]
        [string]$Owner,

        # Notes - optional
        [Parameter(Mandatory = $false)]
        [string]$Notes,

        # InformationURL - link to a knowledge base item with further info (optional)
        [Parameter(Mandatory = $false)]
        [string]$InformationURL,

        # PrivacyURL - link to the app's privacy policy (optional)
        [Parameter(Mandatory = $false)]
        [string]$PrivacyURL,

        # CompanyPortalFeaturedApp - whether to feature the app in company portal (optional, defaults to false)
        [Parameter(Mandatory = $false)]
        [bool]$CompanyPortalFeaturedApp = $false,

        # CategoryName - specify a single or multiple categories to categorize the app (optional)
        [Parameter(Mandatory = $false)]
        [string[]]$CategoryName,

        # RestartBehavior - restart behavior if app requires restart (optional, defaults to basedOnReturnCode)
        [Parameter(Mandatory = $false)]
        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$RestartBehavior = "basedOnReturnCode",

        # InstallExperience - install as system or user (optional, default SYSTEM)
        [Parameter(Mandatory = $false)]
        [ValidateSet("SYSTEM", "User")]
        [string]$InstallExperience = "SYSTEM",

        # InstallCommandLine - install command line (optional)
        [Parameter(Mandatory = $false)]
        [string]$InstallCommandLine,

        # UninstallCommandLine - uninstall command line (optional)
        [Parameter(Mandatory = $false)]
        [string]$UninstallCommandLine,

        # ApplicationExePath - path to main exe on the client machine (will be used for detection if provided)
        [Parameter(Mandatory = $false)]
        [string]$ApplicationExePath,

        # RegKeyPath - registry path that holds displayversion value name on the client machine
        # (will be used for detection if provided)
        # Must include HKLM\ or HKEY_LOCAL_MACHINE\ at the start (or whatever registry hive)
        [Parameter(Mandatory = $false)]
        [string]$RegKeyPath,

        # DisplayVersion - the version value that appears in the registry on the client machine (will be used for detection if provided)
        [Parameter(Mandatory = $false)]
        [string]$DisplayVersion
    )

    # get app
    try {
        $ogLoc = Get-Location
        Set-Location "A00:"
        $app = Get-CMApplication -Name $ApplicationName
        Set-Location $ogLoc
    } catch {
        throw "Could not find application with that name: $_"
    }

    # pull out info from sdmpackagexml
    [xml]$appxml = $app.SDMPackageXml
    $appxmlDisplayInfo = $appxml.AppMgmtDigest.Application.DisplayInfo.Info
    $appXmlCustomData = $appxml.AppMgmtDigest.DeploymentType.Installer.CustomData

    $displayName = $appxmlDisplayInfo.Title
    $description = $appxmlDisplayInfo.Description
    $publisher = $appxmlDisplayInfo.Publisher
    $appVersion = $appxmlDisplayInfo.Version

    # base folder and installer file are two separate elements in xml
    $installerFile = $appXmlCustomData.InstallCommandLine -split " " |
        Select-Object -First 1
    $sourcePathBase = $appxml.AppMgmtDigest.DeploymentType.Installer.Contents.Content |
        Where-Object { $_.Location -notlike "*\Uninstall\*" } |
        Select-Object -ExpandProperty Location
    $sourcePath = $sourcePathBase + $installerFile

    # use exe path if provided or try to pull it out from sccm
    if ($PSBoundParameters["ApplicationExePath"]) {
        $applicationExePath = $ApplicationExePath
    } else {
        $appPathBase = $appXmlCustomData.EnhancedDetectionMethod.Settings.File.Path
        $appPathExe = $appXmlCustomData.EnhancedDetectionMethod.Settings.File.Filter

        if ([string]::IsNullOrEmpty($appPathBase) -or [string]::IsNullOrEmpty($appPathExe)) {
            $msg = "Unable to find file existence detection method for: $($app.LocalizedDisplayName)`n" +
            "Provide a path to the installed application's executable."
            throw $msg
        }

        $applicationExePath = "$appPathBase\$appPathExe"
    }

    # reg key path and reg key value are two separate elements
    if ($PSBoundParameters["RegKeyPath"] -and $PSBoundParameters["DisplayVersion"]) {
        $regKeyPath = $RegKeyPath
        $displayVersion = $DisplayVersion
    } else {
        $regKeyPath = "HKEY_LOCAL_MACHINE\" + $appXmlCustomData.EnhancedDetectionMethod.Settings.SimpleSetting.RegistryDiscoverySource.Key
        $displayVersion = $appXmlCustomData.EnhancedDetectionMethod.Rule.Expression.Operands.Expression.Operands.ConstantValue |
            Where-Object { $_.DataType -like "String" } |
            Select-Object -ExpandProperty Value
        if ([string]::IsNullOrEmpty($regKeyPath) -or [string]::IsNullOrEmpty($displayVersion)) {
            throw "Unable to find registry key detection method for: $($app.LocalizedDisplayName)"
        }
    }

    if ($PSBoundParameters["InstallCommandLine"]) {
        $installCommandLine = $InstallCommandLine
    } else {
        $installCommandLine = $appXmlCustomData.InstallCommandLine
    }

    if (-not $installCommandLine) {
        throw "Could not find install command line: $_"
    }

    if ($PSBoundParameters["UninstallCommandLine"]) {
        $uninstallCommandLine = $UninstallCommandLine
    } else {
        $uninstallCommandLine = $appXmlCustomData.UninstallCommandLine
    }

    if (-not $UninstallCommandLine) {
        throw "Could not find uninstall command line: $_"
    }

    # build splat
    $newIntuneAppArgs = @{
        SourcePath                  = $sourcePath
        InstalledApplicationSizeMB  = $InstalledApplicationSizeMB
        DisplayName                 = $displayName
        Publisher                   = $publisher
        Description                 = $description
        ApplicationExePath          = $applicationExePath
        RegKeyPath                  = $regKeyPath
        DisplayVersion              = $displayVersion
        IconPath                    = $IconPath
        AppVersion                  = $appVersion
        InstallCommandLine          = $installCommandLine
        UninstallCommandLine        = $uninstallCommandLine
    }

    if ($PSBoundParameters["Developer"]) {
        $newIntuneAppArgs.Add("Developer", $Developer)
    }

    if ($PSBoundParameters["Owner"]) {
        $newIntuneAppArgs.Add("Owner", $Owner)
    }

    if ($PSBoundParameters["Notes"]) {
        $newIntuneAppArgs.Add("Notes", $Notes)
    }

    if ($PSBoundParameters["InformationURL"]) {
        $newIntuneAppArgs.Add("InformationURL", $InformationURL)
    }

    if ($PSBoundParameters["PrivacyURL"]) {
        $newIntuneAppArgs.Add("PrivacyURL", $PrivacyURL)
    }

    if ($PSBoundParameters["CompanyPortalFeaturedApp"]) {
        $newIntuneAppArgs.Add("CompanyPortalFeaturedApp", $CompanyPortalFeaturedApp)
    }

    if ($PSBoundParameters["RestartBehavior"]) {
        $newIntuneAppArgs.Add("RestartBehavior", $RestartBehavior)
    }

    if ($PSBoundParameters["InstallExperience"]) {
        $newIntuneAppArgs.Add("InstallExperience", $InstallExperience)
    }

    # create app
    try {
        New-IntuneApp @newIntuneAppArgs
    } catch {
        throw "Error encountered when creating app in Intune: $_"
    }

    # assign to mem-device-app-testing_gs
    Deploy-IntuneAppToTesting -DisplayName $displayName

    # output the parameter splat to the console
    Write-Output "`$convertSCCMAppArgs = @{"
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        Write-Output "$($_.Key) = `"$($_.Value)`""
    }
    Write-Output "}"
    Write-Output "Convert-SCCMAppToIntune @convertSCCMAppArgs"
}

#endregion

#region Copy-InstallScripts.ps1
function Copy-InstallScripts {
    [Alias("cis")]
    param(
        # TestMachineName
        [Parameter(Mandatory)]
        [string]$TestMachineName,
        # Publisher
        [Parameter(Mandatory)]
        [string]$Publisher,
        # ApplicationName
        [Parameter(Mandatory)]
        [string]$ApplicationName
    )

    $scripts = Get-ChildItem -Path "C:\sources\repos\matmcp1-psadt-app-scripts\$ApplicationName" -Recurse -Include "*.ps1"
    $scriptDirectories = $scripts.FullName | Split-Path -Parent

    foreach ($dir in $scriptDirectories) {
        try {
            Write-Verbose "Copying: '$dir' to 'C:\sources\staging'"
            Copy-Item -Path $dir -Destination "C:\sources\staging" -Recurse -Force
            Write-Verbose "Copying: '$dir' to '\\$TestMachineName\c$\windows\imecache'"
            Copy-Item -Path $dir -Destination "\\$TestMachineName\c$\windows\imecache" -Recurse -Force
            Write-Verbose "Copying: '$dir' to '\\bmd\bmdapps\sccm_packages\software\$Publisher'"
            Copy-Item -Path $dir -Destination "\\bmd\bmdapps\sccm_packages\software\$Publisher" -Recurse -Force
        } catch {
            throw $_
        }
    }
}

#endregion

#region Deploy-IntuneAppAllDevices.ps1
function Deploy-IntuneAppAllDevices {
    [CmdletBinding()]
    param (
        # DisplayName
        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    # deploy app to all devices
    try {
        $appID = Get-IntuneWin32App | Where-Object { $_.displayName -like $DisplayName } | Select-Object -ExpandProperty "ID"

        if ($appID.Count -lt 1) {
            throw "Found no applications with DisplayName: $DisplayName"
        } elseif ($appID.Count -gt 1) {
            throw "Found more than one application when searching using display name: $DisplayName. Be more specific."
        }

        Add-IntuneWin32AppAssignmentAllDevices `
            -ID $appID `
            -Intent "available" `
            -Notification "showAll" `
            -DeliveryOptimizationPriority "foreground"

    } catch {
        throw "Error encountered when deploying app: $_"
    }
}

#endregion

#region Deploy-IntuneAppToGroup.ps1
function Deploy-IntuneAppToGroup {
    [CmdletBinding()]
    param (
        # DisplayName - displayname of app in intune
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,

        # GroupID - id of group in entra
        [Parameter(Mandatory=$true)]
        [string]$GroupID
    )

    try {
        $win32App = Get-IntuneWin32App | Where-Object { $_.DisplayName -like $DisplayName }
    } catch {
        throw "Encountered error when retrieving app from intune with displayname: '$DisplayName'"
    }

    if ($null -eq $win32App) {
        throw "Could not find app with DisplayName: '$DisplayName'"
    } elseif ($win32App.Count -gt 1) {
        throw "Found more than 1 app with DisplayName: '$DisplayName'. Be more specific."
    }

    try {
        $intuneWin32AppAssignmentArgs = @{
            Include         = $true
            ID              = $win32App.id
            GroupID         = $groupID
            Intent          = "available"
            Notification    = "showAll"
        }
        Add-IntuneWin32AppAssignmentGroup @intuneWin32AppAssignmentArgs
    } catch {
        throw "Encountered error when assigning '$DisplayName' to GroupID '$GroupID'"
    }
}

#endregion

#region Deploy-IntuneAppToTesting.ps1
function Deploy-IntuneAppToTesting {
    [CmdletBinding()]
    param (
        # DisplayName - displayname of app in intune
        [Parameter(Mandatory=$true)]
        [string]$DisplayName
    )

    try {
        $win32App = Get-IntuneWin32App | Where-Object DisplayName -like $DisplayName
    } catch {
        throw "Encountered error when retrieving app from intune with displayname: '$DisplayName'"
    }

    if ($null -eq $win32App) {
        throw "Could not find app with DisplayName: '$DisplayName'"
    } elseif ($win32App.Count -gt 1) {
        throw "Found more than 1 app with DisplayName: '$DisplayName'. Be more specific."
    }

    try {
        $intuneWin32AppAssignmentArgs = @{
            Include         = $true
            ID              = $win32App.id
            GroupID         = "9deb0e98-7051-4279-9e7a-31ec1daae2b9"
            Intent          = "available"
            Notification    = "showAll"
        }
        Add-IntuneWin32AppAssignmentGroup @intuneWin32AppAssignmentArgs
    } catch {
        throw "Encountered error when assigning '$DisplayName' to mem-device-app-testing_gs with ID '9deb0e98-7051-4279-9e7a-31ec1daae2b9'"
    }
}

#endregion

#region Get-DeviceEntraGroups.ps1
function Get-DeviceEntraGroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceId
    )

    process {
        # 1. Look up the device in Entra ID.
        # Checks both the hardware 'deviceId' and the directory 'id' to be safe.
        $device = Get-MgDevice -Filter "deviceId eq '$DeviceId'" -ErrorAction SilentlyContinue
        if (-not $device) {
            $device = Get-MgDevice -DeviceId $DeviceId -ErrorAction SilentlyContinue
        }

        if (-not $device) {
            Write-Error "Device '$DeviceId' could not be found in Entra ID."
            return
        }

        # 2. Grab flat memberships. 
        # We explicitly ask for 'displayName' and 'groupTypes' so Graph populates them.
        $memberships = Get-MgDeviceMemberOf -DeviceId $device.Id -All -Property "id,displayName,groupTypes"

        if (-not $memberships) {
            Write-Host "The device is not a direct member of any Entra groups."
            return
        }

        # 3. Filter for groups and parse their membership styles
        $results = foreach ($member in $memberships) {
            $odataType = $member.AdditionalProperties['@odata.type']

            # Exclude other directory object types like Administrative Units
            if ($odataType -eq '#microsoft.graph.group') {
                $groupTypes = $member.AdditionalProperties['groupTypes']
                $isDynamic = $false

                if ($null -ne $groupTypes) {
                    # Safely evaluate array vs string element types from the Graph response
                    if ($groupTypes -is [System.Collections.IEnumerable] -and $groupTypes -isnot [string]) {
                        if ($groupTypes -contains 'DynamicMembership') {
                            $isDynamic = $true
                        }
                    } else {
                        if ($groupTypes.ToString() -like "*DynamicMembership*") {
                            $isDynamic = $true
                        }
                    }
                }

                $membershipType = if ($isDynamic) {
                    "Dynamic"
                } else {
                    "Static (Assigned)"
                }

                [PSCustomObject]@{
                    GroupName   = $member.AdditionalProperties['displayName']
                    GroupId     = $member.Id
                    GroupType   = $membershipType
                }
            }
        }

        return $results
    }
}

#endregion

#region Get-EntraGroups.ps1
function Get-EntraGroups {
    [CmdletBinding()]
    param (
        # ExportCsvPath
        [Parameter(Mandatory)]
        [string]
        $ExportCsvPath
    )
    
    # 2. Get all groups
    try {
        $allGroups = Get-MgGroup -All
    } catch {
        throw $_
    }
    
    # 3. Define the custom property to determine the detailed type
    $allGroups | Select-Object Id, DisplayName, Mail, MailNickname, Description, OnPremisesSyncEnabled, 
    @{
        N = 'GroupType';
        E = {
            # Start with a modifier, checking for DynamicMembership first
            $Modifier = if ($_.GroupTypes -contains 'DynamicMembership') { "Dynamic " } else { "" }
            
            # Determine the base group type
            $BaseType = ""
            
            # 1. Check for Microsoft 365 Group (which is always mail-enabled and security-enabled)
            if ($_.GroupTypes -contains 'Unified') {
                $BaseType = "Microsoft 365 (Unified)"
            }
            # 2. Check for Security Group (must be SecurityEnabled = True)
            elseif ($_.SecurityEnabled -eq $true) {
                # Is it mail-enabled too?
                if ($_.MailEnabled -eq $true) {
                    $BaseType = "Mail-Enabled Security"
                }
                # Just a standard Security Group
                else {
                    $BaseType = "Security"
                }
            }
            # 3. Fallback to Distribution List (MailEnabled = True, SecurityEnabled = False)
            elseif ($_.MailEnabled -eq $true) {
                $BaseType = "Distribution"
            }
            # 4. Final Fallback (Should be rare)
            else {
                $BaseType = "Other"
            }
    
            # Combine the modifier and the base type
            $Modifier + $BaseType
        }
    },
    @{N = 'IsSynced'; E = { $_.OnPremisesSyncEnabled -eq $true } } | 
    Export-Csv -Path $ExportCsvPath -NoTypeInformation -Force
    
    Write-Host "Export complete. Find the categorized list at $ExportCsvPath" -ForegroundColor Green
}

#endregion

#region Get-IntuneApp.ps1
function Get-IntuneApp {
    param(
        # DisplayName
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        # ID - one or more app guid's to lookup
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('AppId')]
        [string[]]$ID,

        # AllProperties - will add every app property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    begin {
        $baseUri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps"
        $select = if ($AllProperties) { '' } else { '?$select=id,displayName' }
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()

        function Add-AppObjectToList {
            param([object]$App)

            if ($AllProperties) {
                $results.Add([PSCustomObject]$App)
            } else {
                $results.Add([PSCustomObject]@{
                    ID          = $app.id
                    DisplayName = $app.displayName
                })
            }
        }
    }

    process {
        if ($ID) {
            foreach ($appId in $ID) {
                $uri = "$baseUri/$appId$select"
                try {
                    $app = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                } catch {
                    Write-Warning "Couldn't get DisplayName for $appId. $_"
                }
                Add-AppObjectToList -App $app
            }
        } else {
            $uri = "$baseUri$select"
            while ($uri) {
                try {
                    $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                } catch {
                    Write-Warning "Couldn't get DisplayName for $appId. $_"
                }
                foreach ($app in $response.value) {
                    if ($DisplayName -and $app.displayName -notlike $DisplayName) {
                        continue
                    }
                    Add-AppObjectToList -App $app
                }
                $uri = $response.'@odata.nextLink'
            }
        }
    }

    end {
        $results
    }
}

#endregion

#region Get-IntuneAppFailures.ps1
function Get-IntuneAppFailures {
    param (
        # ComputerName
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        # LastXDays - returns failures in the last x days, defaults to one day
        [Parameter(Mandatory=$false)]
        [int]$LastXDays = 1
    )

    $errors = Invoke-Command -ComputerName $ComputerName -ArgumentList $LastXDays -ScriptBlock {
        $regPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\Reporting\00000000-0000-0000-0000-000000000000"

        $appRegItems = Get-ChildItem $regPath | Get-ItemProperty

        foreach ($appRegItem in $appRegItems) {
            $statusServiceReportTime = [datetime]::ParseExact(
                $appRegItem.StatusServiceReportTime,
                'MM/dd/yyyy HH:mm:ss',
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
                [System.Globalization.DateTimeStyles]::AdjustToUniversal
            )

            $lastUpdatedTime = [datetime]::ParseExact(
                $appRegItem.LastUpdatedTime,
                'MM/dd/yyyy HH:mm:ss',
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
                [System.Globalization.DateTimeStyles]::AdjustToUniversal
            )

            $lastUpdatedTimeIsStale = $lastUpdatedTime -lt (Get-Date).ToUniversalTime().AddDays(-[Math]::Abs($using:LastXDays))
            if ($lastUpdatedTimeIsStale) { continue }

            $appId                                  = $appRegItem.PSChildName
            $reportingState                         = $appRegItem.ReportingState | ConvertFrom-Json
            $enforcementErrorCode                   = $reportingState.EnforcementErrorCode
            $hasEnforcementError                    = (-not [string]::IsNullOrWhiteSpace($enforcementErrorCode)) -and ($enforcementErrorCode -ne 0) -and ($enforcementErrorCode -ne "0x80070642")
            $detectionErrorOccurred                 = $reportingState.DetectionErrorOccurred
            $hasDetectionError                      = $detectionErrorOccurred -eq 'True'
            $applicabilityErrorOccurred             = $reportingState.ApplicabilityErrorOccurred
            $hasApplicabilityError                  = $applicabilityErrorOccurred -eq 'True'
            $noErrors                               = (-not $hasEnforcementError) -and (-not $hasDetectionError) -and (-not $hasApplicabilityError)

            if ($noErrors) { continue }

            [PSCustomObject]@{
                'AppId'                        = $appId
                'StatusServiceReportTime'      = $statusServiceReportTime.ToLocalTime()
                'AppStatusLastChanged'         = $lastUpdatedTime.ToLocalTime()
                'HasEnforcementError'          = $hasEnforcementError
                'EnforcementErrorCode'         = '0x{0:X8}' -f ($enforcementErrorCode -band 0x00000000FFFFFFFF)
                'HasDetectionError'            = $hasDetectionError
                'DetectionErrorCode'           = $reportingState.DetectionErrorCode
                'HasApplicabilityError'        = $hasApplicabilityError
                'ApplicabilityErrorCode'       = $reportingState.ApplicabilityErrorCode
            }
        }
    }

    $errors | Select-Object @{
        Name = 'DisplayName'
        Expr = { (Get-IntuneApp -ID $_.AppId).DisplayName }
    }, * -ExcludeProperty 'PSComputerName','RunspaceId'
}

#endregion

#region Get-IntuneAppFailuresPostToURL.ps1
function Get-IntuneAppFailuresPostToURL {
    function Write-CMLog {
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]
            $Message,
            # Path
            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path = "$env:PROGRAMDATA\IntuneAppFailureMonitor\IntuneAppFailureMonitor.log",
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]
            $Level = "Info",
            # Component
            [Parameter(Mandatory = $false)]
            [string]
            $Component = "PowerShellScript",
            # Context
            [Parameter(Mandatory = $false)]
            [string]
            $Context = "PowerShellScript",
            # Quiet - suppresses output
            [Parameter(Mandatory = $false)]
            [switch]
            $Quiet = $false
        )

        process {
            $logDir = Split-Path $Path -Parent

            if (-not (Test-Path -Path $logDir -PathType Container)) {
                try {
                    New-Item -ItemType Directory -Path $logDir -ErrorAction Stop -Force
                } catch {
                    throw "Could not create log directory: $logDir $_"
                }
            }

            $now = Get-Date
            $tzOffset = [TimeZoneInfo]::Local.GetUtcOffset($now).TotalMinutes
            $timeStr = $now.ToString("HH:mm:ss.fff") + ("{0:+000;-000;+000}" -f $tzOffset)
            $dateStr = $now.ToString("MM-dd-yyyy")

            foreach ($line in $Message) {
                if (-not $Quiet) {
                    # output the message
                    Write-Output $line
                }

                # convert level to type codes so cmtrace can read it
                switch ($Level) {
                    "Info" { [int]$type = 1 }
                    "Warning" { [int]$type = 2 }
                    "Error" { [int]$type = 3 }
                }

                $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                $scriptName = $MyInvocation.MyCommand.Name

                # create log entry
                $logLine = "<![LOG[$line]LOG]!>" +
                "<" +
                "time=`"$timeStr`" " +
                "date=`"$dateStr`" " +
                "component=`"$Component`" " +
                "context=`"$Context`" " +
                "type=`"$type`" " +
                "thread=`"$threadId`" " +
                "file=`"$scriptName`"" +
                ">"

                # append line to log file
                $logLine | Out-File -FilePath $Path -Append -Encoding utf8
            }
        }
    }

    $regPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\Reporting\00000000-0000-0000-0000-000000000000"

    $appRegItems = Get-ChildItem $regPath | Get-ItemProperty

    $appFailures = foreach ($appRegItem in $appRegItems) {
        $statusServiceReportTime = [datetime]::ParseExact(
            $appRegItem.StatusServiceReportTime,
            'MM/dd/yyyy HH:mm:ss',
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
            [System.Globalization.DateTimeStyles]::AdjustToUniversal
        )

        $statusServiceReportIsStale = $statusServiceReportTime -lt (Get-Date).ToUniversalTime().AddMinutes(-[Math]::Abs(60))
        if ($statusServiceReportIsStale) { continue }

        $lastUpdatedTime = [datetime]::ParseExact(
            $appRegItem.LastUpdatedTime,
            'MM/dd/yyyy HH:mm:ss',
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
            [System.Globalization.DateTimeStyles]::AdjustToUniversal
        )

        $appId                                  = $appRegItem.PSChildName
        $reportingState                         = $appRegItem.ReportingState | ConvertFrom-Json
        $enforcementErrorCode                   = $reportingState.EnforcementErrorCode
        $hasEnforcementError                    = (-not [string]::IsNullOrWhiteSpace($enforcementErrorCode)) -and ($enforcementErrorCode -ne 0)
        $detectionErrorOccurred                 = $reportingState.DetectionErrorOccurred
        $hasDetectionError                      = $detectionErrorOccurred -eq 'True'
        $applicabilityErrorOccurred             = $reportingState.ApplicabilityErrorOccurred
        $hasApplicabilityError                  = $applicabilityErrorOccurred -eq 'True'
        $noErrors                               = (-not $hasEnforcementError) -and (-not $hasDetectionError) -and (-not $hasApplicabilityError)

        if ($noErrors) { continue }

        Write-CMLog "StatusServiceReport for $appId is less than one hour old and has at least one error."
        Write-CMLog "AppId: $appId"
        Write-CMLog "StatusServiceReportTime: $statusServiceReportTime"
        Write-CMLog "EnforcementErrorCode: $enforcementErrorCode"

        [PSCustomObject]@{
            'AppId'                        = $appId
            'StatusServiceReportTime'      = $statusServiceReportTime.ToLocalTime()
            'AppStatusLastChanged'         = $lastUpdatedTime.ToLocalTime()
            'HasEnforcementError'          = $hasEnforcementError
            'EnforcementErrorCode'         = '0x{0:X8}' -f ($enforcementErrorCode -band 0x00000000FFFFFFFF)
            'HasDetectionError'            = $hasDetectionError
            'DetectionErrorCode'           = $reportingState.DetectionErrorCode
            'HasApplicabilityError'        = $hasApplicabilityError
            'ApplicabilityErrorCode'       = $reportingState.ApplicabilityErrorCode
        }
    }

    if ($appFailures.Count -gt 0) {
        $computerName = $env:COMPUTERNAME
        $scanTime = (Get-Date).ToString('o')
        $appIndex = 1
        $appReportHtml = foreach ($appFailure in $appFailures) {
@"
<table style="border-collapse:collapse; margin-bottom:20px; width:700px;">
    <th colspan="2" style="text-align:center; background:#f2f2f2; padding:10px; border:1px solid #ccc;">
        Application Installation Failure #$($appIndex)
    </th>
<tr>
    <td style="font-weight:bold; padding:8px; border:1px solid #ccc; width:200px;">
        App ID
    </td>
    <td style="padding:8px; border:1px solid #ccc;">
        $($appFailure.AppId)
    </td>
</tr>
<tr>
    <td style="font-weight:bold; padding:8px; border:1px solid #ccc;">
        Intune Status Service Report Time
    </td>
    <td style="padding:8px; border:1px solid #ccc;">
        $($appFailure.StatusServiceReportTime)
    </td>
</tr>
<tr>
    <td style="font-weight:bold; padding:8px; border:1px solid #ccc;">
        Intune Installation Status Last Changed
    </td>
    <td style="padding:8px; border:1px solid #ccc;">
        $($appFailure.AppStatusLastChanged)
    </td>
</tr>
<tr>
    <td style="font-weight:bold; padding:8px; border:1px solid #ccc;">
        Enforcement Error Code
    </td>
    <td style="padding:8px; border:1px solid #ccc;">
        $($appFailure.EnforcementErrorCode)
    </td>
</tr>
</table>
"@
            $appIndex++
        }

        $appIdsString = (
            $appFailures | ForEach-Object {
                "'$($_.AppId)'"
            }
        ) -join ",`r`n"

        $htmlBody = 
@"
<html>
<body style="font-family:Segoe UI,Arial,sans-serif;">
<h2>Installation Failure Detected!</h2>
<p><strong>Computer:</strong> $env:COMPUTERNAME</p>
<p><strong>Scan Time:</strong> $scanTime</p>
<h3>Failure Details</h3>
$($appReportHtml -join "`n")
<h3>Copy IDs</h3>
<pre style="background:#f4f4f4;border:1px solid #ccc;padding:12px;font-family:Consolas,monospace;white-space:pre-wrap;">
<code>
$appIdsString
</code>
</pre>
</body>
</html>
"@

        $payload = [PSCustomObject]@{
            Subject         = "[ALERT] Intune App Install Failed!"
            Body            = $htmlBody
        }

        $json = $payload | ConvertTo-Json -Depth 10

        $thumb = "36D08BA1F03685F06B9B3E7B047C337CD4590877"
        $cert = Get-Item "Cert:\LocalMachine\My\$thumb"
        $cmsPath = "$env:PROGRAMDATA\IntuneAppFailureMonitor\LogicAppUrl.cms"
        $url = Unprotect-CmsMessage -LiteralPath $cmsPath -To $cert -ErrorAction Stop

        try {
            Invoke-RestMethod -Uri $url -Method POST -ContentType 'application/json' -Body $json -ErrorAction Stop
        } catch {
            Write-CMLog "Failed to send payload to endpoint: $($_.Exception.Message)"
        }
    }
}

#endregion

#region Get-IntuneDevice.ps1
function Get-IntuneDevice {
    param(
        # DeviceName - filter results by device name; supports wildcards (* and ?)
        [Parameter(Mandatory=$false)]
        [string]$DeviceName,
        # AllProperties - will add every device property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,deviceName,model'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($device in $response.value) {
            if ($DeviceName -and $device.deviceName -notlike $DeviceName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$device)
            } else {
                $results.Add([PSCustomObject]@{
                    ID              = $device.id
                    DeviceName      = $device.deviceName
                    Model           = $device.model
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}

#endregion

#region Get-IntuneGroup.ps1
function Get-IntuneGroup {
    param (
        # Name - name of the group to search for in entra
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        # AllProperties - will return all group properties on the object
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/groups"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,displayName'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($group in $response.value) {
            if ($DisplayName -and $group.displayName -notlike $DisplayName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$group)
            } else {
                $results.Add([PSCustomObject]@{
                    ID          = $group.id
                    DisplayName   = $group.displayName
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}

#endregion

#region Get-IntuneGroupMembers.ps1
function Get-IntuneGroupMembers {
    param (
        # Name - name of the group to retrieve members of
        [Parameter(Mandatory=$true)]
        [string]$GroupID,

        # AllProperties - will return all properties on the object
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/groups/$GroupID/members"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,displayName,userPrincipalName'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($member in $response.value) {
            if ($DisplayName -and $group.displayName -notlike $DisplayName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$group)
            } else {
                $results.Add([PSCustomObject]@{
                    ID              = $group.id
                    DisplayName     = $group.displayName
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}

#endregion

#region Get-IntuneUser.ps1
function Get-IntuneUser {
    param(
        # UserPrincipalName
        [Parameter(Mandatory=$false)]
        [string]$UserPrincipalName,

        # AllProperties - will add every user property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/users"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,displayName,userPrincipalName,jobTitle'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($user in $response.value) {
            if ($UserPrincipalName -and $user.userPrincipalName -notlike $UserPrincipalName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$user)
            } else {
                $results.Add([PSCustomObject]@{
                    ID                  = $user.id
                    UserPrincipalName   = $user.userPrincipalName
                    DisplayName         = $user.displayName
                    JobTitle            = $user.jobTitle
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}

#endregion

#region Get-RemediationScript.ps1
function Get-RemediationScript {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
    $scriptResults = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($script in $response.value) {
            $scriptResults.Add([PSCustomObject]@{
                ID          = $script.id
                DisplayName = $script.displayName
                Description = $script.description
            })
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $scriptResults
}

#endregion

#region Get-RemediationScriptAssignment.ps1
# Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All", "Group.Read.All"

function Get-RemediationScriptAssignment {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
    $scriptResults = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($script in $response.value) {
            $scriptResults.Add([PSCustomObject]@{
                ID          = $script.id
                DisplayName = $script.displayName
                Description = $script.description
            })
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $targetScript = $scriptResults | Out-GridView -Title "Select Remediation Script" -OutputMode Single

    if ($targetScript) {
        # 2. Get assignments for the selected remediation script
        $assignmentsUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$($targetScript.id)/assignments"
        $assignments = (Invoke-MgGraphRequest -Method GET -Uri $assignmentsUri).value

        # 3. Output assignment details
        $assignments | ForEach-Object {
            $target = $_.target
            $targetType = $target.'@odata.type'
            $groupId = $target.groupId
            $groupName = "N/A"

            # Resolve Entra ID Group Name if assigned to a specific group
            if ($groupId) {
                try {
                    $group = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$groupId"
                    $groupName = $group.displayName
                } catch {
                    $groupName = "Unknown/Deleted Group"
                }
            }

            [PSCustomObject]@{
                ScriptName     = $targetScript.displayName
                AssignmentId   = $_.id
                TargetType     = $targetType.Split('.')[-1]
                GroupName      = $groupName
                GroupId        = $groupId
                FilterId       = $target.deviceAndAppManagementAssignmentFilterId
                FilterType     = $target.deviceAndAppManagementAssignmentFilterType
                ScheduleType   = $_.runSchedule.'@odata.type'.Split('.')[-1]
                ScheduleDetail = $_.runSchedule.interval
            }
        } | Format-Table -AutoSize
    }
}

#endregion

#region Get-RequiredAssignmentsForGroup.ps1
# Connect-MgGraph -Scopes "DeviceManagementApps.Read.All" -NoWelcome
function Get-RequiredAssignmentsForGroup {
    param (
        # GroupId
        [Parameter(Mandatory=$true)]
        [string]
        $GroupId
    )

    Write-Host "Scanning Win32 apps for 'Required' assignments to group ID: $GroupId..." -ForegroundColor Cyan

    # 2. Query endpoint directly and handle pagination
    $uri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')&`$expand=assignments"
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($app in $response.value) {
            foreach ($assignment in $app.assignments) {
                $assignedGroupId = $assignment.target.groupId

                if ($assignment.intent -eq 'required' -and $assignedGroupId -eq $GroupId) {
                    $results.Add([PSCustomObject]@{
                        AppDisplayName  = $app.displayName
                        AppId           = $app.id
                        Intent          = $assignment.intent
                        GroupId         = $assignedGroupId
                        FilterMode      = $assignment.target.filterType
                        FilterId        = $assignment.target.filterId
                    })
                }
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    # 3. Output results
    if ($results.Count -gt 0) {
        Write-Host "`nFound $($results.Count) matching Win32 application(s):" -ForegroundColor Green
        $results | Format-Table -AutoSize
    } else {
        Write-Host "`nNo Win32 applications are deployed as 'Required' to group ID: $GroupId." -ForegroundColor Yellow
    }
}

#endregion

#region Get-VulnerabilitiesBySoftwareName.ps1
<#
.SYNOPSIS
Input the name of an application e.g. Illustrator and this function
will output a list of machines with vulnerable software versions
along with install locations, uninstallstrings and lastloggedon
user
#>
function Get-VulnerabilitiesBySoftwareName {
    param(
        # SoftwareName
        [Parameter(Mandatory)]
        [string]
        $SoftwareName,
        # CsvPath
        [Parameter(Mandatory)]
        [string]
        $CsvPath
    )

    function Invoke-CustomQuery {
        param(
            # extra
            [Parameter(Mandatory)]
            [string]
            $ResourceUrl
        )

        $baseUrl = 'https://api-us.securitycenter.microsoft.com'
        $uri = $baseUrl + $ResourceUrl

        $headers = @{
            Authorization = ""
        }

        $res = Invoke-RestMethod `
        -Method GET `
        -Uri $uri `
        -ContentType "application/json" `
        -Headers $headers

        return $res
    }

    $res = Invoke-CustomQuery -ResourceUrl "/api/machines/SoftwareVulnerabilitiesByMachine"

    $softwareVulnInfo = $res.value |
    Where-Object { $_.id -like "*$SoftwareName*" } |
    Select-Object -Unique -CaseInsensitive -Property deviceName,deviceId,
    osPlatform,osVersion,softwareVendor,softwareName,softwareVersion,
    @{n="Disk Paths";e={$_.diskPaths -join ', '}},
    @{n="Registry Paths";e={$_.registryPaths -join ', '}} |
    Sort-Object deviceName

    foreach($item in $softwareVulnInfo) {
        $deviceId = $item.deviceId
        $res = Invoke-CustomQuery -ResourceUrl "/api/machines/$deviceId/logonusers"
        $logonUsers = $res.value | Where-Object { $_.logonTypes -like 'Interactive' }
        $item | Add-Member -MemberType NoteProperty -Name 'Logon Users' -Value ($logonUsers.accountName -join ', ')
        $item | Add-Member -MemberType NoteProperty -Name 'Last Seen' -Value ($logonUsers.lastSeen -join ', ')
    }

    $softwareVulnInfo | Export-Csv -Path $CsvPath -Force -NoTypeInformation
    $softwareVulnInfo | Export-Excel -Path "$CsvPath.xlsx"
}

#endregion

#region Hide-IntelExtensibleFrameworkUpdate.ps1
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

#endregion

#region Hide-IntelExtensibleFrameworkUpdateDetection.ps1
<#
.SYNOPSIS
Detects whether the 'Intel - Extension - 2.1.10103.24' Windows Update is being
offered to the machine and has not yet been hidden. This update comes through the
local WU scan and not the drivers deployed through Intune.
.NOTES
Author:     Matt McPhee
Created:    15/09/2026
Updated:    15/09/2026
Exit 1 = update is visible and needs hiding, Exit 0 = no action required.
#>
function Hide-IntelExtensibleFrameworkUpdateDetection {
    $titlePattern = "*Intel*Extension*2.1.10103.24*"
    $logPath = "C:\Windows\Logs\Hide-IntelExtensibleFrameworkUpdate.log"

    function Write-CMLog {
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]
            $Message,
            # Path
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path,
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]
            $Level = "Info",
            # Component
            [Parameter(Mandatory = $false)]
            [string]
            $Component = "PowerShellScript",
            # Context
            [Parameter(Mandatory = $false)]
            [string]
            $Context = "PowerShellScript",
            # Quiet - suppresses output
            [Parameter(Mandatory = $false)]
            [switch]
            $Quiet = $false
        )

        process {
            $logDir = Split-Path $Path -Parent

            if (-not (Test-Path -Path $logDir -PathType Container)) {
                try {
                    New-Item -ItemType Directory -Path $logDir -ErrorAction Stop -Force | Out-Null
                } catch {
                    throw "Could not create log directory: $logDir $_"
                }
            }

            $now = Get-Date
            $tzOffset = [TimeZoneInfo]::Local.GetUtcOffset($now).TotalMinutes
            $timeStr = $now.ToString("HH:mm:ss.fff") + ("{0:+000;-000;+000}" -f $tzOffset)
            $dateStr = $now.ToString("MM-dd-yyyy")

            foreach ($line in $Message) {
                if (-not $Quiet) {
                    # output the message
                    Write-Output $line
                }

                # convert level to type codes so cmtrace can read it
                switch ($Level) {
                    "Info" { [int]$type = 1 }
                    "Warning" { [int]$type = 2 }
                    "Error" { [int]$type = 3 }
                }

                $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId

                # create log entry
                $logLine = "<![LOG[$line]LOG]!>" +
                "<" +
                "time=`"$timeStr`" " +
                "date=`"$dateStr`" " +
                "component=`"$Component`" " +
                "context=`"$Context`" " +
                "type=`"$type`" " +
                "thread=`"$threadId`" " +
                "file=`"Hide-IntelExtensibleFrameworkUpdateDetection.ps1`"" +
                ">"

                # append line to log file
                $logLine | Out-File -FilePath $Path -Append -Encoding utf8
            }
        }
    }

    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()

        # only non-hidden updates are candidates for remediation
        $updates = @($updateSearcher.Search("IsHidden=0").Updates)
    } catch {
        Write-CMLog -Message "Failed to query the Windows Update Agent: $($_.Exception.Message)" -Level 'Error' -Path $logPath -Quiet
        Write-Output "Windows Update Agent query failed"
        exit 0
    }

    $matched = @($updates | Where-Object { $_.Title -like $titlePattern })

    if ($matched.Count -gt 0) {
        # issue detected
        foreach ($update in $matched) {
            Write-CMLog -Message "Detected visible update: $($update.Title)" -Level 'Warning' -Path $logPath -Quiet
        }
        Write-Output "Intel Extensible Framework update 2.1.10103.24 is visible and requires hiding"
        exit 1
    } else {
        Write-CMLog -Message "No visible update matching '$titlePattern'. Taking no action." -Level 'Info' -Path $logPath -Quiet
        Write-Output "Intel Extensible Framework update 2.1.10103.24 not offered or already hidden"
        exit 0
    }
}

#endregion

#region Hide-IntelExtensibleFrameworkUpdateRemediation.ps1
<#
.SYNOPSIS
Hides the 'Intel - Extension - 2.1.10103.24' Windows Update so it is no longer
offered to the machine.
.NOTES
Author:     Matt McPhee
Created:    15/09/2026
Updated:    15/09/2026
Exit 0 = update hidden successfully, Exit 1 = remediation failed.
#>
function Hide-IntelExtensibleFrameworkUpdateRemediation {
    $titlePattern = "*Intel*Extension*2.1.10103.24*"
    $logPath = "C:\Windows\Logs\Hide-IntelExtensibleFrameworkUpdate.log"

    function Write-CMLog {
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]$Message,
            # Path
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$Path,
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]$Level = "Info",
            # Component
            [Parameter(Mandatory = $false)]
            [string]$Component = "PowerShellScript",
            # Context
            [Parameter(Mandatory = $false)]
            [string]$Context = "PowerShellScript",
            # Quiet - suppresses output
            [Parameter(Mandatory = $false)]
            [switch]$Quiet = $false
        )

        process {
            $logDir = Split-Path $Path -Parent

            if (-not (Test-Path -Path $logDir -PathType Container)) {
                try {
                    New-Item -ItemType Directory -Path $logDir -ErrorAction Stop -Force | Out-Null
                } catch {
                    throw "Could not create log directory: $logDir $_"
                }
            }

            $now = Get-Date
            $tzOffset = [TimeZoneInfo]::Local.GetUtcOffset($now).TotalMinutes
            $timeStr = $now.ToString("HH:mm:ss.fff") + ("{0:+000;-000;+000}" -f $tzOffset)
            $dateStr = $now.ToString("MM-dd-yyyy")

            foreach ($line in $Message) {
                if (-not $Quiet) {
                    # output the message
                    Write-Output $line
                }

                # convert level to type codes so cmtrace can read it
                switch ($Level) {
                    "Info" { [int]$type = 1 }
                    "Warning" { [int]$type = 2 }
                    "Error" { [int]$type = 3 }
                }

                $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId

                # create log entry
                $logLine = "<![LOG[$line]LOG]!>" +
                "<" +
                "time=`"$timeStr`" " +
                "date=`"$dateStr`" " +
                "component=`"$Component`" " +
                "context=`"$Context`" " +
                "type=`"$type`" " +
                "thread=`"$threadId`" " +
                "file=`"Hide-IntelExtensibleFrameworkUpdateRemediation.ps1`"" +
                ">"

                # append line to log file
                $logLine | Out-File -FilePath $Path -Append -Encoding utf8
            }
        }
    }

    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $updates = @($updateSearcher.Search("IsHidden=0").Updates)
    } catch {
        Write-CMLog -Message "Failed to query the Windows Update Agent: $($_.Exception.Message)" -Level 'Error' -Path $logPath -Quiet
        Write-Output "Windows Update Agent query failed"
        exit 1
    }

    $matched = @($updates | Where-Object { $_.Title -like $titlePattern })

    if ($matched.Count -eq 0) {
        Write-CMLog -Message "No visible update matching '$titlePattern'. Nothing to remediate." -Level 'Info' -Path $logPath -Quiet
        Write-Output "Intel Extensible Framework update 2.1.10103.24 not offered or already hidden"
        exit 0
    }

    $failures = [System.Collections.Generic.List[string]]::new()

    foreach ($update in $matched) {
        try {
            $update.IsHidden = $true
        } catch {
            Write-CMLog -Message "Failed to hide $($update.Title): $($_.Exception.Message)" -Level 'Error' -Path $logPath -Quiet
            $failures.Add($update.Title)
            continue
        }

        Start-Sleep -Seconds 60

        # re-read the property to confirm the change persisted to the WU datastore
        if ($update.IsHidden) {
            Write-CMLog -Message "Successfully hid $($update.Title)" -Level 'Info' -Path $logPath -Quiet
        } else {
            Write-CMLog -Message "Hide operation reported no error but $($update.Title) is still visible" -Level 'Error' -Path $logPath -Quiet
            $failures.Add($update.Title)
        }
    }

    if ($failures.Count -gt 0) {
        Write-Output "Failed to hide $($failures.Count) update(s): $($failures -join ', ')"
        exit 1
    }

    Write-Output "Hid $($matched.Count) update(s) matching Intel Extensible Framework 2.1.10103.24"
    exit 0
}

#endregion

#region New-IntuneAppControlPolicy.ps1
function New-IntuneAppControlPolicy {
    [CmdletBinding()]
    param (
        # Required parameter for policy name
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        # Path to the custom policy XML file
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        [string]$PolicyXmlPath,

        # Optional description with empty default
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    # Check if required module is installed
    if (-not (Get-Module -Name Microsoft.Graph.Beta.DeviceManagement -ListAvailable)) {
        Write-Error "Microsoft.Graph.Beta.DeviceManagement module is required."
        Write-Error "Please install it using 'Install-Module -Name Microsoft.Graph.Beta.DeviceManagement'."
        return
    }

    # Import the module
    Import-Module Microsoft.Graph.Beta.DeviceManagement

    try {
        # Read the XML file and convert to base64
        $policyXml = Get-Content -Path $PolicyXmlPath -Raw
        $policyBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($policyXml))

        # find the policy template
        $policyTemplates = Get-MgBetaDeviceManagementConfigurationPolicyTemplate
        $policyTemplate = $policyTemplates | Where-Object { $_.Name -eq "Application Control Template" }
        $policyTemplateId = $policyTemplate.Id

        # construct the uri for fetching template IDs
        $uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$policyTemplateId')?`$expand=settings"

        # fetch the policy details with expanded settings
        Invoke-MgGraphRequest -Method GET -Uri $uri |
        Select-Object -Property name, description, settings, platforms, technologies, templateReference

        # Create hashtable for policy parameters
        $params = @{
            '@odata.type' = "#microsoft.graph.windowsDefenderApplicationControl"
            DisplayName = $DisplayName
            Description = $Description
            PolicyContent = $policyBase64
        }

        # Create the policy using Graph API
        $response = New-MgBetaDeviceManagementConfigurationPolicy -BodyParameter $params
        Write-Output $response  # Return the created policy object
    } catch {
        Write-Error "Failed to create app control policy: $_"  # Error handling
    }
}

#endregion

#region New-IntuneGroup.ps1
function New-IntuneGroup {
    param (
        # DisplayName
        [Parameter(Mandatory)]
        [string]
        $DisplayName,
        # MailNickname
        [Parameter(Mandatory)]
        [string]
        $MailNickname,
        # Description
        [Parameter(Mandatory=$false)]
        [string]
        $Description,
        # MailEnabled
        [Parameter()]
        [switch]
        $MailEnabled,
        # SecurityEnabled
        [Parameter()]
        [switch]
        $SecurityEnabled,
        # Visibility
        [ValidateSetAttribute("Private","Public","HiddenMembership")]
        [Parameter(Mandatory)]
        [string]
        $Visibility
    )

    # test vars
    $DisplayName = "test group"
    $MailNickname = "testgroup"
    $MailEnabled = $false
    $SecurityEnabled = $true
    $Description = "This is a test group."
    $Visibility = "Private"

    $groupParams = @{
        displayName = $DisplayName
        mailNickname = $MailNickname
        visibility = $Visibility
    }

    New-MgGroup -BodyParameter $groupParams
}

#endregion

#region New-IntuneWinPackage.ps1
function New-IntuneWinPackage {
    [CmdletBinding()]
    param (
        # SourceFolder
        [Parameter(Mandatory)]
        [string]
        $SourceFolder
    )

    $headers = @{ "User-Agent" = "PowerShell" }
    $url = "https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/heads/master.zip"
    $targetDir = "C:\sources\tools"
    $exePath = Join-Path -Path $targetDir -ChildPath "intunewinapputil.exe"
    $tempZipPath = Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil_Master.zip"
    $tempExtractPath = Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil_Master"
    $ProgressPreference = 'SilentlyContinue'
    
    try {
        # create folder if it doesn't exist
        if (-not (Test-Path -Path $targetDir)) {
            Write-Host "Creating target directory: $targetDir" -ForegroundColor Green
            New-Item -Path $targetDir -ItemType Directory | Out-Null
        }

        # download the ZIP file
        Write-Host "Downloading latest version from GitHub..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $url -OutFile $tempZipPath -Headers $headers -ErrorAction Stop
            Write-Host "Download successful." -ForegroundColor Green
        } catch {
            throw "Failed to download the file from $url. Error: $($_.Exception.Message)"
        }

        # extract the ZIP file
        Write-Host "Extracting files to temporary directory..." -ForegroundColor Cyan
        try {
            Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force
            Write-Host "Extraction successful." -ForegroundColor Green
        } catch {
            throw "Failed to extract the ZIP file. Error: $($_.Exception.Message)"
        }

        # copy the executable to the target path
        Write-Host "Copying intunewinapputil.exe to $targetDir..." -ForegroundColor Cyan

        # the executable is typically located inside a folder named 'Microsoft-Win32-Content-Prep-Tool-master'
        $sourceExePath = Get-ChildItem -Path "$tempExtractPath\*" -Filter "IntuneWinAppUtil.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1

        if (-not $sourceExePath) {
            throw "Could not find IntuneWinAppUtil.exe in the extracted content."
        }

        try {
            Copy-Item -Path $sourceExePath -Destination $exePath -Force -ErrorAction Stop
            Write-Host "Successfully placed IntuneWinAppUtil.exe at $exePath" -ForegroundColor Green
        } catch {
            throw "Failed to copy the executable. Error: $($_.Exception.Message)"
        }

        # clean up temporary files
        Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
        Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleanup complete." -ForegroundColor Green

        # create dummy exe file
        $SourceFolderName = $SourceFolder | Split-Path -Leaf
        $dummyExePath = "$SourceFolder\$SourceFolderName"
        New-Item -Path $dummyExePath -ItemType File -Force | Out-Null

        # run intunewinapputil.exe
        $intunewinFileName = ($SourceFolder | Split-Path -Leaf) + ".intunewin"
        Write-Host "Packaging $SourceFolder into $targetDir\$intunewinFileName" -ForegroundColor Cyan
        $exeArgs = "-c `"$SourceFolder`" -s `"$dummyExePath`" -o `"$targetDir`" -qq"

        try {
            Start-Process $exePath -ArgumentList $exeArgs -Wait -WindowStyle Hidden
        } catch {
            throw "Failed to run $exePath. Error: $($_.Exception.Message)"
        }

        # remove dummy exe file
        Remove-Item $dummyExePath -Force -ErrorAction SilentlyContinue
        
        Write-Host "Packaging complete." -ForegroundColor Green
    } catch {
        throw $_
    }
}

#endregion

#region New-RemediationScript.ps1
function New-RemediationScript {
    [CmdletBinding()]
    param (

    )

    # vars
    $AssignmentGroup = 'gp_co-management_usg'
    $DisplayName = "Update Adobe Apps"
    $Description = "This script will detect if RemoteUpdateManager.exe exists " +
    "on the target machine and then runs it. This downloads and " +
    "installs any updates available for Adobe Creative Cloud Desktop Application apps."
    $Publisher = "Matt McPhee"
    $RunAs = 'SYSTEM'
    $RunAs32 = $false
    $ScheduleFrequency = "1"
    $StartTime = "01:00"
    $DetectionScriptPath = "C:\sources\repos\ps-scripts\intune-scripts\Update-AdobeAppsDetection.ps1"
    $detectionScriptContent = Get-Content $detectionScriptPath
    $detectionScriptContentBytes = [System.Text.Encoding]::UTF8.GetBytes($detectionScriptContent)
    $RemediationScriptPath = "C:\sources\repos\ps-scripts\intune-scripts\Update-AdobeAppsRemediation.ps1"
    $remediationScriptContent = Get-Content $remediationScriptPath
    $remediationScriptContentBytes = [System.Text.Encoding]::UTF8.GetBytes($remediationScriptContent)

    $scriptParams = @{
        displayName = $DisplayName
        description = $Description
        publisher = $Publisher
        runAs32Bit = $RunAs32
        runAsAccount = $RunAs
        enforceSignatureCheck = $false
        detectionScriptContent = $detectionScriptContentBytes
        remediationScriptContent = $remediationScriptContentBytes
        roleScopeTagIds = @("10", "7", "9")
    }

    $graphApiVersion = "beta"
    $resource = "deviceManagement/deviceHealthScripts"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$resource"

    try {
        $remediationScriptResponse = Invoke-MGGraphRequest -Uri $uri `
            -Method POST -Body $scriptParams -ContentType 'application/json' `
            -ErrorAction Stop
    } catch {
        Write-Error "$_"
    }

    $intuneGroupId = (Get-MgBetaGroup -Filter "DisplayName eq '$AssignmentGroup'").Id

    $assignmentParams = @{
        DeviceHealthScriptAssignments = @(
            @{
                Target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    GroupId = $intuneGroupId
                }
                RunRemediationScript = $true
                RunSchedule = @{
                    "@odata.type" = "#microsoft.graph.deviceHealthScriptDailySchedule"
                    Interval = $ScheduleFrequency
                    Time = $StartTime
                    UseUtc = $false
                }
            }
        )
    }

    $scriptId = $remediationScriptResponse.Id
    $uri = "https://graph.microsoft.com/$graphApiVersion/$resource/$scriptId/assign"

    try {
        Invoke-MGGraphRequest -Uri $uri `
            -Method POST -Body $assignmentParams -ContentType 'application/json' `
            -ErrorAction Stop
    } catch {
        Write-Error "$_"
    }
}

#endregion

#region Remove-RemediationScriptAssignment.ps1
function Remove-RemediationScriptAssignment {
    [CmdletBinding(DefaultParameterSetName = "ByGroupId")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByGroupId")]
        [string]$GroupId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByAssignmentId")]
        [string]$AssignmentId,

        [Parameter(Mandatory = $true, ParameterSetName = "All")]
        [switch]$All
    )

    $assignUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assign"

    # 1. Handle removing all assignments
    if ($All) {
        $body = @{
            "deviceHealthScriptAssignments" = @()
        } | ConvertTo-Json

        try {
            Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $body -ContentType "application/json"
            Write-Host "Successfully removed all assignments from Remediation Script: $ScriptId" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to remove all assignments: $_"
        }
        return
    }

    # 2. Fetch existing assignments
    $existingUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assignments"
    try {
        $existing = (Invoke-MgGraphRequest -Method GET -Uri $existingUri).value
    }
    catch {
        Write-Error "Failed to retrieve existing assignments: $_"
        return
    }

    if (-not $existing -or $existing.Count -eq 0) {
        Write-Warning "Remediation Script $ScriptId has no assignments to remove."
        return
    }

    # 3. Filter out the targeted assignment
    $remainingAssignments = [System.Collections.Generic.List[hashtable]]::new()
    $matchFound = $false

    foreach ($item in $existing) {
        $matchesGroup      = ($PSCmdlet.ParameterSetName -eq "ByGroupId" -and $item.target.groupId -eq $GroupId)
        $matchesAssignment = ($PSCmdlet.ParameterSetName -eq "ByAssignmentId" -and $item.id -eq $AssignmentId)

        if ($matchesGroup -or $matchesAssignment) {
            $matchFound = $true
            continue
        }

        # Keep non-matching assignments and rebuild clean object
        $cleanedItem = [ordered]@{
            "@odata.type"          = "#microsoft.graph.deviceHealthScriptAssignment"
            "target"               = $item.target
            "runSchedule"          = $item.runSchedule
            "runRemediationScript" = $item.runRemediationScript
        }
        $remainingAssignments.Add($cleanedItem)
    }

    if (-not $matchFound) {
        $targetIdentifier = if ($PSCmdlet.ParameterSetName -eq "ByGroupId") { "GroupId $GroupId" } else { "AssignmentId $AssignmentId" }
        Write-Warning "No matching assignment found for $targetIdentifier on script $ScriptId."
        return
    }

    # 4. POST the updated assignment list
    $body = @{
        "deviceHealthScriptAssignments" = $remainingAssignments
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $body -ContentType "application/json"
        Write-Host "Successfully updated assignments for Remediation Script: $ScriptId" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to update assignments: $_"
    }
}

#endregion

#region Scrape-Logs.ps1
function Scrape-Logs {
    # Paths
    $logDir   = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
    $regBase  = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"

    $appMap = @{}

    # Search newest logs first (AppWorkload logs hold Win32 app telemetry in modern IME builds)
    $logFiles = Get-ChildItem -Path $logDir -Filter "*.log" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "AppWorkload|IntuneManagementExtension" } |
    Sort-Object LastWriteTime -Descending

    foreach ($file in $logFiles) {
        # Scan for the policy sync line
        Get-Content -Path $file.FullName -ErrorAction SilentlyContinue |
        Where-Object { $_ -match 'Get policies = (\[.+?\])' } |
        ForEach-Object {
            try {
                $policies = $matches[1] | ConvertFrom-Json
                foreach ($app in $policies) {
                    if ($app.Id -and $app.Name -and -not $appMap.ContainsKey($app.Id)) {
                        $appMap[$app.Id] = $app.Name
                    }
                }
            } catch {
                # Skip partial/corrupted log entries
            }
        }
    }

    # Enumerate the registry and resolve names
    $appInventory = [System.Collections.Generic.List[PSCustomObject]]::new()

    Get-ChildItem -Path $regBase -ErrorAction SilentlyContinue | ForEach-Object {
        $context = $_.PSChildName
        Get-ChildItem -Path $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
            $rawGuid   = $_.PSChildName
            $cleanGuid = ($rawGuid -split '_')[0] # Strips revision suffixes like _1
            $props     = Get-ItemProperty -Path $_.PSPath

            $appInventory.Add([PSCustomObject]@{
                AppGuid         = $cleanGuid
                DisplayName     = if ($appMap.ContainsKey($cleanGuid)) { $appMap[$cleanGuid] } else { "Unknown / Log Expired" }
                Scope           = if ($context -eq "00000000-0000-0000-0000-000000000000") { "Device" } else { "User" }
                ComplianceState = $props.ComplianceState
                EnforcementState= $props.EnforcementState
                InstallExCode   = $props.InstallExCode
            })
        }
    }

    # Example: Output to CSV for telemetry/monitoring
    $appInventory | Export-Csv -Path "$env:ProgramData\Win32AppInventory.csv" -NoTypeInformation
}

#endregion

#region Send-GraphEmail.ps1
function Send-GraphEmail {
    [CmdletBinding()]
    param (
        # Subject
        [Parameter(Mandatory)]
        [string]
        $Subject,
        # Content
        [Parameter(Mandatory)]
        [string]
        $Content,
        # Recipients
        [Parameter(Mandatory)]
        [string[]]
        $Recipients,
        # CcRecipients
        [Parameter(Mandatory = $false)]
        [string[]]
        $CcRecipients,
        # BccRecipients
        [Parameter(Mandatory = $false)]
        [string[]]
        $BccRecipients
    )

    [array]$graphRecipients = foreach ($recipient in $Recipients) {
        @{ emailAddress = @{ address = $recipient } }
    }
    
    $mailParams = @{
        Message         = @{
            Subject         = $Subject
            Body            = @{
                ContentType     = "HTML"
                Content         = $Content
            }
            ToRecipients    = $graphRecipients
        }
        SaveToSentItems = $true
    }

    if ($CcRecipients) {
        [array]$graphCcRecipients = foreach ($recipient in $CcRecipients) {
            @{ emailAddress = @{ address = $recipient } }
        }

        $mailParams.Message.CcRecipients = $graphCcRecipients
    }

    if ($BccRecipients) {
        [array]$graphBccRecipients = foreach ($recipient in $BccRecipients) {
            @{ emailAddress = @{ address = $recipient } }
        }

        $mailParams.Message.BccRecipients = $graphBccRecipients
    }

    try {
        Send-MgUserMail -UserId "mm.su@onmatmcp1.onmicrosoft.com" -BodyParameter $mailParams -ErrorAction 'Stop'
    } catch {
        throw "Error: $($_.Exception.Message)"
    }
}

#endregion

#region Update-AdobeAppsDetection.ps1
<#
.SYNOPSIS
Detects if the Adobe RemoteUpdateManager.exe exists on the machine.
.NOTES
Author:     Matt McPhee
Created:    06/05/2025
Updated:    06/05/2025
#>
function Update-AdobeAppsDetection {
    $rumPath = "C:\Program Files (x86)\Common Files\Adobe\OOBE_Enterprise\RemoteUpdateManager\RemoteUpdateManager.exe"
    $logPath = "C:\Windows\Logs\Software\Update-AdobeApps.log"

    if (Test-Path $rumPath) {
        # issue detected
        Write-Log -Message "RemoteUpdateManager.exe detected. Proceeding to launch it." -Level Info -Path $logPath
        exit 1
    } else {
        Write-Log -Message "RemoteUpdateManager.exe not detected. Taking no action." -Level Info -Path $logPath
        exit 0
    }
}
#endregion

#region Update-AdobeAppsRemediation.ps1
<#
.SYNOPSIS
Executes Adobe's RemoteUpdateManager.exe which will update creative cloud
applications on the machine.
.NOTES
Author:     Matt McPhee
Created:    06/05/2025
Updated:    06/05/2025
#>
function Update-AdobeAppsRemediation {
    $rumPath = "C:\Program Files (x86)\Common Files\Adobe\OOBE_Enterprise\RemoteUpdateManager\RemoteUpdateManager.exe"
    $logPath = "C:\Windows\Logs\Software\Update-AdobeApps.log"

    try {
        # attempt to run RemoteUpdateManager.exe
        Start-Process -FilePath $rumPath -WindowStyle 'Hidden' -ErrorAction 'Stop'
        Write-Log -Message "RemoteUpdateManager.exe launched." -Level 'Info' -Path $logPath
    } catch {
        Write-Log -Message "Encountered this error when attempting to launch RemoteUpdateManager.exe:" -Level 'Error' -Path $logPath
        Write-Log -Message "$_" -Level 'Error' -Path $logPath
    }
}
#endregion

#region Add-MITLicence.ps1
function Add-MITLicence {
    [CmdletBinding()]
    param (
        # Path
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Path: '$_' not found."
            }
            if (-not (Test-Path $_ -PathType Container)) {
                throw "Path: '$_' is not a directory."
            }
            $true
        })]
        [string]
        $FolderPath,
        # Name
        [Parameter(Mandatory)]
        [string]
        $Name
    )
    
    # get licence content
    $licenceContent = (Invoke-RestMethod -Uri 'https://api.github.com/licenses/mit').body
    
    # replace year in the content with current year
    $licenceContent = $licenceContent -replace '\[year\]', (Get-Date -Format yyyy)
    
    # replace name in content with name param
    $licenceContent = $licenceContent -replace '\[fullname\]', $Name
    
    # put LICENSE file (no extension) in path
    $licenceContent | Out-File -FilePath "$FolderPath\LICENSE" -Encoding 'utf8' | Out-Null
}

#endregion

#region Add-RemoteLocalGroupMember.ps1
function Add-RemoteLocalGroupMember {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # Group
        [Parameter(Mandatory)]
        [string]
        $Group,
        # Member
        [Parameter(Mandatory)]
        [string]
        $Member
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        try {
            Add-LocalGroupMember -Group $using:Group -Member $using:Member
        } catch {
            $_
        }
    }
}

#endregion

#region Download-HPBiosHPCMSL.ps1
function Download-HPBiosHPCMSL {
    [CmdletBinding()]
    param (
        # Path - path to save .bin bios files to
        [Parameter(Mandatory)]
        [string]$Path,
        # Model - all or part of the laptop model name to search bios for using HPCMSL
        [Parameter(Mandatory)]
        [string]$Model
    )

    if (!(Test-Path $Path -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $Path -Force
    }

    # Resolve the Platform/System Board ID for the Model
    $device = Get-HPDeviceDetails -Name "*$Model*" | Select-Object -First 1

    if ($device) {
        Write-Host "Found $($device.Name) (Platform ID: $($device.SystemID))" -ForegroundColor Cyan
        Write-Host "Downloading latest BIOS..." -ForegroundColor Yellow

        # get bin filename
        $filename = (Get-HPBIOSUpdates -Platform $device.SystemID -Latest).bin

        $biosFilePath = "$Path\$filename"

        # Downloads the latest .bin firmware payload directly into the folder
        Get-HPBIOSUpdates -Platform $device.SystemID -Download -SaveAs $biosFilePath
    } else {
        Write-Warning "Could not find a platform matching: $Model"
    }

    Write-Host "`nAll BIOS downloads complete! Files saved to $biosFilePath" -ForegroundColor Green
}

#endregion

#region Format-Xml.ps1
function Format-Xml {
    param (
        # XmlString
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]
        $XmlString
    )

    try {
        $xml = [xml]$XmlString
    } catch {
        Write-Error "Couldn't format provided XmlString as xml - make sure it has the correct structure."
        return
    }

    # create XmlWriterSettings object to format xml
    $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
    $xmlWriterSettings.Indent = $true
    $xmlWriterSettings.IndentChars = "    "
    $xmlWriterSettings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
    $xmlWriterSettings.OmitXmlDeclaration = $true

    # create a StringWriter to capture the output as a string
    $stringWriter = New-Object System.IO.StringWriter

    # create XmlWriter using xmlwritersettings and stringwriter
    $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $xmlWriterSettings)

    # write the xml string
    $xml.WriteTo($xmlWriter)

    # close the writer to flush it out
    $xmlWriter.Close()

    # return formatted output
    return $stringWriter.ToString()
}
#endregion

#region Get-BlockLetters.ps1
function Get-BlockLetters {
    [CmdletBinding()]
    [Alias('gbl')]
    param (
        # Text
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $Text,
        # Colour
        [Parameter(Mandatory=$false)]
        [string]
        $Colour
    )
    
    begin {
        $asciiTable = @{
            'A' = @(
                ' ______   ',
                '/\  __ \  ',
                '\ \  __ \ ',
                ' \ \ \ \ \',
                '  \/_/\/_/'
            )
            'B' = @(
                ' _____    ',
                '/\  _ \_  ',
                '\ \  __ \ ',
                ' \ \_____\',
                '  \/_____/'
            )
            'C' = @(
                ' ______   ',
                '/\  ___\  ',
                '\ \ \____ ',
                ' \ \_____\',
                '  \/_____/'
            )
            'D' = @(
                ' _____   ',
                '/\  __"- ',
                '\ \ \_\ \',
                ' \ \____/',
                '  \/___/ '
            )
            'E' = @(
                ' ______   ',
                '/\  ___\  ',
                '\ \  ___\ ',
                ' \ \_____\',
                '  \/_____/'
            )
            'F' = @(
                ' ______ ',
                '/\  ___\',
                '\ \  _\/',
                ' \ \_\/ ',
                '  \/_/  '
            )
            'G' = @(
                ' _____    ',
                '/\  __\_  ',
                '\ \ \_\ \ ',
                ' \ \__   \',
                '  \/__/\_/'
            )
            'H' = @(
                ' __  __   ',
                '/\ \_\ \  ',
                '\ \  __ \ ',
                ' \ \_\ \_\',
                '  \/_/\/_/'
            )
            'I' = @(
                ' ______   ',
                '/\__  _\  ',
                '\/__\ \__ ',
                '  /\_____\',
                '  \/_____/'
            )
            'J' = @(
                ' ____   ',
                '/\__ \  ',
                '\/__\ \ ',
                '/\_____\',
                '\/_____/'
            )
            'K' = @(
                ' __   _   ',
                '/\ \-" \  ',
                '\ \  --"_ ',
                ' \ \ \-. \',
                '  \/_/ /_/'
            )
            'L' = @(
                ' __      ',
                '/\ \     ',
                '\ \ \___ ',
                ' \ \____\',
                '  \/____/'
            )
            'M' = @(
                ' __    __   ',
                '/\ "-./  \  ',
                '\ \ \-./\ \ ',
                ' \ \_\ \ \_\',
                '  \/_/  \/_/'
            )
            'N' = @(
                ' __    __   ',
                '/\  "-.\ \  ',
                '\ \ \"-.  \ ',
                ' \ \_\ \ \_\',
                '  \/_/  \/_/'
            )
            'O' = @(
                ' ______   ',
                '/\  __ \  ',
                '\ \ \_\ \ ',
                ' \ \_____\',
                '  \/_____/'
            )
            'P' = @(
                ' ______  ',
                '/\  __ \ ',
                '\ \  __/ ',
                ' \ \ \/  ',
                '  \/_/   '
            )
            'Q' = @(
                ' ______  ',
                '/\  __ \ ',
                '\ \__  _\',
                ' \/_/\__\',
                '    \/__/'
            )
            'R' = @(
                ' _______  ',
                '/\  ___ \ ',
                '\ \  __ / ',
                ' \ \_\ \_\',
                '  \/_/\/_/'
            )
            'S' = @(
                ' ______   ',
                '/\  ___\  ',
                '\ \___  \ ',
                ' \/\_____\',
                '  \/_____/'
            )
            'T' = @(
                ' ______  ',
                '/\__  _\ ',
                '\/_ \ \/ ',
                '   \ \_\ ',
                '    \/_/ '
            )
            'U' = @(
                ' __   __   ',
                '/\ \  \ \  ',
                '\ \ \__\ \ ',
                ' \ \______\',
                '  \/______/'
            )
            'V' = @(
                ' __ __   ',
                '/\ \\ \  ',
                '\ \ \\ \ ',
                ' \ \____\',
                '  \/____/'
            )
            'W' = @(
                ' __ _ _   ',
                '/\ \ \ \  ',
                '\ \ \ \ \ ',
                ' \ \_____\',
                '  \/_____/'
            )
            'X' = @(
                ' ___  ___   ',
                '/\__\_\__\  ',
                '\/_/\__\_/_ ',
                ' /\__\_/\__\',
                ' \/__/ \/__/'
            )
            'Y' = @(
                ' __  __  ',
                '/\ \_\ \ ',
                '\ \__  _\',
                ' \/_/\ \/',
                '    \/_/ '
            )
            'Z' = @(
                ' _____   ',
                '/\__  |  ',
                '\/_/ /__ ',
                '  /\____\',
                '  \/____/'
            )
            ' ' = @(
                '   ',
                '   ',
                '   ',
                '   ',
                '   '
            )
            '-' = @(
                '      ',
                ' ____ ',
                '/\___\',
                '\/___/',
                '      '
            )
            '1' = @(
                ' __   ',
                '/\ \  ',
                '\ \ \ ',
                ' \ \_\',
                '  \/_/'
            )
            '2' = @(
                ' _____   ',
                '/\__  \  ',
                '\/_-" /_ ',
                ' /\_____\',
                ' \/_____/'
            )
            '3' = @(
                ' ______   ',
                '/\___  \  ',
                '\//\__  \ ',
                ' \/\_____\',
                '  \/_____/'
            )
            '4' = @(
                ' __  __   ',
                '/\ \_\ \  ',
                '\ \____ \ ',
                ' \/___/\ \',
                '      \/_/'
            )
            '5' = @(
                ' ______   ',
                '/\  ___\  ',
                '\ \___  \ ',
                ' \/\_____\',
                '  \/_____/'
            )
            '6' = @(
                ' __       ',
                '/\ \____  ',
                '\ \  __ \ ',
                ' \ \_____\',
                '  \/_____/'
            )
            '7' = @(
                ' ______   ',
                '/\___  \  ',
                '\/___\  \ ',
                '    \ \__\',
                '     \/__/'
            )
            '8' = @(
                ' ______   ',
                '/\  __ \  ',
                '\ \  __ \ ',
                ' \ \_____\',
                '  \/_____/'
            )
            '9' = @(
                ' ______   ',
                '/\  __ \  ',
                '\ \____ \ ',
                ' \/___/\ \',
                '      \/_/'
            )
            '0' = @(
                ' ______   ',
                '/\  __ \  ',
                '\ \ \_\ \ ',
                ' \ \_____\',
                '  \/_____/'
            )
            '!' = @(
                ' __   ',
                '/\ \  ',
                '\ \_\ ',
                ' \/\_\',
                '  \/_/'
            )
        }
    }
    
    process {
        $text = $Text.ToUpper()

        $lines = @('#', '#', '#', '#', '#')

        foreach ($char in $text.ToCharArray()) {
            if ($asciiTable.ContainsKey([string]$char)) {
                $charLines = $asciiTable[[string]$char]
                for ($i = 0; $i -lt 5; $i++) {
                    $lines[$i] += $charLines[$i]
                }
            }
        }

        if ($Colour) {
            try {
                foreach ($line in $lines) {
                    Write-Host $line -ForegroundColor $Colour
                }
            } catch {
                throw "Colour: '$Colour' is not a valid colour."
            }
        } else {
            $lines
        }
    }
    
    end {
        
    }
}

#endregion

#region Get-Departments.ps1
function Get-Departments {
    $initialLocation = Get-Location
    Set-Location -Path "C:\"
    $csvPath = "\\bmd\bmdapps\BI\JamesG\Departments.csv"
    $csvDestination = "$env:USERPROFILE\Downloads\Departments.csv"
    Copy-Item -Path $csvPath -Destination $csvDestination -Force
    Import-Csv -Path $csvDestination
    Set-Location -Path $initialLocation
}

#endregion

#region Get-FolderSizeBytes.ps1
function Get-FolderSizeBytes {
    [CmdletBinding()]
    param (
        # FolderPath
        [Parameter(Mandatory)]
        [string]
        $FolderPath
    )
    
    (Get-ChildItem -Path $FolderPath -File -Recurse | Measure-Object -Property Length -Sum).Sum
}
#endregion

#region Get-FolderSizesGroupObject.ps1
function Get-FolderSizesGroupObject {
    [CmdletBinding()]
    param (
        # FolderPath
        [Parameter(Mandatory)]
        [string]
        $FolderPath
    )
    try {
        Get-ChildItem -Path $FolderPath -Recurse -File |
        Where-Object { $_.Length -gt '1MB' } |
        Group-Object { $_.Directory.FullName } |
        Select-Object @{
            name = 'Folder'
            expr = { $_.Name }
        },
        @{
            name = 'SizeGB'
            expr = { [math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1GB, 3) }
        } |
        Where-Object { $_.SizeGB -gt '0.01'}
    } catch {
        throw $_
    }
}

#endregion

#region Get-FolderSizesRecurse.ps1
function Get-FolderSizesRecurse {
    [CmdletBinding()]
    param (
        # FolderPath
        [Parameter(Mandatory)]
        [string]
        $FolderPath
    )
    try {
        Get-ChildItem -Path $FolderPath -Directory -Recurse | ForEach-Object {
            $size = (Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{
                Folder = $_.FullName
                SizeGB = [math]::Round($size / 1GB, 2)
            }
        }
    } catch {
        throw $_
    }
}

#endregion

#region Get-InstalledApps.ps1
#region Comments
<#
.SYNOPSIS
This function searches the 64bit and 32bit registry stores for installed
applications and displays info about them
.NOTES
Author:     Matt McPhee
Created:    2025-06-02
Changelog:  2025-11-05 - added test paths for office click to run and bmd reg keys
.PARAMETER ComputerName
The name of the computer on the network. If this is not supplied, it will use
the computer the script runs on.
.PARAMETER ApplicationName
The name of the application. You should use wildcards on either side. If this
is not supplied, it will return all apps found in the registry.
.EXAMPLE
Get-InstalledApps -ComputerName MMWIN11-05 -ApplicationName *note*
#>
function Get-InstalledApps {
    [CmdletBinding()]
    param(
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName,
        # ApplicationName
        [Parameter(Mandatory=$false)]
        [string]
        $ApplicationName
    )

    $getAppsScriptBlock = {
        $apps = @()

        $x64Apps = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            Select-Object *,@{ n="RegistryKey"; e={$_.PSPath.Substring(36)} }
        $apps += $x64Apps

        $x86Apps = Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            Select-Object *,@{ n="RegistryKey"; e={$_.PSPath.Substring(36)} }
        $apps += $x86Apps

        $selectProperties = @(
            'DisplayName',
            'DisplayVersion',
            'InstallLocation',
            'UninstallString',
            'QuietUninstallString',
            'RegistryKey'
        )

        return $apps | Select-Object $selectProperties
    }

    if ($ComputerName) {
        $apps = Invoke-Command -ComputerName $ComputerName -ScriptBlock $getAppsScriptBlock
    } else {
        $apps = & $getAppsScriptBlock
    }

    if ($ApplicationName) {
        return $apps | Where-Object { $_.DisplayName -like $ApplicationName } | Sort-Object DisplayName
    } else {
        return $apps | Sort-Object DisplayName
    }
}

#endregion

#region Get-PSADTTemplateLatest.ps1
function Get-PSADTTemplateLatest {
    [CmdletBinding()]
    param (
        # DestinationFolder
        [Parameter(Mandatory)]
        [string]
        $DestinationFolder
    )
    
    $repo = "PSAppDeployToolkit"
    $githubUrl = "https://api.github.com/repos/$repo/$repo/releases/latest"
    
    $fileName = "PSAppDeployToolkit_Template_v4.zip"
    $outFile = Split-Path -Path $DestinationFolder -Parent | Join-Path -ChildPath $fileName


    # if folder exists, rename it to timestamp
    if (Test-Path -Path $DestinationFolder) {
        try {
            $timestamp = Get-Date -Format "yyyyMMddhhmmss"
            $newName = "$timestamp-psadt"
            Write-Host "Path already exists. Renaming folder to $newName"
            Rename-Item -Path $DestinationFolder -NewName $newName -Force
        } catch {
            throw $_
        }
    }

    # create destination folder if it doesn't exist
    if (-not (Test-Path -Path $DestinationFolder)) {
        Write-Host "Creating directory: $DestinationFolder"
        $null = New-Item -Path $DestinationFolder -ItemType Directory
    }

    # get latest release info from github
    Write-Host "Querying github for latest release..."
    try {
        $ProgressPreference = 'SilentlyContinue'

        $releaseInfo = Invoke-RestMethod -Uri $githubUrl

        $asset = $releaseInfo.assets | Where-Object { $_.name -eq $fileName }

        if ($asset) {
            $downloadUrl = $asset.browser_download_url
            Write-Host "Found latest release $($releaseInfo.tag_name) with download URL $downloadUrl"
        } else {
            throw "Could not find $fileName in the latest release."
        }
    } catch {
        throw "Failed to connect to github or parse response: $_"
    }

    # remove zip if it exists
    if (Test-Path $outFile) {
        Remove-Item -Path $outFile -Force
    }
    
    # download the file
    Write-Host "Downloading $fileName from $downloadUrl..."
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outFile
        Write-Host "Download saved to $outFile"
    } catch {
        throw "Failed to download file: $_"
    }

    # extract the file
    Write-Host "Extracting $fileName to $DestinationFolder..."
    try {
        $7zArgs = "x `"$outFile`" -o`"$DestinationFolder`""
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList $7zArgs -WindowStyle Hidden -Wait
        Write-Host "Successfully extracted $fileName to $DestinationFolder"
    } catch {
        throw "Error encountered when attempting to extract: $_"
    }
}
#endregion

#region Get-RemoteLocalGroupMember.ps1
function Get-RemoteLocalGroupMember {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # Group
        [Parameter(Mandatory)]
        [string]
        $Group
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        try {
            Get-LocalGroupMember -Group $using:Group
        } catch {
            $_
        }
    }
}

#endregion

#region Install-LatestVSTOR2010.ps1
function Install-LatestVSTOR2010 {
    function Write-Log {
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]
            $Message,
            # Path
            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path = "C:\Windows\Logs\Software\Install-LatestVSTOR2010.log",
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]
            $Level = "Info",
            # Component
            [Parameter(Mandatory = $false)]
            [string]
            $Component = "PowerShellScript",
            # Context
            [Parameter(Mandatory = $false)]
            [string]
            $Context = "PowerShellScript",
            # Quiet - suppresses output
            [Parameter(Mandatory = $false)]
            [switch]
            $Quiet = $false
        )

        process {
            foreach ($line in $Message) {
                if (-not $Quiet) {
                    # output the message
                    Write-Host $Message
                }

                # convert level to type codes so cmtrace can read it
                switch ($Level) {
                    "Info" { [int]$type = 1 }
                    "Warning" { [int]$type = 2 }
                    "Error" { [int]$type = 3 }
                }

                $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                $scriptName = $MyInvocation.MyCommand.Name

                # create log entry
                $logLine = "<![LOG[$Message]LOG]!>" +
                "<" +
                "time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +
                "date=`"$(Get-Date -Format "d-M-yyyy")`" " +
                "component=`"$Component`" " +
                "context=`"$Context`" " +
                "type=`"$type`" " +
                "thread=`"$threadId`" " +
                "file=`"$scriptName`"" +
                ">"

                # append line to log file
                $logLine | Out-File -FilePath $Path -Append -Encoding utf8
            }
        }
    }

    $url = "https://go.microsoft.com/fwlink/?linkid=140384"
    $destination = "C:\windows\ccmcache\vstor2010\vstor_redist.exe"

    try {
        Write-Log "Beginning download of VSTOR 2010." -Quiet
        Write-Log "Landing page URL is $url" -Quiet

        $pattern = 'https://download\.microsoft\.com/[\w\-/]+vstor_redist\.exe'
        $res = Invoke-WebRequest -Uri $url -UseBasicParsing
        $latestUrl = [regex]::match($res.Content, $pattern).Value

        Write-Log "Download URL from landing page is $latestURL" -Quiet
        Write-Log "Downloading to $destination" -Quiet
        Invoke-WebRequest -Uri $latestUrl -OutFile $destination
        Write-Log "Executing '$destination /q /norestart'" -Quiet

        Start-Process -FilePath $destination -ArgumentList "/q /norestart" -Wait

        Write-Log "Completed installation of VSTOR 2010." -Quiet
    } catch {
        Write-Error "Failed to download the latest VSTO runtime: $_"
        return 1
    }
}

#endregion

#region Invoke-PsExecScript.ps1
function Invoke-PsExecScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Leaf)) {
                throw "Script file does not exist: $_"
            }

            if ([System.IO.Path]::GetExtension($_) -ne '.ps1') {
                throw "File must be a PowerShell .ps1 script."
            }

            $true
        })]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory=$false)]
        [string]$PsExecPath = 'C:\sources\staging\PSTools\PsExec.exe',

        [Parameter(Mandatory=$false)]
        [switch]$KeepRemoteScript
    )

    $scriptPath = (Resolve-Path $Path).Path

    foreach ($Computer in $ComputerName) {
        $fileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
        $fileName = '{0}_{1}.ps1' -f $fileNameNoExt, [guid]::NewGuid().ToString('N')

        $remoteDirectory = "\\$Computer\C$\ProgramData\BMD\PsExec"
        $remoteUNCPath   = Join-Path $remoteDirectory $fileName
        $remoteLocalPath = "C:\ProgramData\BMD\PsExec\$fileName"

        try {
            # Create temporary directory on remote machine
            if (-not (Test-Path $remoteDirectory)) {
                New-Item `
                    -Path $remoteDirectory `
                    -ItemType Directory `
                    -Force `
                    -ErrorAction Stop |
                    Out-Null
            }

            # Copy script to remote machine
            Copy-Item `
                -Path $scriptPath `
                -Destination $remoteUNCPath `
                -Force `
                -ErrorAction Stop

            # Build PsExec arguments
            $psExecArgs = @(
                "\\$Computer"
                '-accepteula'
                '-nobanner'
                '-s'
            )

            $psExecArgs += @(
                'powershell.exe'
                '-NoProfile'
                '-ExecutionPolicy'
                'Bypass'
                '-File'
                $remoteLocalPath
            )

            if ($ArgumentList) {
                $psExecArgs += $ArgumentList
            }

            Write-Verbose "Running $Path on $Computer"

            & $PsExecPath @psExecArgs

            $exitCode = $LASTEXITCODE

            [pscustomobject]@{
                ComputerName = $Computer
                Script       = $scriptPath
                exitCode     = $exitCode
                Success      = ($exitCode -eq 0)
            }
        } catch {
            Write-Error "Failed to run script on $Computer : $_"
        } finally {
            if (-not $KeepRemoteScript) {
                Remove-Item `
                    -Path $remoteUNCPath `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }
}

#endregion

#region New-Day.ps1
function New-Day {
    [CmdletBinding()]
    param (
        # Day
        [Parameter(Mandatory)]
        [ValidateSet("Monday","Tuesday","Wednesday","Thursday","Friday")]
        [string]
        $Day
    )

    $date = Get-Date -Format "yyyy-MM-dd"
    $dateLong = Get-Date -Format "dd-MMM-yyyy"
    $dateArr = $date -split "-"
    $dateYear = $dateArr[0]
    # $dateMonth = $dateArr[1]
    # $dateDay = $dateArr[2]
    $notePath = "$env:systemdrive\sources\repos\weekly-notepad\weeklynotepad$dateYear\$date.txt"

    if (-not ($notePath)) {
        New-Item -Path $notePath -Force
    }

    Get-BlockLetters $Day | Add-Content -Path $notePath
    Get-BlockLetters $dateLong | Add-Content -Path $notePath
    Add-Content -Path $notePath -Value ""
}

#endregion

#region New-ScriptFiles.ps1
function New-ScriptFiles {
    param (
        # Path
        [Parameter(Mandatory)]
        [string]
        $Path,
        # NumberOfScripts
        [Parameter(Mandatory)]
        [int]
        $NumberOfScripts
    )

    for ($i = 0; $i -lt $NumberOfScripts; $i++) {
        $randomFileName = "example-script{0}.ps1" -f (Get-Random -Minimum 1 -Maximum 999999)

        $filePath = "$Path\$randomFileName"

        New-Item -Path $filePath -ItemType File -Force

        Set-Content -Path $filePath -Value $filePath
    }
}

#endregion

#region Round-Nearest100.ps1
function Round-Nearest100 {
    param (
        # number
        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Number
    )

    return ($Number + (100 - ($Number % 100)))
}

#endregion

#region Start-MSEdge.ps1
function Start-MSEdge {
    [CmdletBinding()]
    [Alias('edge')]
    param (
        # FilePath
        [Parameter(Mandatory=$false,ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [string[]]
        $FilePath
    )
    
    begin {
        $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        if (-not (Test-Path $edgePath)) {
            throw "Could not find msedge.exe at $edgePath"
        }
    }
    
    process {
        if ($FilePath) {
            foreach ($path in $FilePath) {
                Start-Process 'msedge' -ArgumentList $path -Wait
            }
        } else {
            Start-Process 'msedge' -Wait
        }
    }
    
    end {
        
    }
}

#endregion

#region Test-FolderWriteSpeed.ps1
function Test-FolderWriteSpeed {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [int]$SizeMB = 100
    )

    $TestFile = Join-Path $Path "SpeedTest_$([guid]::NewGuid()).tmp"
    $Buffer   = New-Object byte[] (1MB)
    $Watch    = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $Stream = [System.IO.File]::Create($TestFile)

        for ($i = 0; $i -lt $SizeMB; $i++) {
            $Stream.Write($Buffer, 0, $Buffer.Length)
        }

        $Stream.Flush()
        $Stream.Close()

        $Watch.Stop()

        [pscustomobject]@{
            Path     = $Path
            SizeMB   = $SizeMB
            Seconds  = [math]::Round($Watch.Elapsed.TotalSeconds, 2)
            'MB/s'     = [math]::Round($SizeMB / $Watch.Elapsed.TotalSeconds, 2)
        }
    }
    finally {
        if ($Stream) {
            $Stream.Dispose()
        }

        Remove-Item $TestFile -Force -ErrorAction SilentlyContinue
    }
}

#endregion

#region Test-UdpConnection.ps1
function Test-UdpPort {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    Write-Host "Testing UDP port $Port on $ComputerName..."

    try {
        # Create a new UDP Client object
        $UdpClient = New-Object System.Net.Sockets.UdpClient

        # Set a short timeout for the check
        $UdpClient.Client.ReceiveTimeout = 2000  # 2 seconds

        # Attempt to connect (bind to the port)
        $UdpClient.Connect($ComputerName, $Port)
        
        Write-Host "UDP Port $Port on $ComputerName appears to be OPEN." -ForegroundColor Green
    } catch {
        Write-Host "UDP Port $Port on $ComputerName appears to be CLOSED or UNREACHABLE." -ForegroundColor Red
    } finally {
        # Clean up the object
        if ($UdpClient) { $UdpClient.Close() }
    }
}

#endregion

#region Unprotect-ExcelWorkbook.ps1
function Unprotect-ExcelWorkbook {
    <#
    .SYNOPSIS
    Removes sheet and workbook structure protection from an .xlsx file.

    .DESCRIPTION
    Extracts the .xlsx archive, searches workbook.xml and all sheet.xml files 
    for the <workbookProtection> and <sheetProtection> tags, removes them, 
    and re-compresses the file into a new unprotected document.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    # 1. Validate File
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    $fileInfo = Get-Item $FilePath
    if ($fileInfo.Extension -ne '.xlsx') {
        throw "This script only works on .xlsx files."
    }

    # 2. Setup Paths
    $directory = $fileInfo.DirectoryName
    $baseName = $fileInfo.BaseName
    $newFilePath = Join-Path $directory "$($baseName)_Unprotected.xlsx"
    $tempZipPath = Join-Path $directory "$($baseName)_temp.zip"
    $tempExtractPath = Join-Path $directory "$($baseName)_temp_extract"

    # Clean up any residual temp folders from previous failed runs
    if (Test-Path $tempExtractPath) { Remove-Item $tempExtractPath -Recurse -Force }
    if (Test-Path $tempZipPath) { Remove-Item $tempZipPath -Force }

    try {
        Write-Host "Creating working copy and extracting..." -ForegroundColor Cyan
        Copy-Item $FilePath $tempZipPath
        Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

        # Excel requires UTF-8 without a Byte Order Mark (BOM). 
        # Standard Out-File/Set-Content can corrupt the XML, so we use .NET directly.
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false

        # 3. Process workbook.xml (Workbook Structure Protection)
        $workbookPath = Join-Path $tempExtractPath "xl\workbook.xml"
        if (Test-Path $workbookPath) {
            $xmlContent = Get-Content $workbookPath -Raw
            if ($xmlContent -match '<workbookProtection[^>]*>') {
                Write-Host " -> Removing workbook protection..."
                $xmlContent = $xmlContent -replace '<workbookProtection[^>]*>', ''
                [System.IO.File]::WriteAllText($workbookPath, $xmlContent, $utf8NoBom)
            }
        }

        # 4. Process sheet*.xml files (Sheet Edit Protection)
        $sheetsPath = Join-Path $tempExtractPath "xl\worksheets"
        if (Test-Path $sheetsPath) {
            $sheetFiles = Get-ChildItem -Path $sheetsPath -Filter "*.xml"
            foreach ($sheet in $sheetFiles) {
                $sheetPath = $sheet.FullName
                $xmlContent = Get-Content $sheetPath -Raw
                if ($xmlContent -match '<sheetProtection[^>]*>') {
                    Write-Host " -> Removing protection from $($sheet.Name)..."
                    $xmlContent = $xmlContent -replace '<sheetProtection[^>]*>', ''
                    [System.IO.File]::WriteAllText($sheetPath, $xmlContent, $utf8NoBom)
                }
            }
        }

        # 5. Re-compress the file
        Write-Host "Re-compressing file into new .xlsx..." -ForegroundColor Cyan
        # Note: We zip the contents of the folder (\*), not the folder itself.
        Compress-Archive -Path "$tempExtractPath\*" -DestinationPath $tempZipPath -Force
        Copy-Item -Path $tempZipPath -Destination $newFilePath -Force

        Write-Host "Success! Unprotected file saved to: $newFilePath" -ForegroundColor Green

    }
    catch {
        Write-Error "An error occurred: $_"
    }
    finally {
        # 6. Cleanup Temp Files
        Write-Host "Cleaning up temporary files..."
        if (Test-Path $tempExtractPath) { Remove-Item $tempExtractPath -Recurse -Force }
        if (Test-Path $tempZipPath) { Remove-Item $tempZipPath -Force }
    }
}

#endregion

#region Wait-ProcessPolled.ps1
function Wait-ProcessPolled {
    [CmdletBinding()]
    param (
        # ProcessName - process to wait for
        [Parameter(Mandatory)]
        [string]
        $ProcessName,
        # MaxAttempts - number of times to poll the process
        [Parameter(Mandatory)]
        [ValidateRange("Positive")]
        [int]
        $MaxAttempts,
        # WaitSeconds - seconds to wait between polling
        [Parameter(Mandatory)]
        [ValidateRange("Positive")]
        [int]
        $WaitSeconds,
        # LogPath - path to write logs to. This is mandatory because this function is specifically to be used with no-touch scripts.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                $dir = Split-Path $_ -Parent
                if (Test-Path $dir) {
                    return $true
                } else {
                    throw "LogPath: The folder path '$dir' does not exist."
                }
            })]
        [string]
        $LogPath
    )

    $curAttempts = 0
    while ($curAttempts -lt $MaxAttempts) {
        $curAttempts++
        try {
            $proc = Get-Process -Name $ProcessName
            if ($proc) {
                $msg = "$ProcessName is still running. Waiting $waitSecs seconds. This is attempt $curAttempts out of $maxAttempts."
                Write-Log -Message $msg -Level Info -Path $LogPath
            }
        } catch {
            Write-Log "Process not found. Proceeding..." -Level Info -Path $LogPath
            break
        }
        Start-Sleep -Seconds $waitSecs
    }
}

#endregion

#region Write-CMLog.ps1
<#
.SYNOPSIS
    This function will write a message to a file for logging purposes.
.PARAMETER Message
    A message to be logged. Can accept an array of messages (each message will be logged on a separate line).
.PARAMETER Level
    The severity level of the log line. Can be Info (default), Warn or Error.
.PARAMETER Path
    The desired path the log will be written to. Must include filename and file extension.
.OUTPUTS
    Appends a line to a log file.
#>
function Write-CMLog {
    [CmdletBinding()]
    param(
        # Message
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]
        $Message,
        # Path
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        # Level
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string]
        $Level = "Info",
        # Component
        [Parameter(Mandatory = $false)]
        [string]
        $Component = "PowerShellScript",
        # Context
        [Parameter(Mandatory = $false)]
        [string]
        $Context = "PowerShellScript",
        # Quiet - suppresses output
        [Parameter(Mandatory = $false)]
        [switch]
        $Quiet = $false
    )

    process {
        $logDir = Split-Path $Path -Parent

        if (-not (Test-Path -Path $logDir -PathType Container)) {
            try {
                New-Item -ItemType Directory -Path $logDir -ErrorAction Stop -Force
            } catch {
                throw "Could not create log directory: $logDir $_"
            }
        }

        $now = Get-Date
        $tzOffset = [TimeZoneInfo]::Local.GetUtcOffset($now).TotalMinutes
        $timeStr = $now.ToString("HH:mm:ss.fff") + ("{0:+000;-000;+000}" -f $tzOffset)
        $dateStr = $now.ToString("MM-dd-yyyy")

        foreach ($line in $Message) {
            if (-not $Quiet) {
                # output the message
                Write-Output $line
            }

            # convert level to type codes so cmtrace can read it
            switch ($Level) {
                "Info" { [int]$type = 1 }
                "Warning" { [int]$type = 2 }
                "Error" { [int]$type = 3 }
            }

            $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            $scriptName = $MyInvocation.MyCommand.Name

            # create log entry
            $logLine = "<![LOG[$line]LOG]!>" +
            "<" +
            "time=`"$timeStr`" " +
            "date=`"$dateStr`" " +
            "component=`"$Component`" " +
            "context=`"$Context`" " +
            "type=`"$type`" " +
            "thread=`"$threadId`" " +
            "file=`"$scriptName`"" +
            ">"

            # append line to log file
            $logLine | Out-File -FilePath $Path -Append -Encoding utf8
        }
    }
}

#endregion

#region Write-DashLine.ps1
function Write-DashLine {
    param(
        [string]$Text
    )

    $totalLength = 100
    $dashCount = $totalLength - $Text.Length
    $dashChar = "="
    $boundChar = "|"
    $boundStart = $boundChar + $dashChar * 3
    $boundEnd = $dashChar * 3 + $boundChar

    if ($dashCount -le 0) {
        $line = "$boundStart $Text $boundEnd"
    } else {
        $boundEndDynamic = $dashChar * ($dashCount) + $boundEnd
        $line = "$boundStart $Text $boundEndDynamic"
    }

    Write-Host $line -ForegroundColor Cyan
}

#endregion

#region Remove-AutoCADRegKeys.ps1
function Remove-AutoCADRegKeys {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # UserUPN
        [Parameter(Mandatory)]
        [string]
        $UserUPN,
        # ApplicationName
        [Parameter(Mandatory)]
        [ValidateSet("AutoCAD 2024", "AutoCAD Civil 3D 2025")]
        [string]
        $ApplicationName
    )

    function Write-CMLog {
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]
            $Message,
            # Path
            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path = "C:\Windows\Logs\Software\Remove-AutoCADRegKeys.log",
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]
            $Level = "Info",
            # Component
            [Parameter(Mandatory = $false)]
            [string]
            $Component = "PowerShellScript",
            # Context
            [Parameter(Mandatory = $false)]
            [string]
            $Context = "PowerShellScript",
            # Quiet - suppresses output
            [Parameter(Mandatory = $false)]
            [switch]
            $Quiet = $false
        )

        process {
            foreach ($line in $Message) {
                if (-not $Quiet) {
                    # output the message
                    Write-Host $Message
                }

                # convert level to type codes so cmtrace can read it
                switch ($Level) {
                    "Info" { [int]$type = 1 }
                    "Warning" { [int]$type = 2 }
                    "Error" { [int]$type = 3 }
                }

                $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                $scriptName = $MyInvocation.MyCommand.Name

                # create log entry
                $logLine = "<![LOG[$Message]LOG]!>" +
                "<" +
                "time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +
                "date=`"$(Get-Date -Format "d-M-yyyy")`" " +
                "component=`"$Component`" " +
                "context=`"$Context`" " +
                "type=`"$type`" " +
                "thread=`"$threadId`" " +
                "file=`"$scriptName`"" +
                ">"

                # append line to log file
                $logLine | Out-File -FilePath $Path -Append -Encoding utf8
            }
        }
    }

    # confirm user is logged in
    try {
        $explorerProcesses = Get-CimInstance -ClassName Win32_Process -ComputerName $ComputerName -Filter "Name = 'explorer.exe'"

        $loggedOnUsers = foreach ($proc in $explorerProcesses) {
            (Invoke-CimMethod -InputObject $proc -MethodName GetOwner).User
        }

        if ($loggedOnUsers -contains $UserUPN) {
            Write-CMLog "$UserUPN is currently logged into $ComputerName"
        } else {
            throw "ERROR: $UserUPN is not currently logged into $ComputerName. $UserUPN must be logged in. $_"
        }
    } catch {
        throw "ERROR: $_"
    }

    try {
        Write-CMLog -Message "Attempting to remove reg keys for '$ApplicationName'"
        $sid = (Get-ADUser -Identity $UserUPN).SID
        Write-CMLog -Message "$UserUPN SID is '$sid'"

        if ($ApplicationName -eq "AutoCAD 2024") {
            $appRegPath = "R24.3\ACAD-7101:409"
        } elseif ($ApplicationName -eq "AutoCAD Civil 3D 2025") {
            $appRegPath = "R25.0\ACAD-8100:409"
        }

        $keyPath = "$sid\Software\Autodesk\AutoCAD\$appRegPath"
        Write-CMLog -Message "Registry path to recursively delete will be: 'HKEY_USERS\$keyPath'"

        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                try {
                    [Microsoft.Win32.Registry]::Users.DeleteSubKeyTree($using:keyPath, $false)
                } catch {
                    throw "ERROR: $_"
                }
            }
        } catch {
            throw "ERROR: $_"
        }

        Write-CMLog -Message "Successfully deleted 'HKEY_USERS\$keyPath' (or it did not exist)."
    } catch {
        throw "ERROR: $_"
    }
}

#endregion

#region Set-BestAppearanceWin11.ps1
function Set-BestAppearanceWin11 {
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

        $themePath = 'HKU:\S-1-5-21-36468863-1111239545-1232828436-70408\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $explorerPath = 'HKU:\S-1-5-21-36468863-1111239545-1232828436-70408\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        $searchPath = 'HKU:\S-1-5-21-36468863-1111239545-1232828436-70408\Software\Microsoft\Windows\CurrentVersion\Search'

        # $themePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        # $explorerPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        # $searchPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'

        Set-ItemProperty -Path $themePath -Name AppsUseLightTheme -Value 0
        Set-ItemProperty -Path $themePath -Name SystemUsesLightTheme -Value 0

        Set-ItemProperty -Path $explorerPath -Name DontPrettyPath -Value 1
        Set-ItemProperty -Path $explorerPath -Name ShowTaskViewButton -Value 0
        Set-ItemProperty -Path $explorerPath -Name TaskbarAl -Value 0
        Set-ItemProperty -Path $explorerPath -Name TaskGlomLevel -Value 2
        Set-ItemProperty -Path $explorerPath -Name TaskbarSn -Value 0
        Set-ItemProperty -Path $explorerPath -Name TaskbarSd -Value 0
        Set-ItemProperty -Path $explorerPath -Name SearchboxTaskbarMode -Value 0
        Set-ItemProperty -Path $explorerPath -Name Start_Layout -Value 1

        Set-ItemProperty -Path $searchPath -Name SearchboxTaskbarMode -Value 0
    }
}

#endregion

#region Add-DeviceToCollection.ps1
function Add-DeviceToCollection {
    [CmdletBinding()]
    param(
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # MACAddress
        [Parameter(Mandatory)]
        [string]
        $MACAddress,
        # CollectionName
        [Parameter(Mandatory)]
        [string]
        $CollectionName
    )

    try {
        # check if machine name already exists
        try {
            $cmDevice = Get-CMDevice -Name $ComputerName -ErrorAction Stop
        } catch {
            $cmDevice = $null
        }

        if ($cmDevice) {
            throw "A device named $ComputerName already exists."
        }

        # check if mac address already taken
        $cmDeviceMac = Get-CMDevice -Fast | Where-Object { $_.MACAddress -like $MACAddress } | Select-Object -First 1
        if ($cmDeviceMac) {
            throw "A device with MAC address $MACAddress already exists."
        }

        Write-Host "Creating computer '$ComputerName' with MAC address '$MacAddress'"

        $device = Import-CMComputerInformation -ComputerName $ComputerName `
            -MacAddress $MACAddress `
            -ErrorAction Stop

        Write-Host "Import complete. Waiting for ResourceID..."

        $resourceID = $null
        $maxAttempts = 60
        $currAttempt = 0
        $waitSecs = 20

        while ($currAttempt -lt $maxAttempts) {
            $device = $null
            $currAttempt++
            Write-Host "This is wait $currAttempt of $maxAttempts with $waitSecs seconds between attempts."
            Start-Sleep -Seconds $waitSecs
            $device = Get-CMDevice -Name $ComputerName -ErrorAction SilentlyContinue

            if ($device) {
                $resourceID = $device.ResourceID
                break
            }
        }

        if (-not $resourceID) {
            throw "Failed to retrieve device resource ID after '$maxAttempts' attempts. Aborting..."
        }

        Write-Host "Resource ID found: '$resourceID'"
        Write-Host "Adding '$($device.Name)' to collection '$CollectionName' using a direct membership rule..."

        Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName `
            -ResourceId $resourceID

        Write-Host "Successfully added $ComputerName to $CollectionName"
    } catch {
        throw $_
    }
}

#endregion

#region Add-SCCMDeviceToCollection.ps1
function Add-SCCMDeviceToCollection {
    [CmdletBinding()]
    param (
        # ComputerName - the name of the computer you'd like to add
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        # CollectionName - the name of the collection to add to
        [Parameter(Mandatory)]
        [string]$CollectionName
    )

    begin {
        $ogLoc = Get-Location
        Set-Location "A00:"
    }

    process {
        foreach ($device in $ComputerName) {
            try {
                $deviceResourceId = (Get-CMDevice -Fast -Name $device -ErrorAction "Stop").ResourceId
            } catch {
                Set-Location $ogLoc
                throw "Encountered error: $_"
            }
    
            if ($null -eq $deviceResourceId) {
                Set-Location $ogLoc
                throw "'$device' could not be found."
            }
    
            try {
                Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $deviceResourceId -ErrorAction "Stop"
            } catch {
                Set-Location $ogLoc
                throw "Encountered error when adding '$device' to '$CollectionName': '$CollectionName' could not be found. $_"
            }
        }
    }

    end {
        Set-Location $ogLoc
    }
}

#endregion

#region Copy-InvokeScript.ps1
function Copy-InvokeScript {
    [CmdletBinding()]
    param (
        # SourcePath
        [Parameter(Mandatory)]
        [string]
        $SourcePath,
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    $ogLoc = Get-Location

    Set-Location "C:\"

    try {
        $remotePath = $SourcePath.Replace("C:\", "\\$ComputerName\c`$\")
        
        $destinationPaths = @(
            $remotePath
        )

        foreach ($destinationPath in $destinationPaths) {
            if (Test-Path $destinationPath) {
                Copy-Item -Path $SourcePath -Destination $destinationPath -Force
                Write-Host "Copied invoke-appdeploytookit.ps1 to $destinationPath" -ForegroundColor Green
            } else {
                Write-Host "Could not find path: $destinationPath" -ForegroundColor Red
            }
        }
    } catch {
        throw $_
    }

    Set-Location $ogLoc
}

#endregion

#region Get-SCCMAppInfo.ps1
function Get-SCCMAppInfo {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory=$true)]
        [string[]]$ApplicationName,

        # CsvOutPath
        [Parameter(Mandatory = $false)]
        [string]$CsvOutPath = "C:\sources\csv\$(Get-Date -Format 'yyyy-MM-dd-HHmmss')-appinfo.csv"
    )

    begin {
        # change drive logic
        $ogLoc = Get-Location
        Set-Location "A00:"
    }

    process {
        foreach ($appName in $ApplicationName) {
            # get app
            try {
                $app = Get-CMApplication -Name $appName
            } catch {
                throw "Encountered error when retrieving info about '$app': $_"
            }

            if ($null -eq $app) {
                throw "Could not find application named '$appName': $_"
            } elseif ($app.Count -gt 1) {
                throw "Found more than one app when searching for '$appName'. Be more specific."
            }

            # pull out info from sdmpackagexml into result object
            [xml]$appxml = $app.SDMPackageXml
            $appxmlDisplayInfo = $appxml.AppMgmtDigest.Application.DisplayInfo.Info
            $appxmlInstaller = $appxml.AppMgmtDigest.DeploymentType.Installer

            # this is an array containing install and uninstall if they are separate
            # if uninstall is present then separate them, if not then only return contentlocation
            $contentLocation = $appxmlInstaller.Contents.Content
            if ($contentLocation.Count -gt 1) {
                $installContentLocation = $contentLocation | 
                    Where-Object { $_.Location -like "*\install*" } |
                    Select-Object -ExpandProperty "Location"
                $uninstallContentLocation = $contentLocation | 
                    Where-Object { $_.Location -like "*\uninstall*" } |
                    Select-Object -ExpandProperty "Location"
            } else {
                $installContentLocation = $contentLocation.Location
                $uninstallContentLocation = $null
            }

            # handle cases where there are multiple registry key detection methods
            $appxmlRegistry = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Settings.SimpleSetting.RegistryDiscoverySource
            if ($appxmlRegistry.Count -gt 1) {
                $registryHive0 = $appxmlRegistry[0].Hive
                $registryHive1 = $appxmlRegistry[1].Hive
                $registryKey0 = $appxmlRegistry[0].Key
                $registryKey1 = $appxmlRegistry[1].Key
                $registryValueName0 = $appxmlRegistry[0].ValueName
                $registryValueName1 = $appxmlRegistry[1].ValueName
            } else {
                $registryHive0 = $appxmlRegistry.Hive
                $registryKey0 = $appxmlRegistry.Key
                $registryValueName0 = $appxmlRegistry.ValueName
                $registryHive1 = $null
                $registryKey1 = $null
                $registryValueName1 = $null
            }

            $appxmlRegistryVersionValue = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Rule.Expression.Operands.Expression.Operands.ConstantValue |
                Where-Object { $_.DataType -like "String" } |
                Select-Object -ExpandProperty "Value"
            if ($appxmlRegistryVersionValue.Count -gt 1) {
                $registryVersionValue0 = $appxmlRegistryVersionValue[0]
                $registryVersionValue1 = $appxmlRegistryVersionValue[1]
            } else {
                $registryVersionValue0 = $appxmlRegistryVersionValue
                $registryVersionValue1 = $null
            }

            # handle cases where msi detection info isn't in the standard location
            $msiProductCode = $appxmlInstaller.CustomData.ProductCode
            if ($null -eq $msiProductCode) {
                $msiProductCode = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Settings.MSI.ProductCode
            }

            $msiProductVersion = $appxmlInstaller.CustomData.ProductVersion
            if ($null -eq $msiProductVersion) {
                $msiProductVersion = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Rule.Expression.Operands.ConstantValue.Value
            }

            # handle cases where there are multiple msiproductcodes
            if ($msiProductCode.Count -gt 1) {
                $msiProductCode0 = $msiProductCode[0]
                $msiProductCode1 = $msiProductCode[1]
            } else {
                $msiProductCode0 = $msiProductCode
                $msiProductCode1 = $null
            }

            $appInfo = [pscustomobject]@{
                DisplayName                 = $appxmlDisplayInfo.Title
                Description                 = $appxmlDisplayInfo.Description
                Publisher                   = $appxmlDisplayInfo.Publisher
                AppVersion                  = $appxmlDisplayInfo.Version
                InstallContentLocation      = $installContentLocation
                UninstallContentLocation    = $uninstallContentLocation
                InstallCommandLine          = $appxmlInstaller.CustomData.InstallCommandLine
                UninstallCommandLine        = $appxmlInstaller.CustomData.UninstallCommandLine
                ExecutionContext            = $appxmlInstaller.InstallAction.Args.Arg |
                    Where-Object { $_.name -like "ExecutionContext" } |
                    Select-Object -ExpandProperty '#text'
                ExecuteTime                 = $appxmlInstaller.InstallAction.Args.Arg |
                    Where-Object { $_.name -like "ExecuteTime" } |
                    Select-Object -ExpandProperty '#text'
                MaxExecuteTime              = $appxmlInstaller.InstallAction.Args.Arg |
                    Where-Object { $_.name -like "MaxExecuteTime" } |
                    Select-Object -ExpandProperty '#text'
                RegistryHive0               = $registryHive0
                RegistryKey0                = $registryKey0
                RegistryValueName0          = $registryValueName0
                RegistryVersionValue0       = $registryVersionValue0
                RegistryHive1               = $registryHive1
                RegistryKey1                = $registryKey1
                RegistryValueName1          = $registryValueName1
                RegistryVersionValue1       = $registryVersionValue1
                InstalledFolder             = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Settings.File.Path
                InstalledExe                = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Settings.File.Filter
                MSIProductCode0             = $msiProductCode0
                MSIProductCode1             = $msiProductCode1
                MSIProductVersion           = $msiProductVersion
            }

            $appInfo | Export-Csv -Path $CsvOutPath -NoTypeInformation -Append
            $appInfo
        }
    }

    end {
        Set-Location $ogLoc
    }
}

#endregion

#region Get-SCCMCollectionMembers.ps1
function Get-SCCMCollectionMembers {
    [CmdletBinding()]
    param (
        # CollectionName
        [Parameter(Mandatory)]
        [string]
        $CollectionName
    )

    $ogLoc = Get-Location

    Set-Location 'A00:'

    try {
        $collName = (Get-CMCollection -Name $CollectionName).Name
        if ($collectionName.Count -gt 1) {
            Set-Location $ogLoc
            throw "Found these collections when searching for '$CollectionName': $collName`n`n"
        }
        Get-CMCollectionMember -CollectionName $CollectionName | Select-Object Name,CurrentLogonUser
    } catch {
        throw $_
    }

    Set-Location $ogLoc
}

#endregion

#region Get-SCCMContentLocation.ps1
function Get-SCCMContentLocation {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory)]
        [string]
        $ApplicationName
    )

    $ogLoc = Get-Location
    Set-Location 'A00:'

    try {
        $app = Get-CMApplication -Name "$ApplicationName" -Fast
        if ($app.Count -lt 1) {
            throw "Application '$ApplicationName' not found."
        } elseif ($app.Count -gt 1) {
            throw "Found more than one application when searching for '$ApplicationName'. Be more specific."
        }
    } catch {
        Set-Location $ogLoc
        throw $_
    }

    $appDts = $app | Get-CMDeploymentType

    $nameAndFolder = $appDts |
    Select-Object LocalizedDisplayName, @{
        name = 'ContentLocation'
        expr = {
            $location = ($_.SDMPackageXML | Select-String '<Location>(.*)</Location>').Matches.Groups[1].Value
            $location = $location.Substring(0, $location.Length - 1)
            $location
        }
    }

    Set-Location $env:PROGRAMFILES

    $nameAndFolder | Select-Object *, @{
        name = 'Size'
        expr = {
            "$((Get-ChildItem -Path $_.ContentLocation -File -Recurse | Measure-Object -Property Length -Sum).Sum) bytes"
        }
    }, @{
        name = 'LastWriteTime'
        expr = {
            (Get-Item -Path $_.ContentLocation).LastWriteTime.ToString('hh:mm:ss tt dd-MMM-yyyy')
        }
    } |
    Sort-Object { (Get-Item $_.ContentLocation).LastWriteTime }

    Set-Location $ogLoc
}

#endregion

#region Get-SCCMDeploymentCollections.ps1
function Get-SCCMDeploymentCollections {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory)]
        [string]
        $ApplicationName
    )

    try {
        $startLoc = Get-Location
        Set-Location A00:

        Get-CMApplicationDeployment -ApplicationName $ApplicationName |
        Select-Object ApplicationName, CollectionName, LastModificationTime, LastModifiedBy

        Set-Location $startLoc
    } catch {
        throw $_
    }
}

#endregion

#region Install-SCCMClient.ps1
function Install-SCCMClient {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    if (-not (Test-Connection $ComputerName -Quiet -Count 2)) {
        throw "Computer is not online or could not find $ComputerName."
    }

    do {
        Write-Host "This will remove the SCCM client from $ComputerName!" -ForegroundColor Red
        $userInput = Read-Host "Type 'y' and press Enter to continue, or 'n' to exit"
        $userInput = $userInput.Trim()

        if ($userInput -eq 'y') {
            # exit the loop and continue the script
            Write-Host "Proceeding..." -ForegroundColor Green
            break
        } elseif ($userInput -eq 'n') {
            # User chose to exit
            Write-Host "Script execution cancelled." -ForegroundColor Red
            return
        } else {
            # Invalid input
            Write-Host "Invalid input. Please type 'y' or 'n'." -ForegroundColor Red
        }
    } while ($true)

    # start
    Write-Log ""
    Write-Log "=============="
    Write-Log $ComputerName
    Write-Log "=============="

    # needs to be in C:\ provider for unc paths to work
    $startLoc = Get-Location
    Set-Location "C:\"

    $waitSecs = 5

    $uninstallCommand = "-s \\$ComputerName C:\windows\ccmsetup\ccmsetup.exe /uninstall"
    Write-Log "Running: psexec $uninstallCommand"
    Start-Process -FilePath "psexec" -ArgumentList $uninstallCommand -Wait
    Write-Log "SCCM client has been uninstalled!"
    Start-Sleep -Seconds $waitSecs

    Write-Log "Copying ccmsetup files to remote machine..."
    try {
        $ccmSetupHostPath = "C:\sources\staging\ccmsetup"
        $ccmSetupDestinationPath = "\\$ComputerName\c$\Windows"
        Copy-Item -Path $ccmSetupHostPath -Destination $ccmSetupDestinationPath -Recurse -Force -ErrorAction Stop
        Write-Log "ccmsetup files have been copied to C:\Windows\ccmsetup on remote machine!"
    } catch {
        throw $_
    }

    $installCommand = "-s \\$ComputerName C:\windows\ccmsetup\ccmsetup.exe /mp:BNESCCM01.BMD.COM.AU SMSSITECODE=A00 SMSMP=BNESCCM01.BMD.COM.AU FSP=BNESCCM01.BMD.COM.AU /MANAGEDINSTALLER"
    Write-Log "Starting SCCM client install..."
    Start-Process -FilePath "psexec" -ArgumentList $installCommand -Wait
    Write-Log "SCCM client install has been started! Inspect C:\Windows\ccmsetup\logs\ccmsetup.log"
    Start-Sleep -Seconds $waitSecs

    Set-Location $startLoc
}

#endregion

#region Move-SCCMAppToBin.ps1
function Move-SCCMAppToBin {
    param (
        # Name - name of application in sccm
        [Parameter(Mandatory)]
        [string]$Name
    )

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    $app = Get-CMApplication -Name $Name -Fast

    foreach ($application in $app) {
        try {
            $application | Move-CMObject -FolderPath ".\Application\``BIN"
        } catch {
            throw "Encountered error when moving application '$($application.LocalizedDisplayName)' to folder '.\Application\``BIN'. $_"
        }
    }

    Set-Location $ogLoc
}

#endregion

#region New-SCCMAppInstalledCollection.ps1
function New-SCCMAppInstalledCollection {
    [CmdletBinding()]
    param (
        # AppString - the string the query will use
        # make sure you include the % wildcard
        # % at the start is slow, % at the end is fast
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppString,
        # CollectionName - the name of the collection to be created
        # must be in the format '<application> Installed'
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CollectionName
    )

    # schedule collection update to happen between 1am and 2am every 7 days
    try {
        $schedule = New-CMSchedule -Start (Get-Date -Hour 1) `
            -RecurInterval Days `
            -RecurCount 7
        
        Write-Host "Creating collection: '$CollectionName'..."
        $null = New-CMDeviceCollection -Name $CollectionName `
            -LimitingCollectionName "All Windows 10 and higher" `
            -RefreshSchedule $schedule `
            -RefreshType Periodic `
            -Comment "All devices with $CollectionName" `
            -ErrorAction Stop
        Write-Host "Success!" -ForegroundColor Green

        $sb = New-Object -TypeName System.Text.StringBuilder
        $null = $sb.Append("select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.Name ")
        $null = $sb.Append("from SMS_R_System inner join SMS_G_System_INSTALLED_SOFTWARE ")
        $null = $sb.Append("on SMS_G_System_INSTALLED_SOFTWARE.ResourceId = SMS_R_System.ResourceId ")
        # {0} these three chars get replaced by whatever's in $AppString
        $null = $sb.AppendFormat('where SMS_G_System_INSTALLED_SOFTWARE.ARPDisplayName like "{0}"', $AppString)
        $query = $sb.ToString()

        Write-Host "Adding wql query to collection..."
        Add-CMDeviceCollectionQueryMembershipRule -CollectionName $CollectionName `
            -RuleName $CollectionName `
            -QueryExpression $query `
            -ErrorAction Stop
        Write-Host "Success!" -ForegroundColor Green

        Write-Host "Moving collection to Software Installed folder..."
        $coll = Get-CMCollection -Name $CollectionName
        $coll | Move-CMObject -FolderPath 'A00:\DeviceCollection\Software Installed'
        Write-Host "Success!" -ForegroundColor Green
        
        Write-Host "Add this change to the changes spreadsheet :^)" -ForegroundColor Green
    } catch {
        throw $_
    }
}

#endregion

#region Nuke-SCCMApp.ps1
function Nuke-SCCMApp {
    param (
        # Name - name of app to search for
        [Parameter(Mandatory)]
        [string]
        $Name
    )

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    $apps = Get-CMApplication -Name $Name -Fast

    if (-not $apps) {
        Write-Warning "Application '$Name' was not found."
        return
    }

    # warning message
    $title    = "Warning!"
    $message  = "You are about to NUKE the following applications: " + 
        "`n`n$($apps.LocalizedDisplayName -join "`n")`n`nAre you sure you wish to continue?"
    $options  = "&Yes", "&No" # The ampersand defines the hotkey (Y and N)
    $default  = 1 # Sets 'No' as the default index

    $selection = $host.ui.PromptForChoice($title, $message, $options, $default)

    if ($selection -eq 0) {
        Write-Host "You chose Yes. Starting process..."
    } else {
        Write-Host "Operation aborted by user."
        return
    }

    foreach ($app in $apps) {
        Remove-SCCMDeployments -ApplicationName $app.LocalizedDisplayName
        Remove-SCCMAppContent -Name $app.LocalizedDisplayName
        Remove-SCCMSupersedence -ApplicationName $app.LocalizedDisplayName
        Move-SCCMAppToBin -Name $app.localizedDisplayName
    }

    Set-Location $ogLoc
}

#endregion

#region Open-CMLog.ps1
function Open-CMLog {
    param (
        # ComputerName
        [Parameter()]
        [string]
        $ComputerName,
        # Path
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    # edit string to use UNC
    $uncPath = $Path.replace(":", "$")

    # process path
    $process = "C:\Program Files\CMTrace\CMTrace.exe"

    # log file to open
    Start-Process -FilePath $process -ArgumentList "\\$ComputerName\$uncPath"
}

#endregion

#region Publish-SCCMApplication.ps1
<#
.SYNOPSIS
    This script deploys an existing SCCM application deployment type to a target collection.

.DESCRIPTION
    The script requires the Configuration Manager PowerShell module to be loaded. It finds the specified application,
    its deployment type, and the target collection, then creates a new application deployment.

.PARAMETER ApplicationName
    The name of the application to deploy. This must match the name of an existing application in SCCM.
    If the application has more than one deployment type this cmdlet will fail.

.PARAMETER CollectionName
    The name of the target collection to which the application will be deployed. This can be a user or device collection.

.NOTES
    - This script requires the Configuration Manager console and module to be installed on the machine where it is run.
    - Run this script from a PowerShell session with administrative privileges.
    - Ensure you are connected to the CM site by running Import-MEMModule

.EXAMPLE
    Publish-SCCMApplication -ApplicationName "7-Zip 23.01 (x64)" -DeploymentTypeName "7-Zip 23.01 (x64) - Install" -CollectionName "AaronLocker Testing"
#>
function Publish-SCCMApplication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ApplicationName,

        [Parameter(Mandatory = $false)]
        [string[]]$CollectionName,

        [Parameter(Mandatory = $false)]
        [bool]$ApprovalRequired = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Available", "Required")]
        [string]$DeployPurpose = 'Available',

        [Parameter(Mandatory = $false)]
        [string]$SupersededApplicationName,

        [Parameter(Mandatory = $false)]
        [bool]$Uninstall = $false,

        [Parameter(Mandatory = $false)]
        [switch]$AaronLockerTesting,

        [Parameter(Mandatory = $false)]
        [switch]$HasMail,

        [Parameter(Mandatory = $false)]
        [switch]$ApplicationsForWorkstations,

        [Parameter(Mandatory = $false)]
        [string[]]$RemoveDeployments,

        [Parameter(Mandatory = $false)]
        [string]$RemoveOldVersions,

        [Parameter(Mandatory = $false)]
        [switch]$KeepSupersededDeployments,

        [Parameter(Mandatory = $false)]
        [string]$RemoveAppContent
    )

    $ogLoc = Get-Location
    Set-Location 'A00:'

    # find the application object
    Write-Verbose "Searching for application: '$ApplicationName'..."
    try {
        $app = Get-CMApplication -Name $ApplicationName -Fast
        if (-not $app) {
            throw "Application '$ApplicationName' not found."
        } elseif ($app.Count -gt 1) {
            throw "Found more than one application when searching for '$ApplicationName'. Be more specific."
        }
    } catch {
        throw $_
    }

    # stop if app has more than one or less than one deployment type(s)
    if ($app.NumberOfDeploymentTypes -gt 1) {
        throw "Application '$ApplicationName' has more than one deployment type. Manual deployment required."
    } elseif ($app.NumberOfDeploymentTypes -lt 1) {
        throw "Application '$ApplicationName' has no deployment types."
    }

    # set supersedence if superseded application has been provided
    if ($SupersededApplicationName) {
        try {
            $dt = Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName
            $supersededApp = Get-CMApplication -Name $SupersededApplicationName -Fast
            if (-not $supersededApp) {
                throw "Application '$SupersededApplicationName' not found."
            } elseif ($supersededApp.Count -gt 1) {
                throw "Found more than one application when searching for '$SupersededApplicationName'. Be more specific."
            }
            if ($supersededApp.NumberOfDeploymentTypes -gt 1) {
                throw "Superseded application '$SupersededApplicationName' has more than one deployment type. Set supersedence manually."
            } elseif ($supersededApp.NumberOfDeploymentTypes -lt 1) {
                throw "Superseded application '$SupersededApplicationName' has no deployment types."
            }
            $supersededAppDt = Get-CMDeploymentType -ApplicationName $supersededApp.LocalizedDisplayName
            Write-Verbose "Setting supersedence..."
            Set-CMApplicationSupersedence -InputObject $app `
                -SupersededApplication $supersededApp `
                -CurrentDeploymentType $dt `
                -OldDeploymentType $supersededAppDt `
                -IsUninstall $Uninstall
            Write-Verbose "Supersedence set. Confirming..."
        } catch {
            throw $_
        }
    }

    $deadlineDateTime = (Get-Date -Hour 22 -Minute 00 -Second 00)
    $availableDateTime = $deadlineDateTime.AddDays(-1)

    Write-Verbose "Creating deployment(s) for '$ApplicationName'..."

    # find the target collection object
    if ($CollectionName) {
        foreach ($collectionItem in $CollectionName) {
            Write-Verbose "Searching for collection: '$collectionItem'..."
            try {
                $coll = Get-CMCollection -Name $collectionItem
                if (-not $coll) {
                    Write-Verbose "Collection: '$collectionItem' not found. Skipping..." -ForegroundColor Red
                    continue
                }

                New-CMApplicationDeployment -InputObject $app `
                    -Collection $coll `
                    -DeployAction Install `
                    -DeployPurpose $DeployPurpose `
                    -TimeBaseOn LocalTime `
                    -ApprovalRequired $ApprovalRequired `
                    -AvailableDateTime $availableDateTime `
                    -DeadlineDateTime $deadlineDateTime `
                    -UpdateSupersedence $true

                Write-Verbose "Successfully created deployment for application '$ApplicationName' to collection '$collectionItem'."
            } catch {
                throw $_
            }
        }
    }

    if ($AaronLockerTesting) {
        try {
            New-CMApplicationDeployment -InputObject $app `
                -CollectionId 'A0000209' `
                -DeployAction Install `
                -DeployPurpose Available `
                -TimeBaseOn LocalTime `
                -AvailableDateTime $availableDateTime `
                -DeadlineDateTime $deadlineDateTime `
                -UpdateSupersedence $true
        } catch {
            throw $_
        }

        Write-Verbose "Successfully created deployment for application '$ApplicationName' to collection 'AaronLocker Testing'."
    }

    if ($HasMail) {
        try {
            New-CMApplicationDeployment -InputObject $app `
                -CollectionId 'A0000039' `
                -DeployAction Install `
                -DeployPurpose $DeployPurpose `
                -TimeBaseOn LocalTime `
                -ApprovalRequired $ApprovalRequired `
                -AvailableDateTime $availableDateTime `
                -DeadlineDateTime $deadlineDateTime `
                -UpdateSupersedence $true
        } catch {
            throw $_
        }

        Write-Verbose "Successfully created deployment for application '$ApplicationName' to collection 'HasMail'."
    }

    if ($ApplicationsForWorkstations) {
        try {
            New-CMApplicationDeployment -InputObject $app `
                -CollectionId 'A00001AF' `
                -DeployAction Install `
                -DeployPurpose $DeployPurpose `
                -TimeBaseOn LocalTime `
                -ApprovalRequired $true `
                -AvailableDateTime $availableDateTime `
                -DeadlineDateTime $deadlineDateTime `
                -UpdateSupersedence $true
        } catch {
            throw $_
        }

        Write-Verbose "Successfully created deployment for application '$ApplicationName' to collection 'Applications for Workstations'."
    }

    # remove deployments of superseded application + any others specified in the removedeployments param
    if ( $SupersededApplicationName -and (-not $KeepSupersededDeployments) ) {
        $RemoveDeployments += $SupersededApplicationName
    }

    if ($RemoveDeployments) {
        foreach ($appName in $RemoveDeployments) {
            Remove-SCCMDeployments -ApplicationName $appName
        }
    }

    if ($PSBoundParameters["RemoveOldVersions"]) {
        Remove-SCCMApplicationOldVersions -ApplicationName $RemoveOldVersions
    }

    if ($PSBoundParameters["RemoveAppContent"]) {
        Remove-SCCMAppContentExceptSelected -ApplicationName $RemoveAppContent
    }

    Set-Location $ogLoc
}

#endregion

#region Remove-SCCMAppContent.ps1
function Remove-SCCMAppContent {
    param (
        # Name - name of app to remove all distributed content for
        [Parameter(Mandatory)]
        [string]$Name
    )

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    try {
        $app = Get-CMApplication -Name $Name -Fast
        if (-not $app) {
            Write-Warning "Application '$Name' was not found."
            return
        }

        $appName = $app.LocalizedDisplayName
        $allDps = (Get-CMDistributionPoint).NetworkOSPath.Replace('\\', '')
        $allDpGroups = (Get-CMDistributionPointGroup).Name

        # Remove content from each distribution point group individually so that a
        # destination without the content does not abort removal from the others.
        foreach ($dpGroup in $allDpGroups) {
            try {
                Remove-CMContentDistribution -ApplicationName $appName -DistributionPointGroupName $dpGroup -Force -ErrorAction Stop
                Write-Verbose "Removed content for '$appName' from distribution point group '$dpGroup'."
            }
            catch {
                Write-Verbose "Skipping distribution point group '$dpGroup': $($_.Exception.Message)"
            }
        }

        # Remove content from each distribution point individually for the same reason.
        foreach ($dp in $allDps) {
            try {
                Remove-CMContentDistribution -ApplicationName $appName -DistributionPointName $dp -Force -ErrorAction Stop
                Write-Verbose "Removed content for '$appName' from distribution point '$dp'."
            }
            catch {
                Write-Verbose "Skipping distribution point '$dp': $($_.Exception.Message)"
            }
        }
    }
    finally {
        Set-Location $ogLoc
    }
}

#endregion

#region Remove-SCCMAppContentExceptSelected.ps1
<#
.SYNOPSIS
Removes SCCM application content from all Distribution Points for apps you do NOT select.

.DESCRIPTION
Searches for applications using a localized display name wildcard.
It opens an Out-GridView window where you select the apps you want to KEEP the content for.
For any matching applications you do NOT select, it will purge their content from all standalone
Distribution Points and Distribution Point Groups

.EXAMPLE
Remove-SCCMAppContentExceptSelected -ApplicationName "*Google Chrome*"

.NOTES
Author: Matt McPhee
Date: 2026-05-20
Changelog:
- 2026-05-20 Matt McPhee: Initial script creation
#>
function Remove-SCCMAppContentExceptSelected {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, HelpMessage="Enter the app name (supports wildcards), e.g. *Adobe*")]
        [string]$ApplicationName
    )

    $ogLoc = Get-Location
    Set-Location "A00:"

    # fetch matching applications
    Write-Verbose "Querying SCCM for applications matching '$ApplicationName'..."

    try {
        $allApps = Get-CMApplication -Name $ApplicationName -ErrorAction Stop
    } catch {
        Set-Location $ogLoc
        throw "Error fetching applications: $_"
    }

    if (-not $allApps) {
        Set-Location $ogLoc
        throw "No applications found matching '$ApplicationName'."
    }

    # get selections from gridview
    Write-Verbose "Found $($allApps.Count) application(s). Opening GridView for selection..."

    $appsToKeep = $allApps |
        Select-Object LocalizedDisplayName, SoftwareVersion, Manufacturer, DateCreated, CreatedBy, DateLastModified, LastModifiedBy, NumberOfDeployments, CI_ID |
        Sort-Object DateCreated |
        Out-GridView -Title "Select app content to KEEP (Unselected apps will have content DELETED from ALL DPs!)" -PassThru

    # handle no selection
    if (-not $appsToKeep) {
        $title = "Warning: No Apps Selected"
        $message = "You did not select any applications to keep. This means ALL matching apps will have their content removed. Are you sure you want to proceed?"
        $choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
            "&Yes, remove content for ALL",
            "&No, abort"
        )
        # 1 is the index of the default choice (No, abort)
        $decision = $Host.UI.PromptForChoice($title, $message, $choices, 1)

        if ($decision -eq 1) {
            Write-Verbose "Operation aborted by user. No content was removed."
            Set-Location $ogLoc
            return
        }
    }

    # filter out apps to remove
    if ($appsToKeep) {
        $keepIds = $appsToKeep.CI_ID
    } else {
        $keepIds = @()
    }
    $appsToRemove = $allApps | Where-Object { $_.CI_ID -notin $keepIds }

    if (-not $appsToRemove) {
        Write-Verbose "All applications were selected to be kept. No content will be removed."
        Set-Location $ogLoc
        return
    }

    # fetch all DPs and DP Groups
    Write-Verbose "Fetching all Distribution Points and Distribution Point Groups..."
    $allDps = (Get-CMDistributionPoint).NetworkOSPath.Replace('\\', '')
    if (-not $allDps) {
        Set-Location $ogLoc
        throw "No Distribution Points found in SCCM."
    }

    $allDpGroups = (Get-CMDistributionPointGroup).Name
    if (-not $allDpGroups) {
        Set-Location $ogLoc
        throw "No Distribution Point Groups found in SCCM."
    }

    # remove content if distributed
    foreach ($app in $appsToRemove) {
        $distStatus = Get-CMDistributionStatus -InputObject $app

        if ($distStatus.Targeted -eq 0) {
            Write-Verbose "Skipping '$($app.LocalizedDisplayName)' as it has no content distributed to any DPs."
            continue
        }

        $target = "Application: $($app.LocalizedDisplayName)"
        $action = "Remove content from all Distribution Points and DP Groups"

        if ($PSCmdlet.ShouldProcess($target, $action)) {
            Write-Verbose "Removing content from all DPs for: $($app.LocalizedDisplayName)"
            try {
                Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName -DistributionPointName $allDps -Force -ErrorAction SilentlyContinue
                Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName -DistributionPointGroupName $allDpGroups -Force -ErrorAction SilentlyContinue
            } catch {
                Set-Location $ogLoc
                throw "Failed to remove content for '$($app.LocalizedDisplayName)'. Error: $_"
            }
        }
    }

    Write-Output "Content removal process completed successfully!"

    Set-Location $ogLoc
}

#endregion

#region Remove-SCCMApplicationOldVersions.ps1
<#
.SYNOPSIS
Removes supersedence, deployments and distributed data from application(s).
.DESCRIPTION
From an input application name, lists all applications found with same name in Out-GridView
Selected applications have supersedence and or deployments and or distributed data removed
.PARAMETER ApplicationName
This will take input in the form of a application name.
This is required.
.PARAMETER Supersedence
Switch if enabled will remove all supersedence from the application.
This is optional.
.PARAMETER Deployments
Switch if enabled will remove all deployments from the application.
This is optional.
.PARAMETER Distribution
Switch if enabled will remove all distribution data for the application.
This is optional.
.INPUTS
Application name
.OUTPUTS
Configuration Manager changes and info to console/gridview.
.Notes
Version:        1.00
Author:         Victor Rodriguez
Creation Date:  08/09/2021
Changes:        Initial script development
                19-05-2022 Added IsSuperseding, IsDeployed Data to the Out-GridView
                28-11-2024 Matt McPhee cleaned up formatting and punctuation
.EXAMPLE
Remove all supersedence from selected application
PS> Remove-MEMAppDDS "12D Model" -Supersedence
.EXAMPLE
Remove All deployments from selected application
PS> Remove-MEMAppDDS "12D Model" -Deployments
.EXAMPLE
Remove All Distributed data for selected application
PS> Remove-MEMAppDDS "12D Model" -Distribution
.EXAMPLE
Remove all supersedence and all deployments and all distributed data for selected application
PS> Remove-MEMAppDDS "12D Model" -Supersedence -Deployments -Distribution
#>
function Remove-SCCMApplicationOldVersions {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $ApplicationName
    )

    function Remove-SCCMSupersedenceHelper {
        param (
            # ApplicationName
            [Parameter(Mandatory = $true)]
            [string]
            $ApplicationName
        )

        # find the application object
        Write-Verbose "Searching for application: '$ApplicationName'..."
        $app = Get-CMApplication -Name "$ApplicationName" -Fast
        if ($app.Count -lt 1) {
            throw "Application '$ApplicationName' not found."
        } elseif ($app.Count -gt 1) {
            throw "Found more than one application when searching for '$ApplicationName'. Be more specific."
        }

        # stop if app has more than one or less than one deployment type(s)
        if ($app.NumberOfDeploymentTypes -gt 1) {
            throw "Application '$ApplicationName' has more than one deployment type. Stopping..."
        } elseif ($app.NumberOfDeploymentTypes -lt 1) {
            throw "Application '$ApplicationName' has no deployment types."
        }

        # get current deploymenttype object of app using name of app
        $dt = Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName
        if ($dt.Count -lt 1) {
            throw "Could not find deployment type for application: $($app.LocalizedDisplayName)"
        }

        # get superseded deploymenttype object using current deploymenttype object
        $supersededDt = Get-CMDeploymentTypeSupersedence -InputObject $dt
        if ($supersededDt.Count -lt 1) {
            Write-Host "Could not find superseded deployment type for application: $($app.LocalizedDisplayName) - it has no supersedence."
            return
        }

        # get superseded application object using name of superseded deploymenttype object
        $supersededApp = Get-CMApplication -Name $supersededDt.LocalizedDisplayName -Fast
        if ($supersededApp.Count -lt 1) {
            throw "Could not find superseded application: $($supersededDt.LocalizedDisplayName)"
        }

        try {
            Set-CMApplicationSupersedence `
                -InputObject $app `
                -SupersededApplication $supersededApp `
                -CurrentDeploymentType $dt `
                -OldDeploymentType $supersededDt `
                -RemoveSupersedence `
                -Force `
                -ErrorAction "Stop"
        } catch {
            throw "Could not remove supersedence for $($app.LocalizedDisplayName). Error: $_"
        }

        Write-Host "Removed supersedence for $($app.LocalizedDisplayName)"
    }

    # store current location and change dir to CM drive
    try {
        $ogLoc = Get-Location
        Set-Location "A00:\"
    } catch {
        throw $_
    }
    
    # get application
    try {
        $applications = Get-CMApplication -Fast -ApplicationName $ApplicationName -ErrorAction "Stop"
    } catch {
        throw $_
    }

    if ($applications.Count -lt 1) {
        throw "Could not find any applications using search term: $ApplicationName"
    } elseif ($applications.Count -le 10) {
        $msg = "Could not find more than 10 applications using search term: $ApplicationName" + 
            "`nNo applications to delete."
        throw $msg
    }

    # sort app list by datecreated descending and skip the first 10
    # we want to get only the apps that are NOT one of the latest 10 versions of the app
    $apps = $applications | Sort-Object DateCreated -Descending | Select-Object * -Skip 10

    # next, we want to make sure the 'tenth' oldest version isn't superseding anything
    # because after we delete all versions EXCEPT for the latest 10, this 'tenth' oldest
    # version will become the oldest version
    $tenthOldestApp = $applications | Sort-Object DateCreated -Descending | Select-Object * -Skip 9 -First 1

    if ($tenthOldestApp.isSuperseding) {
        Write-Host "Found supersedence on tenth oldest app version: $($tenthOldestApp.LocalizedDisplayName). Removing..."
        Remove-SCCMSupersedenceHelper -ApplicationName $tenthOldestApp.LocalizedDisplayName
    }

    # get distribution points to remove content from them
    $dps = Get-CMDistributionPoint | Select-Object -ExpandProperty NetworkOSPath

    # warning message
    $title    = "Warning!"
    $message  = "You are about to delete the following applications: " + 
        "`n`n$($apps.LocalizedDisplayName -join "`n")`n`nAre you sure you wish to continue?"
    $options  = "&Yes", "&No" # The ampersand defines the hotkey (Y and N)
    $default  = 1 # Sets 'No' as the default index

    $selection = $host.ui.PromptForChoice($title, $message, $options, $default)

    if ($selection -eq 0) {
        Write-Host "You chose Yes. Starting process..."
    } else {
        Write-Host "Operation aborted by user."
        return
    }

    foreach ($app in $apps) {
        Write-Host "Working on: $($app.LocalizedDisplayName)"

        # remove supersedence if present
        if ($app.isSuperseding) {
            Write-Host "Found supersedence relationship for $($app.LocalizedDisplayName). Removing..."
            Remove-SCCMSupersedenceHelper $app.LocalizedDisplayName
        }

        # remove deployments
        if ($app.NumberOfDeployments -gt 0) {
            try {
                Write-Host "Found deployments for $($app.LocalizedDisplayName)"
                Remove-CMApplicationDeployment -InputObject $app -Force -ErrorAction "Stop"
            } catch {
                throw $_
            }
            Write-Host "Removed all deployments for app: $($app.LocalizedDisplayName)"
        }

        # remove content from DPs
        foreach ($dp in $dps) {
            try {
                Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName `
                    -DistributionPointName $dp `
                    -Force `
                    -ErrorAction "Stop"
                Write-Host "Content for $($app.LocalizedDisplayName) removed from distribution point: $dp"
            } catch {
                Write-Verbose "$($app.LocalizedDisplayName) not found on: $dp"
            }
        }

        # remove application from sccm
        try {
            Remove-CMApplication -Name $app.LocalizedDisplayName -Force -ErrorAction "Stop"
        } catch {
            throw $_
        }
    }

    Write-Host "Removed these apps from SCCM (only keeping 10 most recent):"
    foreach ($app in $apps) {
        Write-Host $app.LocalizedDisplayName
    }

    Set-Location $ogLoc
}

#endregion

#region Remove-SCCMDeployments.ps1
function Remove-SCCMDeployments {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory = $true)]
        [string[]]
        $ApplicationName
    )

    $ogLoc = Get-Location

    Set-Location 'A00:'

    try {
        foreach ($name in $ApplicationName) {
            $app = Get-CMApplication -Name "$name" -Fast
            if ($app.Count -lt 1) {
                throw "Application '$name' not found."
            } elseif ($app.Count -gt 1) {
                throw "Found more than one application when searching for '$name'. Be more specific."
            }

            $app | Remove-CMApplicationDeployment -Force
            Write-Verbose "Successfully removed all deployments for application '$name'."
        }
    } catch {
        Write-Warning "Could not remove deployments for application '$name' - no deployments found."
        Set-Location $ogLoc
    }

    Set-Location $ogLoc
}

#endregion

#region Remove-SCCMSupersedence.ps1
function Remove-SCCMSupersedence {
    [CmdletBinding(DefaultParameterSetName = 'ByApplicationName')]
    param (
        # ApplicationName
        [Parameter(Mandatory = $true, ParameterSetName = 'ByApplicationName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCreationDateRange')]
        [string]
        $ApplicationName,
        # CreationDateRangeStart
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCreationDateRange')]
        [datetime]
        $CreationDateRangeStart,
        # CreationDateRangeEnd
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCreationDateRange')]
        [datetime]
        $CreationDateRangeEnd
    )

    function Remove-SCCMSupersedenceHelper {
        param (
            # ApplicationName
            [Parameter(Mandatory = $true)]
            [string]
            $ApplicationName
        )
        
        # find the application object
        Write-Verbose "Searching for application: '$ApplicationName'..."
        $app = Get-CMApplication -Name "$ApplicationName" -Fast
        if ($app.Count -lt 1) {
            throw "Application '$ApplicationName' not found."
        } elseif ($app.Count -gt 1) {
            throw "Found more than one application when searching for '$ApplicationName'. Be more specific."
        }

        # stop if app has more than one or less than one deployment type(s)
        if ($app.NumberOfDeploymentTypes -gt 1) {
            throw "Application '$ApplicationName' has more than one deployment type. Stopping..."
        } elseif ($app.NumberOfDeploymentTypes -lt 1) {
            throw "Application '$ApplicationName' has no deployment types."
        }

        # get current deploymenttype object of app using name of app
        $dt = Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName
        if ($dt.Count -lt 1) {
            throw "Could not find deployment type for application: $($app.LocalizedDisplayName)"
        }

        # get superseded deploymenttype object using current deploymenttype object
        $supersededDt = Get-CMDeploymentTypeSupersedence -InputObject $dt
        if ($supersededDt.Count -lt 1) {
            Write-Host "Could not find superseded deployment type for application: $($app.LocalizedDisplayName) - it has no supersedence."
            return
        }

        # get superseded application object using name of superseded deploymenttype object
        $supersededApp = Get-CMApplication -Name $supersededDt.LocalizedDisplayName -Fast
        if ($supersededApp.Count -lt 1) {
            throw "Could not find superseded application: $($supersededDt.LocalizedDisplayName)"
        }
        try {
            Set-CMApplicationSupersedence `
                -InputObject $app `
                -SupersededApplication $supersededApp `
                -CurrentDeploymentType $dt `
                -OldDeploymentType $supersededDt `
                -RemoveSupersedence `
                -Force `
                -ErrorAction "Stop"
        } catch {
            Write-Warning "Could not remove supersedence for $($app.LocalizedDisplayName). Error: $_"
        }
        Write-Host "Removed supersedence for $($app.LocalizedDisplayName)"
    }

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    switch ($PSCmdlet.ParameterSetName) {
        'ByApplicationName' {
            try {
                Remove-SCCMSupersedenceHelper -ApplicationName $ApplicationName
            } catch {
                throw $_
            }
        }

        'ByCreationDateRange' {
            try {
                # get array of apps e.g. 'Zoom Workplace*' will return around 18 app objects
                $apps = Get-CMApplication -Name $ApplicationName -Fast
                if ($apps.Count -lt 1) {
                    throw "Could not find any application objects with application name: $ApplicationName"
                } elseif ($apps.Count -eq 1) {
                    $msg = "Found only one application object using application name: $ApplicationName - " +
                    "try running this cmdlet again without any CreationDateRange parameters."
                    throw $msg
                }

                # filter the array based on creationdaterange params
                $filteredDateApps = $apps | Where-Object { $_.DateCreated -gt $CreationDateRangeStart -and $_.DateCreated -lt $CreationDateRangeEnd }
                if ($filteredDateApps.Count -le 1) {
                    $msg = "Only found 1 or less application objects between those CreationDateRange parameters. " +
                    "Try widening the range."
                    throw $msg
                } 

                foreach ($app in $filteredDateApps) {
                    Remove-SCCMSupersedenceHelper -ApplicationName $app.LocalizedDisplayName
                }
            } catch {
                throw $_
            }
        }
    }

    Set-Location $ogLoc
}

#endregion

#region Reset-CCMSQLCELog.ps1
<#
.SYNOPSIS
    Fixes the issue where the CCMSQLCE.log constantly generates and prevents the
    CCM client on the machine from reporting back to configuration manager
.DESCRIPTION
    Stops the CCMExec process ->
    stops the CCMExec service ->
    deletes theccmstore.sdf file ->
    restarts the ccmexec service ->
    runs the machine policy retrieval action ->
    runs the user policy retrieval action ->
    runs the hardware inventory cycle action ->
    runs the application deployment evaluation cycle ->
    runs the software update scan cycle ->
    runs the software update eval cycle
.EXAMPLE
    Reset-CCMSQLCELog -ComputerName 5CD151MCTX
#>

function Reset-CCMSQLCELog {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName
    )

    # variables
    $sleepTime = 1

    # test if machine is online and psremoting is working by testing invoke-command
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {} -ErrorAction Ignore
    $machineOnlineTestFailed = (-not $?)
    if ($machineOnlineTestFailed) {
        throw "Machine is not online or PSRemoting is not working on the machine."
    } else {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-Process CCMExec* | Stop-Process -Force
            Start-Sleep 2
            Get-Service CCMExec* | Set-Service -Status Stopped
            Get-ChildItem -Path "C:\Windows\CCM\CcmStore.sdf" | Remove-Item -Force
            Start-Service CCMExec
            if ((Get-Service CCMExec).Status -notlike 'Running') {
                $errorMsg = "Attempt to restart CcmExec.exe failed. "
                $errorMsg += "Machine needs manual investigation."
                throw $errorMsg
            }
        }
    }

    Start-Sleep -Seconds $sleepTime
    # retrieve machine policy
    Invoke-WmiMethod -ComputerName $ComputerName `
        -Namespace root\ccm `
        -Class SMS_CLIENT `
        -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}" `
        -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # retrieve user policy
    Invoke-WmiMethod -ComputerName $ComputerName `
        -Namespace root\ccm `
        -Class SMS_CLIENT `
        -Name TriggerSchedule "{00000000-0000-0000-0000-000000000026}" `
        -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # hardware inventory
    Invoke-WmiMethod -ComputerName $ComputerName `
        -Namespace root\ccm `
        -Class SMS_CLIENT `
        -Name TriggerSchedule "{00000000-0000-0000-0000-000000000001}" `
        -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # application deployment evaluation
    Invoke-WmiMethod -ComputerName $ComputerName `
        -Namespace root\ccm `
        -Class SMS_CLIENT `
        -Name TriggerSchedule "{00000000-0000-0000-0000-000000000121}" `
        -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # software update scan cycle
    Invoke-WmiMethod -ComputerName $ComputerName `
        -Namespace root\ccm `
        -Class SMS_CLIENT `
        -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}" `
        -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # software update eval cycle
    Invoke-WmiMethod -ComputerName $ComputerName `
        -Namespace root\ccm `
        -Class SMS_CLIENT `
        -Name TriggerSchedule "{00000000-0000-0000-0000-000000000114}" `
        -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
}

#endregion

#region Convert-WDACXML.ps1
function Convert-WDACXML {
    param (
        # folder path (no backslash at the end)
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $XmlFilePath,
        # output folder path (no backslash at the end)
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $CipOutputPath
    )
    $xmlFiles = Get-ChildItem -Path $XmlFilePath -Filter '*.xml'
    foreach ($xmlFile in $xmlFiles) {
        $xmlContent = [xml](Get-Content $xmlFile)
        $policyID = $xmlContent.SiPolicy.PolicyID
        $binaryFilePath = $CipOutputPath + '\' + $policyID + '.cip'
        ConvertFrom-CIPolicy -XmlFilePath $($xmlFile.FullName) `
            -BinaryFilePath $binaryFilePath
        $null = New-Item -ItemType File `
            -Path $CipOutputPath `
            -Name ($PolicyID + '-' + $xmlFile.BaseName + '.info') `
            -Force
    }
}

#endregion

#region Get-ActiveCIPolicies.ps1
function Get-ActiveCIPolicies {
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = $env:COMPUTERNAME,
        # only show policies being enforced
        [Parameter(Mandatory=$false)]
        [switch]
        $EnforcedOnly
    )
    if ($EnforcedOnly) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (citool --list-policies -json | ConvertFrom-Json).Policies |
            Where-Object {$_.IsEnforced -eq "True"} |
            Select-Object PolicyID,BasePolicyID,FriendlyName, `
                IsSystemPolicy,IsOnDisk,IsEnforced,IsAuthorized
        }
    } else {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (citool --list-policies -json | ConvertFrom-Json).Policies |
            Select-Object PolicyID,BasePolicyID,FriendlyName, `
                IsSystemPolicy,IsOnDisk,IsEnforced,IsAuthorized
        }
    }
}

#endregion

#region New-SupplementalAppControlPolicy.ps1
function New-SupplementalAppControlPolicy {
    param (
        # FriendlyName
        [Parameter(Mandatory=$true)]
        [string]
        $FriendlyName,
        # ScanPath
        [Parameter(Mandatory=$true)]
        [string]
        $ScanPath,
        # Desired output location of the policy xml file
        [Parameter(Mandatory=$true)]
        [string]
        $OutputXmlPath,
        # BasePolicyGUID - must be surrounded by curly braces
        [Parameter(Mandatory=$false)]
        [string]
        $BasePolicyGUID = "{488E7D72-DA1E-4219-BB58-22EEBCBB2CFE}"
    )

    # create the policy
    $arguments = @{
        ScanPath = $ScanPath
        OutputXmlPath = $OutputXmlPath
        Level = "Publisher"
        Fallback = "Hash"
    }

    New-CIPolicy @arguments

    # get xml and put it in xml type variable
    [Xml]$xml = Get-Content $OutputXmlPath
    # remove all rule options
    $xml.SiPolicy.Rules.RemoveAll()
    # change policytype to supplemental policy
    $xml.SiPolicy.PolicyType = "Supplemental Policy"
    # change base policy ID
    $xml.SiPolicy.BasePolicyID = $BasePolicyGUID
    # save the xml file
    $xml.Save($OutputXmlPath)
    # add unsigned system integrity policy rule option
    Set-RuleOption -FilePath $OutputXmlPath -Option 6

    # add info to the policy
    $todaysDate = Get-Date -Format "dd-MM-yyyy"

    $arguments = @{
        OutputXmlPath = $OutputXmlPath
        Provider = "PolicyInfo"
        ValueName = "Name"
        Value = "$FriendlyName - $todaysDate"
        Key = "Information"
        ValueType = "String"
    }

    Set-CIPolicySetting @arguments

    # convert the xml to cip
    ConvertFrom-CIPolicy -XmlFilePath $OutputXmlPath -BinaryFilePath "$OutputXmlPath.cip"
}

#endregion

#region Set-BasePolicyID.ps1
function Set-BasePolicyID {
    param (
        # folder path
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_})]
        [string]
        $FolderPath,
        # base policy ID
        [Parameter(Mandatory=$true)]
        [string]
        $BasePolicyID
    )
    $xmlFiles = Get-ChildItem -Path $FolderPath -Filter '*.xml'
    foreach ($xmlFile in $xmlFiles) {
        $xmlContent = [xml](Get-Content $xmlFile)
        Write-Host "Current BasePolicyID for $($xmlFile): $($xmlContent.SiPolicy.BasePolicyID)"
        $xmlContent.SiPolicy.BasePolicyID = $BasePolicyID
        Write-Host "BasePolicyID has been changed to $($xmlContent.SiPolicy.BasePolicyID)"
        $xmlContent.Save($xmlFile)
    }
}

#endregion

