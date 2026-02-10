# ==============================
#  Long Running & Blocking Session Teams Alert
# ==============================

# Teams Webhook URL (Replace XXXX with your actual webhook)
$TeamsWebhookUrl = "https://craftsiliconblr.webhook.office.com/webhookb2/0c6214a5-3631-46ad-8f25-99a9e59a01a9@c6970a01-7db1-4e10-8d80-9f10ab0ccfbc/IncomingWebhook/4d6511da951c406984c716aa985f65a0/177c4eab-cd66-4b9f-896b-c4caa36e412a/V25Z1Cgwp3KoHvTPjENIzN9yXpIoV58nje4z2A0CniFUA1"


# Select the latest Long Running Session report CSV file
$ReportFile = Get-ChildItem -Path "D:\DATAEXT\OUTPUT\Daily_LRSessionBlocking_Alert.csv" |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Check if the file exists
if ($ReportFile) {
    Write-Host "Processing the report file: $($ReportFile.FullName)"
    
    # Load and filter CSV content, removing empty or invalid rows
    $ReportContent = Import-Csv -Path $ReportFile.FullName | Where-Object {
        $_.session_id -ne "" -and $_.session_id -notmatch '^---+$'
    }

    if ($ReportContent.Count -ne 0) {
        # Build Markdown-style message for Teams
        $TeamsMessage = "**🚨 SQL Long Running & Blocking Session Alert**`n`n"
        $TeamsMessage += "| Session ID | Status | Blocked By | Elapsed Time | Login Name | Stored Procedure | Host Name | Database Name |`n"
        $TeamsMessage += "|-------------|---------|-------------|---------------|--------------|------------------|--------------|----------------|`n"

        foreach ($row in $ReportContent) {
            $TeamsMessage += "| $($row.session_id) | $($row.status) | $($row.blocked_by) | $($row.elapsed_time) | $($row.login_name) | $($row.stored_proc) | $($row.host_name) | $($row.database_name) |`n"
        }

        # Prepare JSON payload for Teams
        $BodyJson = ConvertTo-Json -Depth 4 -Compress -InputObject @{
            "@type"    = "MessageCard"
            "@context" = "http://schema.org/extensions"
            summary   = "SQL Long Running & Blocking Session Notification"
            themeColor = "FF0000"  # Red for critical alert
            title     = "❗ SQL Long Running & Blocking Session Alert"
            text      = $TeamsMessage
        }

        # Send alert to Teams
        Invoke-RestMethod -Uri $TeamsWebhookUrl -Method Post -ContentType 'application/json' -Body $BodyJson

        Write-Host "Teams Long Running & Blocking Session alert sent successfully!"
    } else {
        Write-Host "No valid session blocking or long running data found. Alert not sent."
    }
} else {
    Write-Host "No long running alert CSV report file found. Alert not sent."
}
