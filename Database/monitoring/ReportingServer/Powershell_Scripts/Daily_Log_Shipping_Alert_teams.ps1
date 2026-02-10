# Teams Webhook URL (Use your actual webhook URL)
$TeamsWebhookUrl = "https://craftsiliconblr.webhook.office.com/webhookb2/0c6214a5-3631-46ad-8f25-99a9e59a01a9@c6970a01-7db1-4e10-8d80-9f10ab0ccfbc/IncomingWebhook/4d6511da951c406984c716aa985f65a0/177c4eab-cd66-4b9f-896b-c4caa36e412a/V25Z1Cgwp3KoHvTPjENIzN9yXpIoV58nje4z2A0CniFUA1"

# Select the latest Log Shipping report CSV file
$ReportFile = Get-ChildItem -Path "D:\DATAEXT\OUTPUT\Logshipping_Alert_Report.csv" |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Check if the file exists
if ($ReportFile) {
    Write-Host "Processing the report file: $($ReportFile.FullName)"
    
    # Load and filter CSV content, removing empty or invalid rows
    $ReportContent = Import-Csv -Path $ReportFile.FullName | Where-Object {
        $_.DatabaseName -ne "" -and $_.DatabaseName -notmatch '^---+$'
    }

    if ($ReportContent.Count -ne 0) {
        # Build Markdown-style message for Teams
        $TeamsMessage = "**🚨 SQL Log Shipping Failure Alert**`n`n"
        $TeamsMessage += "| Source | DatabaseName | InstanceName | InstanceIP | AlertStatus | ErrorMessage | AlertDate |`n"
        $TeamsMessage += "|---------|---------------|---------------|--------------|--------------|---------------|------------|`n"

        foreach ($row in $ReportContent) {
            $TeamsMessage += "| $($row.Source) | $($row.DatabaseName) | $($row.InstanceName) | $($row.InstanceIP) | $($row.AlertStatus) | $($row.ErrorMessage) | $($row.AlertDate) |`n"
        }

        # Prepare JSON payload for Teams
        $BodyJson = ConvertTo-Json -Depth 4 -Compress -InputObject @{
            "@type"    = "MessageCard"
            "@context" = "http://schema.org/extensions"
            summary   = "SQL Log Shipping Failure Notification"
            themeColor = "FF0000"  # Red for alert
            title     = "❗ SQL Log Shipping Failure Notification"
            text      = $TeamsMessage
        }

        # Send alert to Teams
        Invoke-RestMethod -Uri $TeamsWebhookUrl -Method Post -ContentType 'application/json' -Body $BodyJson

        Write-Host "Teams Log Shipping alert sent successfully!"
    } else {
        Write-Host "No valid log shipping failure data found. Alert not sent."
    }
} else {
    Write-Host "No log shipping alert CSV report file found. Alert not sent."
}
