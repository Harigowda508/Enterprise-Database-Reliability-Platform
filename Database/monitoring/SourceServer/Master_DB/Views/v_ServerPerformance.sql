CREATE VIEW v_ServerPerformance AS  
SELECT  
    'SERVERIP' AS InstanceIP,  
    (  
       SELECT CASE   
           WHEN AVG(wait_time_ms) > 0   
                THEN (100 - AVG(signal_wait_time_ms * 1.0 / NULLIF(wait_time_ms, 0)) * 100)   
                ELSE 0   
       END  
       FROM sys.dm_os_wait_stats  
       WHERE wait_type NOT IN ('SLEEP_TASK', 'SLEEP_BPOOL_FLUSH')  
    ) AS CPUUsagePercent,  
    (  
       SELECT CASE   
            WHEN total_physical_memory_kb > 0   
                 THEN ((total_physical_memory_kb - available_physical_memory_kb) / (total_physical_memory_kb * 1.0)) * 100  
                 ELSE 0   
       END  
       FROM sys.dm_os_sys_memory  
    ) AS MemoryUsagePercent,  
    (  
       SELECT COALESCE(SUM(size * 8.0 / 1024 / 1024), 0)  
       FROM sys.master_files  
    ) AS DiskUsageGB,  
    (  
       SELECT COUNT(*)  
       FROM sys.dm_exec_sessions  
       WHERE is_user_process = 1  
    ) AS ActiveSessions,  
    GETDATE() AS LastUpdated;  