$server = "localhost"
$database = "EDRDP_DEV"

# Step 1: Create database (run against master)
sqlcmd -S $server -d master -i ".\database\00_DB_creation\00_CreateDatabase.sql"

# Step 2: Deploy remaining scripts
$sqlFiles = Get-ChildItem ".\database\01_deployment\*.sql" | Sort-Object Name

foreach ($file in $sqlFiles) {
    Write-Host "Executing $($file.Name)"
    sqlcmd -S $server -d $database -i $file.FullName
}

Write-Host "Deployment Completed Successfully"
