SELECT
    name,
    size * 8 / 1024 AS size_mb
FROM sys.database_files;
