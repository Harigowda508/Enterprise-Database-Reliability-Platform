CREATE PROCEDURE p_InsertDisabledJobs
AS
BEGIN
    SET NOCOUNT ON;

    WITH JobHistory AS (
        SELECT 
            j.name AS JobName,
            j.job_id,
            j.enabled AS JobStatus,  -- 0 = Disabled, 1 = Enabled
            MAX(h.run_date) AS LastModifiedDate,
            MAX(h.run_time) AS LastModifiedTime
        FROM 
            msdb.dbo.sysjobs j
        LEFT JOIN 
            msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
        WHERE 
            j.enabled = 0  -- Only fetch disabled jobs
        GROUP BY 
            j.name, j.job_id, j.enabled
    )
    INSERT INTO t_DisabledJobsHistory
	(JobName, 
	JobStatus,
	JOBDisabledDateTime, 
	ServerIP,
	InsertedTimestamp)

    SELECT DISTINCT  
        JobName,
        'Disabled' AS JobStatus,
        CONVERT(DATETIME, 
            CONVERT(VARCHAR(8), LastModifiedDate, 112) 
            + ' ' 
            + STUFF(STUFF(RIGHT('000000' + CAST(LastModifiedTime AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        ) AS JOBDisabledDateTime,
        'SERVERIP' AS ServerIP,
		getdate() as InsertedTimestamp
    FROM 
        JobHistory
    WHERE 
        CONVERT(DATETIME, 
            CONVERT(VARCHAR(8), LastModifiedDate, 112) 
            + ' ' 
            + STUFF(STUFF(RIGHT('000000' + CAST(LastModifiedTime AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        ) >= DATEADD(HOUR, -24, GETDATE())  -- Fetch jobs disabled in the last 24 hours
    ORDER BY 
        JOBDisabledDateTime DESC;
END;



