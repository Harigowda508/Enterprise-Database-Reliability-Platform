CREATE PROCEDURE p_tempdb_logspace
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ServerIP VARCHAR(50) = 'SERVERIP';

    CREATE TABLE #LogSpace
    (
        DatabaseName SYSNAME,
        LogSizeMB FLOAT,
        LogSpaceUsedPercent FLOAT,
        Status INT
    );

    INSERT INTO #LogSpace
    EXEC ('DBCC SQLPERF(LOGSPACE)');
	insert into t_tempdbLogSpace
    SELECT  
          @ServerIP AS Server_IP,
          DatabaseName,
          LogSizeMB,
          LogSpaceUsedPercent,
          Status,
          GETDATE() AS InsertedTimestamp
    FROM #LogSpace
    WHERE DatabaseName LIKE '%tempdb%'
      AND DatabaseName NOT LIKE '%BrNetTempDB%';
	 
	 drop table #LogSpace
	 
END;




