$server = "CSPLBLRLP403\HARISHINSTANCE"
$database = "EDRDP_DEV"

$sqlFiles = Get-ChildItem ".\database\**\*.sql" | Sort-Object Name

foreach ($file in $sqlFiles) {
    Write-Host "Executing $($file.Name)"
    sqlcmd -S $server -d $database -i $file.FullName
}
