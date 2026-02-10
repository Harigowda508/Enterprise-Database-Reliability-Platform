CREATE VIEW V_JobsStatus AS  
SELECT DISTINCT  
     'SERVERIP' as ServerIP,  
    sysjobs.name AS job_name,  
    CASE   
        WHEN sysjobs.enabled = 1 THEN '1'  
        ELSE '0'  
    END AS job_enabled,  
      
    -- Frequency of job execution  
    CASE  
        WHEN schedules.freq_type = 1 THEN 'One Time'  
        WHEN schedules.freq_type = 4 THEN 'Daily'  
        WHEN schedules.freq_type = 8 THEN 'Weekly'  
        WHEN schedules.freq_type = 16 THEN 'Monthly'  
        WHEN schedules.freq_type = 32 THEN 'Monthly (Relative)'  
        ELSE 'Other'  
    END AS frequency,  
  
    -- Job run status  
    CASE   
        WHEN history.run_status = 1 THEN 'Succeeded'  
        WHEN history.run_status = 0 THEN 'Failed'  
        WHEN history.run_status = 3 THEN 'Cancelled'  
        ELSE 'Unknown'  
    END AS job_status,  
  
    -- Job duration in HH:MM:SS  
    RIGHT('00' + CAST((history.run_duration / 10000) AS VARCHAR(2)), 2) + ':' +   
    RIGHT('00' + CAST(((history.run_duration % 10000) / 100) AS VARCHAR(2)), 2) + ':' +   
    RIGHT('00' + CAST((history.run_duration % 100) AS VARCHAR(2)), 2) AS job_duration,  
  
    -- Execution date and time  
    CAST(CAST(history.run_date AS CHAR(8)) AS DATE) AS succeeded_date,  
    CAST(STUFF(STUFF(RIGHT('000000' + CAST(history.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS TIME(0)) AS succeeded_time,  
  
    -- Error message if job failed  
    (SELECT TOP 1 step_history.message   
     FROM msdb.dbo.sysjobhistory step_history  
     WHERE step_history.job_id = sysjobs.job_id  
           AND step_history.step_id = 1 -- Get only the 1st step error  
           AND step_history.run_status = 0  
           AND CAST(CAST(step_history.run_date AS CHAR(8)) AS DATE) = CAST(CAST(history.run_date AS CHAR(8)) AS DATE)  
           AND CAST(STUFF(STUFF(RIGHT('000000' + CAST(step_history.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS TIME(0))   
               BETWEEN CAST(STUFF(STUFF(RIGHT('000000' + CAST(history.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS TIME(0))   
               AND DATEADD(MINUTE, 1, CAST(STUFF(STUFF(RIGHT('000000' + CAST(history.run_time AS VARCHAR(6)), 6),3, 0, ':'), 6, 0, ':') AS TIME(0)))  
     ORDER BY step_history.run_date DESC, step_history.run_time DESC) AS error_message,  
  
    -- Timestamp for data insertion  
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
    msdb.dbo.sysjobhistory history ON sysjobs.job_id = history.job_id  
    AND history.instance_id = (  
        SELECT MAX(instance_id)  
        FROM msdb.dbo.sysjobhistory  
        WHERE sysjobs.job_id = job_id  
    )  
WHERE  
    sysjobs.name NOT LIKE '%LSBackup%'  
    AND sysjobs.name NOT LIKE '%LSCopy%'  
    AND sysjobs.name NOT LIKE '%LSRestore%'  
  
  
  
  
  