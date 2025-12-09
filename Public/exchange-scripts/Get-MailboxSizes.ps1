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