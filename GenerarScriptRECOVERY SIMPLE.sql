USE [master]
GO


SELECT 'ALTER DATABASE [' + name +'] SET RECOVERY SIMPLE WITH NO_WAIT;'
FROM sys.databases   
where name not in (
'master',
'tempdb',
'model',
'msdb');
GO  