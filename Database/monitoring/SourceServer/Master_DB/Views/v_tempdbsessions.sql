CREATE VIEW v_tempdbsessions      
AS      
SELECT   
     'SERVERIP'as Server_IP ,  
    tsk.session_id,  
    s.login_name,  
    s.host_name,  
    (tsk.user_objects_alloc_page_count + tsk.internal_objects_alloc_page_count) * 8 / 1024 AS TempDB_MB,  
    r.status,  
    r.command,  
    DB_NAME(r.database_id) AS DBName,  
    CONVERT(NVARCHAR(MAX), t.text) AS SQLText ,  
  getdate() as insertedtimestamp-- explicit conversion  
FROM sys.dm_db_task_space_usage AS tsk  
JOIN sys.dm_exec_sessions AS s ON tsk.session_id = s.session_id  
JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id  
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t;  