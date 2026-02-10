CREATE  PROCEDURE pj_GetLogShippingRestoreSuccess                 
AS                  
BEGIN                  
    -- Setting NOCOUNT ON to reduce unnecessary result sets                  
    SET NOCOUNT ON;      
WITH SecondaryInfo AS (      
    SELECT      
        secondary_id AS ID,      
        secondary_server AS ServerName,      
        secondary_database AS DatabaseName,      
        restore_threshold AS RestoreThresholdMinutes,      
  restore_threshold,      
  dATEDIFF(MINUTE, last_restored_date, GETDATE()) acutaltimeoflast,      
  is_read_only,      
  is_in_standby,      
  d.state ,      
        CASE       
            WHEN DATEDIFF(MINUTE, last_restored_date, GETDATE()) > (restore_threshold) and  d.state <>2 and is_in_standby=1 and d.state=0 THEN 'Alert'      
      WHEN   d.state = 2 and d.state <> 1 THEN 'Recovery'      
   WHEN DATEDIFF(MINUTE, last_restored_date, GETDATE()) > (restore_threshold)  and  d.state = 1 THEN 'Restoring'
   when is_in_standby <> 1 then  'normal'
      else       
      'Good'      
      END AS RestoreAlertStatus,      
       -- 'Restore Threshold Exceeded' AS ErrorMessage, -- Error message for restore alerts      
  GETDATE() AS AlertDate, -- Adding current date and time as AlertDate       
        'SERVERIP' AS InstanceIP -- Retrieve instance IP      
    FROM log_shipping_monitor_secondary s       
 inner join sys.databases d      
 on      
 s.secondary_database = d.name      
      
    WHERE EXISTS (      
    SELECT 1      
FROM sys.databases d      
WHERE d.name = s.secondary_database     )      
)      
      
 INSERT INTO t_LogShippingSuccess      
      
-- Fetch only 'Secondary - Restore' alerts for online databases      
  SELECT                   
        'Secondary - Restore' AS Source,                  
        s.DatabaseName,                  
        s.ServerName AS InstanceName,                  
        s.InstanceIP AS InstanceIP,                  
        s.RestoreAlertStatus AS LogStatus,                  
       -- s.ErrorMessage AS ErrorMessage,                  
        s.AlertDate -- Include the alert date                  
    FROM                   
        SecondaryInfo s       
WHERE       
    s.RestoreAlertStatus in ('Good','Recovery','Alert','Restoring')      
ORDER BY       
    DatabaseName, Source;      
END; 