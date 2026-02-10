CREATE VIEW v_DriveSpaceStatus
AS  
SELECT  
    'ServerIP' AS ServerIP,  
    vs.volume_mount_point,  
    vs.logical_volume_name,  
    ROUND(MAX(vs.total_bytes) / 1073741824.0, 2) AS Total_GB,     -- GB as decimal  
    ROUND(MAX(vs.available_bytes) / 1073741824.0, 2) AS Free_GB,  
    ROUND(MAX(vs.total_bytes) / 1099511627776.0, 3) AS Total_TB,  -- TB as decimal  
    ROUND(MAX(vs.available_bytes) / 1099511627776.0, 3) AS Free_TB  
FROM sys.master_files AS mf  
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) AS vs  
GROUP BY  
    vs.volume_mount_point,  
    vs.logical_volume_name;  