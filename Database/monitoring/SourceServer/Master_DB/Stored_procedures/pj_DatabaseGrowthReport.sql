CREATE PROCEDURE pj_DatabaseGrowthReport    
AS    
BEGIN    
    SET NOCOUNT ON;    

  
INSERT INTO t_DBGrowthReport 
(server_ip,
dbname,
dbsize,
inserted_timestamp) 

-- Main query  
SELECT     
    'ServerIP' AS server_ip,    
    d.name AS dbname, -- Explicitly reference the name column from sys.databases    
    -- Calculate the database size dynamically based on size in MB    
        CASE     
            WHEN CAST(SUM(CAST(mf.size AS BIGINT)) * 8.0 / 1024.0 / 1024.0 / 1024.0 AS DECIMAL(18, 2)) >= 1 THEN    
                -- Convert to TB if size in GB is greater than or equal to 1 TB    
                CAST(ROUND(CAST(SUM(CAST(mf.size AS BIGINT)) * 8.0 / 1024.0 / 1024.0 / 1024.0 AS DECIMAL(18, 2)), 2) AS NVARCHAR(50)) + ' TB'    
            WHEN CAST(SUM(CAST(mf.size AS BIGINT)) * 8.0 / 1024.0 / 1024.0 AS DECIMAL(18, 2)) >= 1 THEN    
                -- Convert to GB if size in MB is greater than or equal to 1 GB    
                CAST(ROUND(CAST(SUM(CAST(mf.size AS BIGINT)) * 8.0 / 1024.0 / 1024.0 AS DECIMAL(18, 2)), 2) AS NVARCHAR(50)) + ' GB'    
            WHEN SUM(CAST(mf.size AS BIGINT)) * 8.0 / 1024.0 >= 1 THEN    
                -- Convert to MB if size is greater than or equal to 1 MB    
                CAST(ROUND(SUM(CAST(mf.size AS BIGINT)) * 8.0 / 1024.0, 0) AS NVARCHAR(50)) + ' MB'    
            ELSE    
                -- If size is less than 1 MB, use KB    
                CAST(SUM(CAST(mf.size AS BIGINT)) * 8.0 AS NVARCHAR(50)) + ' KB'    
        END AS dbsize,     
  
    GETDATE() AS inserted_timestamp    
  
FROM     
    master.sys.master_files mf    
INNER JOIN     
    master.sys.databases d ON mf.database_id = d.database_id    
  
WHERE    
    d.name NOT LIKE '%master%'     
    AND d.name NOT LIKE '%model%'    
    AND d.name NOT LIKE '%msdb%'    
    AND d.name NOT LIKE '%tempdb%'     
    AND d.name NOT LIKE '%brnettac%'    
  
GROUP BY     
    d.name;  
   
END;


