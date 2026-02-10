CREATE VIEW V_LRBlockingSessions  
AS    
WITH BlockingSessions AS (    
    SELECT     
        r.blocking_session_id,    
        COUNT(*) AS blocked_sessions_count    
    FROM sys.dm_exec_requests AS r    
    WHERE r.blocking_session_id > 0    
    GROUP BY r.blocking_session_id    
)    
SELECT     
    q.session_id,    
    q.status,    
    q.blocked_by,    
    CONVERT(VARCHAR, DATEADD(ms, q.total_elapsed_time, 0), 8) AS elapsed_time, -- formatted hh:mm:ss    
    q.login_name,    
    q.stored_proc,    
    q.host_name,    
    q.database_name,    
    q.query_text    
       
FROM (    
    SELECT     
        s.session_id,    
        r.status,    
        r.blocking_session_id AS blocked_by,    
        r.total_elapsed_time,   -- use this for filtering    
        COALESCE(QUOTENAME(OBJECT_NAME(st.objectid, st.dbid)), '') AS stored_proc,    
        RIGHT(s.login_name, 16) AS login_name,    
        LEFT(    
            CAST(    
                SUBSTRING(    
                    st.text,    
                    (r.statement_start_offset / 2) + 1,    
                    (    
                        (CASE r.statement_end_offset    
                            WHEN -1 THEN DATALENGTH(st.text)    
                            ELSE r.statement_end_offset    
                         END - r.statement_start_offset) / 2    
                    ) + 1    
                )     
            AS NVARCHAR(MAX)),    
            30    
        ) AS query_text,   -- only first 30 chars    
        s.host_name,    
        DB_NAME(r.database_id) AS database_name,    
        bs.blocked_sessions_count    
    FROM sys.dm_exec_sessions AS s    
    INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id    
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st    
    LEFT JOIN BlockingSessions bs ON s.session_id = bs.blocking_session_id    
) q    
WHERE     
    q.stored_proc NOT LIKE '%r_%' 
    AND q.query_text NOT LIKE '%backup database%'   
 AND q.query_text NOT LIKE '%DBCC SHRINKFILE%'  
    AND (  
        -- Case 1: Session elapsed time >= 30 minutes  
        q.total_elapsed_time >= 30 * 60 * 1000  
  
        OR  
        -- Case 2: Blocking more than 5 sessions AND elapsed time >= 5 minutes  
        (q.blocked_sessions_count > 5 AND q.total_elapsed_time >= 5 * 60 * 1000)  
  
        OR  
        -- Case 3: Long running (>= 30 min) AND blocking  
        (q.total_elapsed_time >= 30 * 60 * 1000 AND q.blocked_sessions_count > 0)  
    );  
  
  
  
  
  