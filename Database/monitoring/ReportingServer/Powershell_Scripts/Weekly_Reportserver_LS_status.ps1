# Teams Webhook URL for CLIENTNAME
$TeamsWebhookUrl = "https://craftsiliconblr.webhook.office.com/webhookb2/0c6214a5-3631-46ad-8f25-99a9e59a01a9@c6970a01-7db1-4e10-8d80-9f10ab0ccfbc/IncomingWebhook/4d6511da951c406984c716aa985f65a0/177c4eab-cd66-4b9f-896b-c4caa36e412a/V25Z1Cgwp3KoHvTPjENIzN9yXpIoV58nje4z2A0CniFUA1"

# Select latest success CSV
$ReportFile = Get-ChildItem -Path "D:\DATAEXT\OUTPUT\Logshipping_Success_Report.csv" |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($ReportFile) {
    Write-Host "Processing CLIENTNAME report from: $($ReportFile.FullName)"

    # Load CSV and skip redundant header row
    $ReportContent = Import-Csv -Path $ReportFile.FullName | Select-Object -Skip 1

    # Correct CLIENTNAME filter using colon!
    $CLIENTNAMERows = $ReportContent | Where-Object {
        $_.InstanceIP.Trim() -like "192.168.181.130:8181"
    }

    if ($CLIENTNAMERows.Count -gt 0) {
        
        $TeamsMessage  = "**📘 CLIENTNAME REPORT SERVER LOGSHIPPING STATUS**`n`n"
        $TeamsMessage += "| Source | DatabaseName | InstanceName | InstanceIP | LogStatus | AlertDate |`n"
        $TeamsMessage += "|--------|--------------|--------------|-------------|-----------|------------|`n"

        foreach ($row in $CLIENTNAMERows) {
            $TeamsMessage += "| $($row.Source) | $($row.DatabaseName) | $($row.InstanceName) | $($row.InstanceIP) | $($row.LogStatus) | $($row.AlertDate) |`n"
        }

        # JSON payload for Teams
        $BodyJson = ConvertTo-Json -Depth 4 -Compress -InputObject @{
            "@type"     = "MessageCard"
            "@context"  = "http://schema.org/extensions"
            summary     = "CLIENTNAME Log Shipping Status"
            themeColor  = "2E8B57"   # greenish blue
            title       = "✔ CLIENTNAME REPORT SERVER LOGSHIPPING STATUS"
            text        = $TeamsMessage
        }

        # Send to Teams
        Invoke-RestMethod -Uri $TeamsWebhookUrl -Method Post -ContentType 'application/json' -Body $BodyJson

        Write-Host "CLIENTNAME Teams report sent successfully!"
    }
    else {
        Write-Host "No CLIENTNAME rows found — showing actual IPs in CSV:"
        $ReportContent.InstanceIP | ForEach-Object { Write-Host "'$_'" }
    }
}
else {
    Write-Host "CSV file not found."
}
