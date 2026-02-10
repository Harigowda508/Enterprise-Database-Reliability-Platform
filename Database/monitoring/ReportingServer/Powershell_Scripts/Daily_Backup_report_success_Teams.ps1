# Teams Webhook URL (Replace with your actual webhook URL)
$TeamsWebhookUrl = "https://craftsiliconblr.webhook.office.com/webhookb2/1e5b44b8-9ecc-44a2-880f-4dc70febcd55@c6970a01-7db1-4e10-8d80-9f10ab0ccfbc/IncomingWebhook/d9d9c611ce50408391bd830c05feadd6/177c4eab-cd66-4b9f-896b-c4caa36e412a/V2UtuYsVpbF53X752yLvh2u7M8WjZoKG-gqu3aDBvWCxU1"

# Select the latest backup report CSV file
$ReportFile = Get-ChildItem -Path "D:\DATAEXT\OUTPUT\Daily_Backup_Report.csv" |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Check if the file exists
if ($ReportFile) {
    Write-Host "Processing the backup report file: $($ReportFile.FullName)"
    
    # Load and filter CSV content, removing empty or invalid rows
    $ReportContent = Import-Csv -Path $ReportFile.FullName | Where-Object {
        $_.job_name -ne "" -and $_.job_name -notmatch '^---+$'
    }

    if ($ReportContent.Count -ne 0) {
        # Calculate summary
        $TotalJobs = $ReportContent.Count
        $SucceededJobs = ($ReportContent | Where-Object { $_.job_status -eq "Succeeded" }).Count
        $FailedJobs = ($ReportContent | Where-Object { $_.job_status -ne "Succeeded" }).Count

        # Header for the Teams message
        $TeamsMessage = "**📦 SQL Daily Backup Report**`n`n"
        $TeamsMessage += "**Generated on:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
        $TeamsMessage += "**Summary:**`n"
        $TeamsMessage += "- Total Jobs: **$TotalJobs**`n"
        $TeamsMessage += "- Succeeded: ✅ **$SucceededJobs**`n"
        $TeamsMessage += "- Failed: ❌ **$FailedJobs**`n`n"

        # Build Markdown-style table
        $TeamsMessage += "| Job Name | Job Enabled | Frequency | Job Status | Job Duration | Succeeded Date | Succeeded Time | Error Message | Inserted Timestamp |`n"
        $TeamsMessage += "|-----------|--------------|------------|-------------|---------------|----------------|----------------|----------------|--------------------|`n"

        # Add each row (limit to 20 for readability)
        foreach ($row in $ReportContent | Select-Object -First 20) {
            $TeamsMessage += "| $($row.job_name) | $($row.job_enabled) | $($row.frequency) | $($row.job_status) | $($row.job_duration) | $($row.succeeded_date) | $($row.succeeded_time) | $($row.error_message) | $($row.inserted_timestamp) |`n"
        }

        # Prepare JSON payload for Teams
        $BodyJson = ConvertTo-Json -Depth 4 -Compress -InputObject @{
            "@type"    = "MessageCard"
            "@context" = "http://schema.org/extensions"
            summary    = "SQL Daily Backup Report"
            themeColor = if ($FailedJobs -gt 0) { "FF0000" } else { "2ECC71" } # Red if failures exist, green otherwise
            title      = "💾 SQL Daily Backup Report"
            text       = $TeamsMessage
        }

        # Send message to Teams
        Invoke-RestMethod -Uri $TeamsWebhookUrl -Method Post -ContentType 'application/json' -Body $BodyJson

        Write-Host "✅ Teams backup report sent successfully!"
    }
    else {
        Write-Host "No valid backup data found in the CSV. Alert not sent."
    }
}
else {
    Write-Host "No backup report file found at the specified path."
}
