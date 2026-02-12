$ErrorActionPreference = "Stop"
$server = "CSPLBLRLP403\HARISHINSTANCE"
$database = "EDRDP_DEV"

# Step 1: Create database (run against master)
sqlcmd -S $server -d master -i  "$basePath\00_CreateDatabase.sql"


$basePath = "D:\Enterprise-Database-Reliability-Platform\Database"

$sqlFiles = Get-ChildItem -Path $basePath -Recurse -Filter *.sql |
            Where-Object { $_.FullName -notmatch "recovery" } |
            Sort-Object FullName
try {

    foreach ($file in $sqlFiles) {
        Write-Host "Executing $($file.FullName)"
        sqlcmd -S $server -E -d EDRDP_DEV -i $file.FullName

    }

    Write-Host "Deployment Completed Successfully"

}
catch {
    Write-Host "Deployment Failed!"
    Write-Host $_.Exception.Message
}
