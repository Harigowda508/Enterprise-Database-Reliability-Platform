-- Cleanup
IF OBJECT_ID('tempdb..#MissingIndexes') IS NOT NULL DROP TABLE #MissingIndexes;

CREATE TABLE #MissingIndexes
(
    DatabaseName SYSNAME,
    SchemaName SYSNAME,
    TableName SYSNAME,
    EqualityCols NVARCHAR(MAX),
    InequalityCols NVARCHAR(MAX),
    IncludeCols NVARCHAR(MAX)
);

DECLARE @DBName SYSNAME;

DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases
WHERE database_id > 4 AND state = 0;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DBName;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'
    USE ' + QUOTENAME(@DBName) + ';

    INSERT INTO #MissingIndexes
    SELECT
        DB_NAME() AS DatabaseName,
        s.name AS SchemaName,
        t.name AS TableName,
        migs.equality_columns,
        migs.inequality_columns,
        migs.included_columns
    FROM sys.dm_db_missing_index_details AS migs
    JOIN sys.dm_db_missing_index_groups AS mig
        ON migs.index_handle = mig.index_handle
    JOIN sys.tables AS t ON migs.object_id = t.object_id
    JOIN sys.schemas AS s ON t.schema_id = s.schema_id;
    ';

    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @DBName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Deduplicate
WITH Deduped AS
(
    SELECT DISTINCT
        DatabaseName,
        SchemaName,
        TableName,
        ISNULL(EqualityCols,'') AS EqualityCols,
        ISNULL(InequalityCols,'') AS InequalityCols,
        ISNULL(IncludeCols,'') AS IncludeCols
    FROM #MissingIndexes
)
SELECT 
    DatabaseName,
    SchemaName,
    TableName,
    EqualityCols,
    InequalityCols,
    IncludeCols,
    '-- CREATE NONCLUSTERED INDEX IX_' + TableName + '_' +
        REPLACE(REPLACE(ISNULL(EqualityCols,''),',','_'),' ','') + 
        CASE WHEN ISNULL(EqualityCols,'') + ISNULL(InequalityCols,'') <> '' 
             THEN ' (' + ISNULL(EqualityCols,'') + 
                  CASE WHEN ISNULL(EqualityCols,'')<>'' AND ISNULL(InequalityCols,'')<>'' THEN ',' ELSE '' END + 
                  ISNULL(InequalityCols,'') + ')' 
             ELSE '' END + 
        CASE WHEN IncludeCols <> '' THEN ' INCLUDE (' + IncludeCols + ')' ELSE '' END + ';' 
        AS SuggestedIndexScript
FROM Deduped
ORDER BY DatabaseName, TableName;
