CREATE PROCEDURE pj_InsertDailyBackupReport
AS
BEGIN
    SET NOCOUNT ON;
	 -- Insert daily data into the existing table without duplicates
    INSERT INTO [t_DBADailybackupReport]
    (
        job_name,
        job_enabled,
        frequency,
        job_status,
        job_duration,
        succeeded_date,
        succeeded_time,
        error_message,
        inserted_timestamp
    )

    SELECT DISTINCT
        sysjobs.name AS job_name,
        CASE 
            WHEN sysjobs.enabled = 1 THEN '1'
            ELSE '0'
        END AS job_enabled,
        
        CASE
            WHEN schedules.freq_type = 1 THEN 'One Time'
            WHEN schedules.freq_type = 4 THEN 'Daily'
            WHEN schedules.freq_type = 8 THEN 'Weekly'
            WHEN schedules.freq_type = 16 THEN 'Monthly'
            WHEN schedules.freq_type = 32 THEN 'Monthly (Relative)'
            ELSE 'Other'
        END AS frequency,
        
        CASE 
            WHEN history.run_status = 1 THEN 'Succeeded'
            WHEN history.run_status = 0 THEN 'Failed'
            WHEN history.run_status = 3 THEN 'Cancelled'
            ELSE 'Unknown'
        END AS job_status,
        
        FORMAT(DATEADD(SECOND, history.run_duration % 100 + (history.run_duration / 100) % 100 * 60 + (history.run_duration / 10000) * 3600, 0), 'HH:mm:ss') AS job_duration,
        
        CONVERT(DATE, CONVERT(CHAR(8), history.run_date)) AS succeeded_date,
        TIMEFROMPARTS(history.run_time / 10000, (history.run_time / 100) % 100, history.run_time % 100, 0, 0) AS succeeded_time,
        
        (SELECT TOP 1 step_history.message 
         FROM msdb.dbo.sysjobhistory step_history
         WHERE step_history.job_id = sysjobs.job_id
               AND step_history.step_id = 1
               AND step_history.run_status = 0
               AND CONVERT(DATE, CONVERT(CHAR(8), step_history.run_date)) = CONVERT(DATE, CONVERT(CHAR(8), history.run_date))
               AND TIMEFROMPARTS(step_history.run_time / 10000, (step_history.run_time / 100) % 100, step_history.run_time % 100, 0, 0) 
                   BETWEEN TIMEFROMPARTS(history.run_time / 10000, (history.run_time / 100) % 100, history.run_time % 100, 0, 0)
                   AND DATEADD(MINUTE, 1, TIMEFROMPARTS(history.run_time / 10000, (history.run_time / 100) % 100, history.run_time % 100, 0, 0))
         ORDER BY step_history.run_date DESC, step_history.run_time DESC) AS error_message,
        
        GETDATE() AS inserted_timestamp
    
    FROM msdb.dbo.sysjobs sysjobs
    LEFT JOIN msdb.dbo.syscategories categories ON sysjobs.category_id = categories.category_id
    LEFT JOIN msdb.dbo.sysjobschedules jobschedules ON sysjobs.job_id = jobschedules.job_id
    LEFT JOIN msdb.dbo.sysschedules schedules ON jobschedules.schedule_id = schedules.schedule_id
    LEFT JOIN msdb.dbo.sysjobhistory history ON sysjobs.job_id = history.job_id
        AND history.instance_id = (
            SELECT MAX(instance_id)
            FROM msdb.dbo.sysjobhistory
            WHERE sysjobs.job_id = job_id
        )
    
    WHERE (sysjobs.name LIKE '%backup%' 
           OR sysjobs.name LIKE '%maint%'
           OR sysjobs.name LIKE '%bak%'
           OR sysjobs.start_step_id LIKE '%subplan_1%')
        AND sysjobs.name NOT LIKE '%LSBackup%'
        AND sysjobs.enabled = 1
        AND sysjobs.name NOT LIKE '%DBA_BACKUP_ALERT%'

    ORDER BY succeeded_date DESC, succeeded_time DESC, job_enabled;
    
    SET NOCOUNT OFF;
END;


