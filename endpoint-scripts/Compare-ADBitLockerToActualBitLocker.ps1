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