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
