CREATE PROCEDURE p_tableGrowthSizeLog
AS
BEGIN
    SET NOCOUNT ON;

-- Step 1: Get list of user databases excluding system DBs and tempdb
DECLARE @DatabasesToCheck TABLE (DBName SYSNAME);

INSERT INTO @DatabasesToCheck (DBName)
SELECT name
FROM sys.databases
WHERE database_id > 4        -- Exclude system databases
  AND name NOT IN ('tempdb') -- Explicitly exclude tempdb
  AND state_desc = 'ONLINE'; -- Ensure DB is online

-- Step 2: Create the temp table
IF OBJECT_ID('tempdb..#TableSizes') IS NOT NULL DROP TABLE #TableSizes;

CREATE TABLE #TableSizes (
    DatabaseName SYSNAME,
    SchemaName SYSNAME,
    TableName SYSNAME,
    RowCounts BIGINT,
    TotalSpaceGB DECIMAL(18,2),
    InsertedTimestamp DATETIME
);

-- Step 3: Loop through databases dynamically
DECLARE @DBName SYSNAME;
DECLARE @SQL NVARCHAR(MAX);

DECLARE db_cursor CURSOR FOR 
SELECT DBName FROM @DatabasesToCheck;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DBName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = '
    USE [' + @DBName + '];

    INSERT INTO #TableSizes
    SELECT DISTINCT
        ''' + @DBName + ''' AS DatabaseName,
        s.name AS SchemaName,
        t.name AS TableName,
        p.rows AS RowCounts,
        CAST(SUM(a.total_pages) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS TotalSpaceGB,
        GETDATE() AS InsertedTimestamp
    FROM 
        sys.tables t
    INNER JOIN 
        sys.indexes i ON t.object_id = i.object_id
    INNER JOIN 
        sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    INNER JOIN 
        sys.allocation_units a ON p.partition_id = a.container_id
    INNER JOIN 
        sys.schemas s ON t.schema_id = s.schema_id
    WHERE 
        t.is_ms_shipped = 0
    GROUP BY 
        s.name, t.name, p.rows
    HAVING 
        SUM(a.total_pages) * 8.0 / 1024 / 1024 > 0';

    BEGIN TRY
        EXEC sp_executesql @SQL;
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred in database: ' + @DBName + ' - ' + ERROR_MESSAGE();
    END CATCH;

    FETCH NEXT FROM db_cursor INTO @DBName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Step 4: Insert into central table
INSERT INTO [t_ClientTableSizeLog]
SELECT * 
FROM #TableSizes
ORDER BY DatabaseName ASC, TotalSpaceGB DESC;

SET NOCOUNT OFF;
END




