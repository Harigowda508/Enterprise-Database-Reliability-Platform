CREATE procedure pj_DeadLockReport
as
BEGIN  
    SET NOCOUNT ON;  
WITH DeadlockData AS 
(
    -- Extract event data from system_health.xel for the previous day
    SELECT 
        CAST(event_data AS XML) AS DeadlockDetails
    FROM sys.fn_xe_file_target_read_file
    (
        'system_health*.xel', 
        NULL, 
        NULL, 
        NULL
    )
    --WHERE object_name = 'xml_deadlock_report'
    --  AND CAST(DATEADD(day, DATEDIFF(day, 0, GETDATE()) - 1, 0) AS DATE) = 
    --      CAST(DATEADD(hour, -1 * (DATEDIFF(hour, GETUTCDATE(), GETDATE())), 
    --      CAST(event_data AS XML).value('(event/@timestamp)[1]', 'datetime2')) AS DATE)
	WHERE object_name = 'xml_deadlock_report'
  AND CAST(event_data AS XML).value('(event/@timestamp)[1]', 'datetime2') 
      >= DATEADD(HOUR, -12, GETDATE())
),
FrameData AS 
(
    -- Extract stored procedure name and line number from executionStack/frame
    SELECT 
        Frames.value('@procname', 'NVARCHAR(256)') AS StoredProcedureName,  -- Extract stored procedure name
        Frames.value('@line', 'INT') AS LineNumber  -- Extract line number
    FROM DeadlockData
    CROSS APPLY DeadlockDetails.nodes('//executionStack/frame') AS FrameData(Frames)  -- Extract frame data
    WHERE Frames.exist('@procname') = 1  -- Filter to only frames with stored procedure names
)
-- Count how many times each stored procedure is involved in a deadlock and filter by kill count
insert into t_DeadLockReport
(
InstanceIP,
StoredProcedureName,
LineNumber,
KillCount,
insertedTimestamp
)
SELECT 
    CAST('SERVERIP' AS NVARCHAR(15)) AS InstanceIP,
    StoredProcedureName,
    LineNumber,
    COUNT(*) AS KillCount,
	getdate() as insertedTimestamp
FROM FrameData
  -- Exclude system stored procedures and ad-hoc queries
where 
StoredProcedureName NOT LIKE 'sys.%'   -- Exclude system stored procedures
AND StoredProcedureName NOT LIKE 'sp_%'  -- Exclude stored procedures starting with 'sp_' (common for system procs)



AND StoredProcedureName NOT LIKE '%adhoc%'  -- Exclude procedures starting with 'dbo.' (optional, depending on your schema conventions)
AND StoredProcedureName NOT LIKE '%mssqlsystemresource%' 
AND StoredProcedureName NOT LIKE '%unknown%'-- Exclude cases where there's no procedure name (ad-hoc queries)
GROUP BY 
    StoredProcedureName,
    LineNumber
HAVING COUNT(*) > 0 -- Filter only those with a kill count greater than 5
ORDER BY KillCount DESC,
StoredProcedureName;  -- Order by kill count in descending order

 SET NOCOUNT OFF;  
 end 


