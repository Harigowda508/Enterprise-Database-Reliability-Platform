CREATE PROCEDURE p_InsertLoginDetails
AS
BEGIN
    SET NOCOUNT ON;

    -- TRUNCATE TABLE t_Fetchlogindetails

    INSERT INTO t_Fetchlogindetails (
        LoginName,
        Statusid,
        StatusOn,
        Inserted_Time,
        Server_IP
    )
    SELECT 
        l.name AS LoginName,
        CASE 
            WHEN l.is_disabled = 0 THEN 'Enabled'
            ELSE 'Disabled'
        END AS Statusid,
        ISNULL(r.name, 'No Role') AS StatusOn,
        GETDATE() AS Inserted_Time,
        conn.local_net_address AS Server_IP
    FROM 
        sys.sql_logins l
    LEFT JOIN 
        sys.server_role_members rm ON l.principal_id = rm.member_principal_id
    LEFT JOIN 
        sys.server_principals r ON rm.role_principal_id = r.principal_id
    CROSS APPLY 
    (
        SELECT DISTINCT local_net_address
        FROM sys.dm_exec_connections 
        WHERE session_id = @@SPID
    ) AS conn
    ORDER BY 
        l.name;
    SET NOCOUNT OFF;
END;


