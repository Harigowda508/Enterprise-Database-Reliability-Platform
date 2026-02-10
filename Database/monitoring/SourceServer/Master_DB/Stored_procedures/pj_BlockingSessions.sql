CREATE PROCEDURE pj_BlockingSessions
AS
BEGIN
    SET NOCOUNT ON;

    -- Common Table Expression (CTE) to find sessions that are blocking others
    WITH BlockingSessions AS (
        SELECT 
            r.blocking_session_id,
            COUNT(*) AS blocked_sessions_count
        FROM 
            sys.dm_exec_requests AS r
        WHERE 
            r.blocking_session_id > 0 -- Include only blocking sessions
        GROUP BY 
            r.blocking_session_id
    )

	insert into  [t_BlockingSessions]
    -- Select details of sessions blocking more than 5 other sessions for more than 10 minutes
    SELECT 
        s.session_id,
        r.STATUS,
        r.blocking_session_id AS 'blocked_by',
        'KILL ' + CAST(s.session_id AS NVARCHAR(100)) AS kill_command,
        CONVERT(VARCHAR, DATEADD(ms, r.wait_time, 0), 8) AS 'wait_time',
        COALESCE(
            QUOTENAME(OBJECT_NAME(st.objectid, st.dbid)), 
            ''
        ) AS 'stored_proc',
        RIGHT(s.login_name, 16) AS 'login_name',
        s.host_name,
        LEFT(s.program_name, 20) AS 'program_name',
        r.open_transaction_count AS 'Opentran',
        DB_NAME(st.dbid) AS database_name,
		GETDATE() AS AlertDate                            -- Include the database name for context
    FROM 
        sys.dm_exec_sessions AS s
    INNER JOIN 
        sys.dm_exec_requests AS r ON r.session_id = s.session_id
    CROSS APPLY 
        sys.dm_exec_sql_text(r.sql_handle) AS st
    LEFT JOIN 
        BlockingSessions bs ON s.session_id = bs.blocking_session_id
    WHERE 
        bs.blocked_sessions_count > 5 -- More than 5 sessions are blocked
        AND r.wait_time >= 5 * 60 * 1000 -- Blocking duration more than 5 minutes
    ORDER BY 
        r.total_elapsed_time DESC,
        r.STATUS,
        r.blocking_session_id,
        s.session_id;

    SET NOCOUNT OFF;
END;


