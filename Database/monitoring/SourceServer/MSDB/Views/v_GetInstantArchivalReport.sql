CREATE VIEW v_GetInstantArchivalReport as  
  SELECT   
    'ServerIP' AS ServerIP,  
    sysjobs.name AS job_name,  
    sysjobs.enabled AS job_enabled,  
  
    -- Frequency Type  
    CASE schedules.freq_type  
        WHEN 1 THEN 'One Time'  
        WHEN 4 THEN 'Daily'  
        WHEN 8 THEN 'Weekly'  
        WHEN 16 THEN 'Monthly'  
        WHEN 32 THEN 'Monthly (Relative)'  
        ELSE 'Other'  
    END AS frequency,  
  
    -- Job run status   
    CASE history.run_status  
        WHEN 1 THEN 'Succeeded'  
        WHEN 0 THEN 'Failed'  
        WHEN 3 THEN 'Cancelled'  
        ELSE 'Unknown'  
    END AS job_status,  
  
    -- Duration to HH:MM:SS  
    RIGHT('00' + CAST(history.run_duration / 10000 AS VARCHAR(2)), 2) + ':' +  
    RIGHT('00' + CAST((history.run_duration % 10000) / 100 AS VARCHAR(2)), 2) + ':' +  
    RIGHT('00' + CAST(history.run_duration % 100 AS VARCHAR(2)), 2) AS job_duration,  
  
    -- Date and Time  
    CAST(CAST(history.run_date AS CHAR(8)) AS DATE) AS succeeded_date,  
    CAST(STUFF(STUFF(RIGHT('000000' + CAST(history.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS TIME(0)) AS succeeded_time,  
  
    -- Error message (for FAILED job only)  
    (  
        SELECT TOP 1 step_history.message  
        FROM msdb.dbo.sysjobhistory step_history  
        WHERE step_history.job_id = sysjobs.job_id  
          AND step_history.step_id = 1  
          AND step_history.run_status = 0  
          AND CAST(CAST(step_history.run_date AS CHAR(8)) AS DATE) =  
              CAST(CAST(history.run_date AS CHAR(8)) AS DATE)  
          AND   
          CAST(  
                STUFF(STUFF(RIGHT('000000' + CAST(step_history.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':'  
                ) AS TIME(0)  
              )  
              BETWEEN   
              CAST(STUFF(STUFF(RIGHT('000000' + CAST(history.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS TIME(0))  
              AND   
              DATEADD(MINUTE, 1, CAST(STUFF(STUFF(RIGHT('000000' + CAST(history.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS TIME(0)))  
        ORDER BY step_history.instance_id DESC  
    ) AS error_message,  
  
    GETDATE() AS inserted_timestamp  
  
FROM   
    msdb.dbo.sysjobs sysjobs  
LEFT JOIN   
    msdb.dbo.syscategories categories ON sysjobs.category_id = categories.category_id  
LEFT JOIN   
    msdb.dbo.sysjobschedules jobschedules ON sysjobs.job_id = jobschedules.job_id  
LEFT JOIN   
    msdb.dbo.sysschedules schedules ON jobschedules.schedule_id = schedules.schedule_id  
LEFT JOIN   
    msdb.dbo.sysjobhistory history   
        ON sysjobs.job_id = history.job_id  
       AND history.instance_id = (  
            SELECT MAX(instance_id)  
            FROM msdb.dbo.sysjobhistory  
            WHERE job_id = sysjobs.job_id  
        )  
  
WHERE   
    (  
        sysjobs.name LIKE '%ARC%'  
        OR sysjobs.name LIKE '%maint%'  
        OR sysjobs.name LIKE '%Archival%'  
    )  
    AND sysjobs.name NOT LIKE 'DBA_ARCHIVAL_REPORT'  
    AND sysjobs.enabled = 1;  
  
    
  
  
  
  
  
  