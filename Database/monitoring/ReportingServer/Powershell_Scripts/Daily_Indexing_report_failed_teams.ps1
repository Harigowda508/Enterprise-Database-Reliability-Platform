# Teams Webhook URL (Replace this with your actual webhook URL)
$TeamsWebhookUrl = "https://craftsiliconblr.webhook.office.com/webhookb2/0c6214a5-3631-46ad-8f25-99a9e59a01a9@c6970a01-7db1-4e10-8d80-9f10ab0ccfbc/IncomingWebhook/4d6511da951c406984c716aa985f65a0/177c4eab-cd66-4b9f-896b-c4caa36e412a/V25Z1Cgwp3KoHvTPjENIzN9yXpIoV58nje4z2A0CniFUA1"  # <-- Replace with your actual one

# Select the latest CSV file
$ReportFile = Get-ChildItem -Path "D:\DATAEXT\OUTPUT\Daily_Indexing_Report_Failed.csv" |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Check if the file exists
if ($ReportFile) {
    Write-Host "Processing the report file: $($ReportFile.FullName)"
    
    # Load and filter CSV content
    $ReportContent = Import-Csv -Path $ReportFile.FullName | Where-Object {
        $_.job_name -ne "" -and $_.job_name -notmatch '^---+$'
    }

    if ($ReportContent.Count -ne 0) {
        # Build Markdown-style table message
        $TeamsMessage = "**SQL Indexing Failure Alert**`n`n"
        $TeamsMessage += "| Job Name | Job Enabled | Frequency | Status | Failed Date | Failed Time | Error Message |`n"
        $TeamsMessage += "|----------|-------------|-----------|--------|-------------|--------------|----------------|`n"

        foreach ($row in $ReportContent) {
            $TeamsMessage += "| $($row.job_name) | $($row.job_enabled) | $($row.frequency) | $($row.job_status) | $($row.failed_date) | $($row.failed_time) | $($row.error_message) |`n"
        }

        # Prepare JSON payload for Teams
        $BodyJson = ConvertTo-Json -Depth 4 -Compress -InputObject @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            summary = "SQL Indexing Job Failure Notification"
            themeColor = "FF0000"
            title = " SQL Indexing Failure Notification"
            text = $TeamsMessage
        }

        # Send the alert to Teams
        Invoke-RestMethod -Uri $TeamsWebhookUrl -Method Post -ContentType 'application/json' -Body $BodyJson

        Write-Host "Teams alert sent successfully!"
    } else {
        Write-Host "No valid data in the report file. Alert not sent."
    }
} else {
    Write-Host "No indexing failed data found. Alert not sent."
}
