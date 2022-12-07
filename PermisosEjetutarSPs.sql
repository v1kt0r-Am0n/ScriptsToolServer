
--- por DB --------------
CREATE ROLE db_executor;
GRANT EXECUTE TO db_executor;


----generator script all database----
SELECT 'USE ['+ name +']  CREATE ROLE db_executor;  GRANT EXECUTE TO db_executor;'
FROM sys.databases   
where name not in (
'master',
'tempdb',
'model',
'msdb')
order by 1;
GO  


