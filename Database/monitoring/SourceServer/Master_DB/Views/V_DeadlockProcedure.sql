CREATE VIEW V_DeadlockProcedure AS  
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
    WHERE object_name = 'xml_deadlock_report'  
      AND CAST(DATEADD(day, DATEDIFF(day, 0, GETDATE()) - 1, 0) AS DATE) =   
          CAST(DATEADD(hour, -1 * (DATEDIFF(hour, GETUTCDATE(), GETDATE())),   
          CAST(event_data AS XML).value('(event/@timestamp)[1]', 'datetime2')) AS DATE)  
   
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
SELECT   
    CAST('SERVERIP' AS NVARCHAR(15)) AS InstanceIP,  
    StoredProcedureName,  
    LineNumber,  
    COUNT(*) AS KillCount,  
    GETDATE() AS InsertedTimestamp  
FROM FrameData  
WHERE   
    StoredProcedureName NOT LIKE 'sys.%'   -- Exclude system stored procedures  
    AND StoredProcedureName NOT LIKE 'sp_%'  -- Exclude stored procedures starting with 'sp_'  
    AND StoredProcedureName NOT LIKE '%adhoc%'  -- Exclude ad-hoc queries  
    AND StoredProcedureName NOT LIKE '%ms%'  
    AND StoredProcedureName NOT LIKE '%unknown%'  
GROUP BY   
    StoredProcedureName,  
    LineNumber  
HAVING COUNT(*) > 5 -- Filter only those with a kill count greater than 5  
  
  
  
  