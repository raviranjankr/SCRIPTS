/**	Script: SQL Server CPU Utilization report from last N minutes **/
/**	Output: 
	SQLServer_CPU_Utilization: % CPU utilized from SQL Server Process
	System_Idle_Process: % CPU Idle - Not serving to any process 
	Other_Process_CPU_Utilization: % CPU utilized by processes otherthan SQL Server
	Event_Time: Time when these values captured
**/
DECLARE @ts BIGINT;
DECLARE @lastNmin TINYINT;
SET @lastNmin = 180;

SELECT @ts =(SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info); 

SELECT TOP(@lastNmin)
		SQLProcessUtilization AS [SQLServer_CPU_Utilization], 
		SystemIdle AS [System_Idle_Process], 
		100 - SystemIdle - SQLProcessUtilization AS [Other_Process_CPU_Utilization], 
		DATEADD(ms,-1 *(@ts - [timestamp]),GETDATE())AS [Event_Time] 
FROM (SELECT record.value('(./Record/@id)[1]','int')AS record_id, 
record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]','int')AS [SystemIdle], 
record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','int')AS [SQLProcessUtilization], 
[timestamp]      
FROM (SELECT[timestamp], convert(xml, record) AS [record]             
FROM sys.dm_os_ring_buffers             
WHERE ring_buffer_type =N'RING_BUFFER_SCHEDULER_MONITOR'AND record LIKE'%%')AS x )AS y 
ORDER BY record_id DESC;


/**	Script: Top 20 Stored Procedures using High CPU **/
/**	Output: Queries, CPU, Elapsed Times, Ms and S ***/
SELECT TOP (20)
    st.text AS Query,
    qs.execution_count,
    qs.total_worker_time AS Total_CPU,
    total_CPU_inSeconds = --Converted from microseconds
    qs.total_worker_time/1000000,
    average_CPU_inSeconds = --Converted from microseconds
    (qs.total_worker_time/1000000) / qs.execution_count,
    qs.total_elapsed_time,
    total_elapsed_time_inSeconds = --Converted from microseconds
    qs.total_elapsed_time/1000000,
    qp.query_plan
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE);


/**	Script: Top 20 Stored Procedures using High CPU **/
/**	Output: 
		SP Name: Stored Procedure Name, TotalWorkerTime: Total Worker Time since the last compile time, AvgWorkerTime: Average Worker Time since last compile time execution_count: Total number of execution since last compile time, 
		Calls/Second: Number of calls / executions per second, total_elapsed_time: total elapsed time, avg_elapsed_time: Average elapsed time, cached_time: Procedure Cached time
**/
SELECT TOP (20) 
  p.name AS [SP Name], 
  qs.total_worker_time AS [TotalWorkerTime], 
  qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
  qs.execution_count, 
  ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
  qs.total_elapsed_time, 
  qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], 
  qs.cached_time
FROM	sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK) ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE);


/**	Script: Database Wise CPU Utilization report **/
/***	Output: SNO: Serial Number, DBName: Databse Name, CPU_Time(Ms): CPU Time in Milliseconds, CPUPercent: Let???s say this instance is using 50% CPU and one of the database is      
using 80%. It means the actual CPU usage from the database is calculated as: (80 / 100) * 50 = 40 %
***/
WITH DB_CPU AS
(SELECT	DatabaseID, 
		DB_Name(DatabaseID)AS [DatabaseName], 
		SUM(total_worker_time)AS [CPU_Time(Ms)] 
FROM	sys.dm_exec_query_stats AS qs 
CROSS APPLY(SELECT	CONVERT(int, value)AS [DatabaseID]  
			FROM	sys.dm_exec_plan_attributes(qs.plan_handle)  
			WHERE	attribute =N'dbid')AS epa GROUP BY DatabaseID) 
SELECT	ROW_NUMBER()OVER(ORDER BY [CPU_Time(Ms)] DESC)AS [SNO], 
	DatabaseName AS [DBName], [CPU_Time(Ms)], 
	CAST([CPU_Time(Ms)] * 1.0 /SUM([CPU_Time(Ms)]) OVER()* 100.0 AS DECIMAL(5, 2))AS [CPUPercent] 
FROM	DB_CPU 
WHERE	DatabaseID > 4 -- system databases 
	AND DatabaseID <> 32767 -- ResourceDB 
ORDER BY SNO OPTION(RECOMPILE); 



