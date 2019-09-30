SELECT 'DBCC SHRINKDATABASE ([' +name +'], TRUNCATEONLY);  '
FROM sys.databases   
where name not in (
'master',
'tempdb',
'model',
'msdb');
GO  


