# Microsoft Teams Webhook URL
$TeamsWebhook = "https://craftsiliconblr.webhook.office.com/webhookb2/1e5b44b8-9ecc-44a2-880f-4dc70febcd55@c6970a01-7db1-4e10-8d80-9f10ab0ccfbc/IncomingWebhook/62f96f6ee29048a4b6d96ae55f7dff0a/e3213da5-6554-41c0-82fa-0196609ef20f/V23IKkj_bZdcy2p_LIQ-Cu-Ltt-hGAZwDGGlbJ1WjWMik1"   # Replace with your Webhook URL

# Select the latest CSV file
$ReportFile = Get-ChildItem -Path "D:\DATAEXT\OUTPUT\Daily_AppJobsFailedReport.csv" |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Check if the file exists
if ($ReportFile) {
    Write-Host "Processing the report file: $($ReportFile.FullName)"
    
    # Load and filter CSV content, skipping unwanted rows
    $ReportContent = Import-Csv -Path $ReportFile.FullName | Where-Object {
        $_.job_name -ne "" -and $_.job_name -notmatch '^---+$'
    }

    # Check if there are failed jobs
    if ($ReportContent.Count -ne 0) {

        # Generate Adaptive Card JSON for Microsoft Teams
        $AdaptiveCard = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "themeColor" = "ff0000"
            "summary" = "SQL Job Failures"
            "title" = "🚨 SQL Job Failure Alert 🚨"
            "sections" = @(@{
                "activityTitle" = "The following SQL Jobs have failed:"
                "activitySubtitle" = "Review the details below:"
                "facts" = @()
            })
        }

        # Add each failed job as a fact entry in the table
        foreach ($row in $ReportContent) {
            $AdaptiveCard["sections"][0]["facts"] += @{
                "name" = "**Job:** $($row.job_name -replace '\\', '/')"
                "value" = "**Server:** $($row.ServerIP)  \n **Error:** $($row.error_message -replace '\\', '/')"
            }
        }

        # Send the alert to Microsoft Teams
        try {
            Invoke-RestMethod -Uri $TeamsWebhook -Method Post -Body ($AdaptiveCard | ConvertTo-Json -Depth 3) -ContentType 'application/json'
            Write-Host "Teams Alert Sent Successfully!"
        } catch {
            Write-Host "Failed to send Teams alert: $_"
        }
    } else {
        Write-Host "No valid data in the report file. Teams alert not sent."
    }
} else {
    Write-Host "No failed job data found. Teams alert not sent."
}