/**	Script: SQL Server CPU Utilization report from last N minutes **/
/***	Output: 
	SQLServer_CPU_Utilization: % CPU utilized from SQL Server Process
	System_Idle_Process: % CPU Idle - Not serving to any process 
	Other_Process_CPU_Utilization: % CPU utilized by processes otherthan SQL Server
	Event_Time: Time when these values captured
***/
 
DECLARE @ts BIGINT;
DECLARE @lastNmin TINYINT;
SET @lastNmin = 180;
SELECT @ts =(SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info); 
SELECT TOP(@lastNmin) SQLProcessUtilization AS [SQLServer_CPU_Utilization], SystemIdle AS [System_Idle_Process], 100 - SystemIdle - SQLProcessUtilization AS [Other_Process_CPU_Utilization], DATEADD(ms,-1 *(@ts - [timestamp]),GETDATE())AS [Event_Time] 
FROM (SELECT record.value('(./Record/@id)[1]','int')AS record_id, 
record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]','int')AS [SystemIdle], 
record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','int')AS [SQLProcessUtilization], 
[timestamp]      
FROM (SELECT[timestamp], convert(xml, record) AS [record]             
FROM sys.dm_os_ring_buffers             
WHERE ring_buffer_type =N'RING_BUFFER_SCHEDULER_MONITOR'AND record LIKE'%%')AS x )AS y 
ORDER BY record_id DESC;


/**	Script: Top 10 queries that causes high CPU Utilization **/
/**	Output: All query related details **/
/**	Note: This script returns list of costly queries when CPU utilization is >=80% from last 10 min ***/
 
SET NOCOUNT ON
DECLARE @ts_now bigint 
DECLARE @AvgCPUUtilization DECIMAL(10,2) 
 
SELECT @ts_now = cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info
 
-- load the CPU utilization in the past 10 minutes into the temp table, you can load them into a permanent table
SELECT TOP(10) SQLProcessUtilization AS [SQLServerProcessCPUUtilization]
,SystemIdle AS [SystemIdleProcess]
,100 - SystemIdle - SQLProcessUtilization AS [OtherProcessCPU Utilization]
,DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [EventTime] 
INTO #CPUUtilization
FROM ( 
      SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
            AS [SystemIdle], 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
            'int') 
            AS [SQLProcessUtilization], [timestamp] 
      FROM ( 
            SELECT [timestamp], CONVERT(xml, record) AS [record] 
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
            AND record LIKE '%<SystemHealth>%') AS x 
      ) AS y 
ORDER BY record_id DESC
 
 
-- check if the average CPU utilization was over 80% in the past 10 minutes
SELECT @AvgCPUUtilization = AVG([SQLServerProcessCPUUtilization] + [OtherProcessCPU Utilization])
FROM #CPUUtilization
WHERE EventTime > DATEADD(MM, -10, GETDATE())
 
IF @AvgCPUUtilization >= 80
BEGIN
	SELECT TOP(10)
		CONVERT(VARCHAR(25),@AvgCPUUtilization) +'%' AS [AvgCPUUtilization]
		, GETDATE() [Date and Time]
		, r.cpu_time
		, r.total_elapsed_time
		, s.session_id
		, s.login_name
		, s.host_name
		, DB_NAME(r.database_id) AS DatabaseName
		, SUBSTRING (t.text,(r.statement_start_offset/2) + 1,
		((CASE WHEN r.statement_end_offset = -1
			THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2
			ELSE r.statement_end_offset
		END - r.statement_start_offset)/2) + 1) AS [IndividualQuery]
		, SUBSTRING(text, 1, 200) AS [ParentQuery]
		, r.status
		, r.start_time
		, r.wait_type
		, s.program_name
	INTO #PossibleCPUUtilizationQueries		
	FROM sys.dm_exec_sessions s
	INNER JOIN sys.dm_exec_connections c ON s.session_id = c.session_id
	INNER JOIN sys.dm_exec_requests r ON c.connection_id = r.connection_id
	CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
	WHERE s.session_id > 50
		AND r.session_id != @@spid
	order by r.cpu_time desc
	
	-- query the temp table, you can also send an email report to yourself or your development team
	SELECT *
	FROM #PossibleCPUUtilizationQueries		
END
 
-- drop the temp tables
IF OBJECT_ID('TEMPDB..#CPUUtilization') IS NOT NULL
drop table #CPUUtilization
 
IF OBJECT_ID('TEMPDB..#PossibleCPUUtilizationQueries') IS NOT NULL
drop table #PossibleCPUUtilizationQueries








