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


