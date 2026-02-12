$ErrorActionPreference = "Stop"

# -----------------------------
# Configuration
# -----------------------------
$server   = "CSPLBLRLP403\HARISHINSTANCE"
$database = "EDRDP_DEV"
$basePath = "D:\Enterprise-Database-Reliability-Platform\Database"

Write-Host "Starting Deployment..."
Write-Host "Server: $server"
Write-Host "Database: $database"
Write-Host ""

# -----------------------------
# Step 1: Create Database
# -----------------------------
Write-Host "Creating database (if not exists)..."

sqlcmd -S $server `
       -U sa `
       -P "Password@12345" `
       -d master `
       -i "$basePath\00_CreateDatabase.sql"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Database creation failed!"
    exit 1
}

# -----------------------------
# Step 2: Deploy All Objects
# -----------------------------
$sqlFiles = Get-ChildItem -Path $basePath -Recurse -Filter *.sql |
            Where-Object { $_.FullName -notmatch "recovery" -and $_.Name -ne "00_CreateDatabase.sql" } |
            Sort-Object FullName

foreach ($file in $sqlFiles) {

    Write-Host "Executing $($file.FullName)"

    sqlcmd -S $server `
           -U sa `
           -P "Password@12345" `
           -d $database `
           -i "$($file.FullName)"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error executing $($file.Name)"
        exit 1
    }
}

Write-Host ""
Write-Host "Deployment Completed Successfully"
