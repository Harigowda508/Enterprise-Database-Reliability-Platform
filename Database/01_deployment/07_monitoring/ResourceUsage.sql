SELECT TOP 10
    qs.total_worker_time / qs.execution_count AS avg_cpu,
    qs.execution_count,
    t.text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
ORDER BY avg_cpu DESC;
