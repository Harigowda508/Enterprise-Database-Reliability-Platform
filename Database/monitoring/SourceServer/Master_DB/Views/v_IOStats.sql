  
  
  
CREATE VIEW v_IOStats  
AS  
SELECT   
    'SERVERIP' AS ServerIP,  
    tab.Drive,  
    tab.volume_mount_point AS VolumeMountPoint,  
  
    CASE WHEN num_of_reads = 0 THEN 0  
         ELSE (io_stall_read_ms / num_of_reads) END AS ReadLatencyMs,  
  
    CASE WHEN num_of_writes = 0 THEN 0  
         ELSE (io_stall_write_ms / num_of_writes) END AS WriteLatencyMs,  
  
    CASE WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0  
         ELSE (io_stall / (num_of_reads + num_of_writes)) END AS OverallLatencyMs,  
  
    CASE WHEN num_of_reads = 0 THEN 0  
         ELSE (num_of_bytes_read / num_of_reads) END AS AvgBytesRead,  
  
    CASE WHEN num_of_writes = 0 THEN 0  
         ELSE (num_of_bytes_written / num_of_writes) END AS AvgBytesWrite,  
  
    CASE WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0  
         ELSE ((num_of_bytes_read + num_of_bytes_written) / (num_of_reads + num_of_writes)) END AS AvgBytesTransfer,  
   GETDATE() AS LogTime  
FROM  
(  
    SELECT   
        LEFT(UPPER(mf.physical_name), 2) AS Drive,  
        SUM(num_of_reads) AS num_of_reads,  
        SUM(io_stall_read_ms) AS io_stall_read_ms,  
        SUM(num_of_writes) AS num_of_writes,  
        SUM(io_stall_write_ms) AS io_stall_write_ms,  
        SUM(num_of_bytes_read) AS num_of_bytes_read,  
        SUM(num_of_bytes_written) AS num_of_bytes_written,  
        SUM(io_stall) AS io_stall,  
        vs.volume_mount_point  
    FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs  
    INNER JOIN sys.master_files mf WITH(NOLOCK)  
        ON vfs.database_id = mf.database_id  
       AND vfs.file_id = mf.file_id  
    CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs  
    GROUP BY LEFT(UPPER(mf.physical_name), 2), vs.volume_mount_point  
) AS tab;  