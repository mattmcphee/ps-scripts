function Get-SCCMDeviceQueries {
    function Write-Log {
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
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]
            $Message,
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]
            $Level = "Info",
            # Path
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path
        )

        process {
            # convert level to type codes so cmtrace can read it
            switch ($Level) {
                "Info" { [int]$Type = 1 }
                "Warning" { [int]$Type = 2 }
                "Error" { [int]$Type = 3 }
            }

            # create log entry
            $logLine = "<![LOG[$Message]LOG]!>" +
            "<" +
            "time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +
            "date=`"$(Get-Date -Format "M-d-yyyy")`" " +
            "type=`"$Type`" " +
            ">"

            # append line to log file
            $logLine | Out-File -FilePath $Path -Append -Force -Encoding utf8
        }
    }

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

