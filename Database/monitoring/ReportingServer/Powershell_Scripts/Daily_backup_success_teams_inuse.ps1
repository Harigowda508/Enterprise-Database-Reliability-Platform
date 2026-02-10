# Teams Webhook URL
$TeamsWebhookUrl = "https://craftsiliconblr.webhook.office.com/webhookb2/1e5b44b8-9ecc-44a2-880f-4dc70febcd55@c6970a01-7db1-4e10-8d80-9f10ab0ccfbc/IncomingWebhook/d9d9c611ce50408391bd830c05feadd6/177c4eab-cd66-4b9f-896b-c4caa36e412a/V2UtuYsVpbF53X752yLvh2u7M8WjZoKG-gqu3aDBvWCxU1"


# Get latest report
$ReportFile = Get-ChildItem -Path "D:\DATAEXT\OUTPUT\Daily_Backup_Report.csv" |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($ReportFile) {
    $ReportContent = Import-Csv -Path $ReportFile.FullName | Where-Object {
        $_.job_name -ne "" -and $_.job_name -notmatch '^---+$'
    }

    if ($ReportContent.Count -ne 0) {
        $TotalJobs = $ReportContent.Count
        $SucceededJobs = ($ReportContent | Where-Object { $_.job_status -eq "Succeeded" }).Count
        $FailedJobs = ($ReportContent | Where-Object { $_.job_status -ne "Succeeded" }).Count

        Write-Host "Total Jobs: $TotalJobs | Succeeded: $SucceededJobs | Failed: $FailedJobs"

        # Split data into chunks of 20 rows
        $ChunkSize = 20
        for ($i = 0; $i -lt $ReportContent.Count; $i += $ChunkSize) {
            $Batch = $ReportContent[$i..([math]::Min($i + $ChunkSize - 1, $ReportContent.Count - 1))]

            $TeamsMessage = "**💾 SQL Daily Backup Report (Part $([math]::Ceiling(($i + 1) / $ChunkSize)) of $([math]::Ceiling($ReportContent.Count / $ChunkSize)))**`n`n"
            if ($i -eq 0) {
                $TeamsMessage += "**Generated on:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
                $TeamsMessage += "**Total Jobs:** $TotalJobs  |  **Succeeded:** ✅ $SucceededJobs  |  **Failed:** ❌ $FailedJobs`n`n"
            }

            $TeamsMessage += "| Job Name | Job Enabled | Frequency | Job Status | Job Duration | Succeeded Date | Succeeded Time | Error Message | Inserted Timestamp |`n"
            $TeamsMessage += "|-----------|--------------|------------|-------------|---------------|----------------|----------------|----------------|--------------------|`n"

            foreach ($row in $Batch) {
                $TeamsMessage += "| $($row.job_name) | $($row.job_enabled) | $($row.frequency) | $($row.job_status) | $($row.job_duration) | $($row.succeeded_date) | $($row.succeeded_time) | $($row.error_message) | $($row.inserted_timestamp) |`n"
            }

            $BodyJson = ConvertTo-Json -Depth 4 -Compress -InputObject @{
                "@type"    = "MessageCard"
                "@context" = "http://schema.org/extensions"
                summary    = "SQL Daily Backup Report"
                themeColor = if ($FailedJobs -gt 0) { "FF0000" } else { "2ECC71" }
                title      = "📋 SQL Daily Backup Report - Batch $([math]::Ceiling(($i + 1) / $ChunkSize))"
                text       = $TeamsMessage
            }

            Invoke-RestMethod -Uri $TeamsWebhookUrl -Method Post -ContentType 'application/json' -Body $BodyJson
            Start-Sleep -Seconds 2
        }

        Write-Host "✅ All Teams messages sent successfully!"
    }
    else {
        Write-Host "No valid data found in CSV."
    }
}
else {
    Write-Host "Report file not found."
}
