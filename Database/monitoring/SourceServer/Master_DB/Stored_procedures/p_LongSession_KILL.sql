CREATE PROCEDURE [dbo].[p_LongSession_KILL]
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @sSQL nvarchar(200)

	DECLARE @sKILL		INT
	DECLARE @iCount		BIT

	INSERT INTO LongRunningQueriesInfo
	(
		SPID					
		,StartTime  
		,DATE
		,TimeTaken_Mins		
		,STATUS            	
		,[Login]           	
		,Host              	
		,BlkBy             	
		,DBName            	
		,CommandType       	
		,ObjectName        	
		,SQLStatement      	
		,ElapsedMS         	
		,CPUTime           	
		,IOReads           	
		,IOWrites          	
		,LastWaitType      	
		,Protocol          	
		,ConnectionWrites  	
		,ConnectionReads   	
		,ClientAddress     	
		,Authentication    	
	)

	---Queries currently running more than 2 hours
	SELECT
		SPID                = er.session_id
		,StartTime          = er.start_time,GETDATE() GETDATE
		,DATEDIFF(SECOND,er.start_time,GETDATE())/60 TimeTaken_Mins
		,STATUS             = ses.STATUS
		,[Login]            = ses.login_name
		,Host               = ses.host_name
		,BlkBy              = er.blocking_session_id
		,DBName             = DB_Name(er.database_id)
		,CommandType        = er.command
		,ObjectName         = OBJECT_NAME(st.objectid)
		,SQLStatement       = st.text
		,ElapsedMS          = er.total_elapsed_time
		,CPUTime            = er.cpu_time
		,IOReads            = er.logical_reads + er.reads
		,IOWrites           = er.writes
		,LastWaitType       = er.last_wait_type
		,Protocol           = con.net_transport
		,ConnectionWrites   = con.num_writes
		,ConnectionReads    = con.num_reads
		,ClientAddress      = con.client_net_address
		,Authentication     = con.auth_scheme
	FROM sys.dm_exec_requests er
	OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
	LEFT JOIN sys.dm_exec_sessions ses
	ON ses.session_id = er.session_id
	LEFT JOIN sys.dm_exec_connections con
	ON con.session_id = ses.session_id
	--WHERE DB_Name(er.database_id)='smfnew'  --- for choose required db
	where er.database_id>4  and er.session_id<>@@SPID and DATEDIFF(SECOND,er.start_time,GETDATE())/60 > 120 -- to avoid system databases and ur session and >10 means running more than 10 mins
	--where  DATEDIFF(SECOND,er.start_time,GETDATE())/60 > 1 
	--WHERE er.command='TRACE QUEUE TASK'
	and command NOT IN('KILLED/ROLLBACK')
	and (command LIKE '%ALTER%INDEX%' OR
  OBJECT_NAME(st.objectid, st.dbid) in('p_GLOSProfileImageMovement_new','p_GLOSProfileImageCleanUp','p_ImageMovement','p_ImageCleanUp'))

	ORDER BY   er.session_id desc

	L:
	SET @iCount = 0 


	DECLARE LONG_SESSION CURSOR FOR
		SELECT er.session_id
		FROM sys.dm_exec_requests er
		OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
		LEFT JOIN sys.dm_exec_sessions ses
		ON ses.session_id = er.session_id
		LEFT JOIN sys.dm_exec_connections con
		ON con.session_id = ses.session_id
		where er.database_id>4  and er.session_id<>@@SPID and DATEDIFF(SECOND,er.start_time,GETDATE())/60 > 120 -- to avoid system databases and ur session and >10 means running more than 10 mins
		and command NOT IN('KILLED/ROLLBACK')
		AND ((command LIKE '%ALTER%INDEX%' or
		OBJECT_NAME(st.objectid, st.dbid) in('need to mention the specific session Sp s to kill here')))
		--ORDER BY   er.session_id desc
	
	OPEN LONG_SESSION
	FETCH NEXT FROM LONG_SESSION
	INTO @sKILL
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @iCount = 1
		SET @sSQL = 'KILL ' + CAST(@sKILL as Varchar(10))
	
		EXEC sp_ExecuteSQL   @sSQL 

		FETCH NEXT FROM LONG_SESSION
		INTO @sKILL

	END

	CLOSE LONG_SESSION
	DEALLOCATE LONG_SESSION

	
	IF @iCount = 1
	BEGIN
		GOTO L;
	END

	SET NOCOUNT OFF


END


