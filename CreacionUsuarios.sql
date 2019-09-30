
USE [master]
GO
--genera script por base y usuario
SELECT 'CREATE LOGIN [UsrDB' + name +'] WITH PASSWORD=N''P4$$W0rdDB.'', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF'
FROM sys.databases   
where name not in (
'master',
'tempdb',
'model',
'msdb');
GO 



USE [AppMovilAutenticacion]
GO
CREATE USER [UsrDBAppMovilAutenticacion] FOR LOGIN [UsrDBAppMovilAutenticacion]
GO
USE [AppMovilAutenticacion]
GO
ALTER ROLE [db_datareader] ADD MEMBER [UsrDBAppMovilAutenticacion]
GO
USE [AppMovilAutenticacion]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [UsrDBAppMovilAutenticacion]
GO


SELECT '
USE [' + name +']
GO
CREATE USER [UsrDB' + name +']  FOR LOGIN [UsrDB' + name +'] 
GO
USE [' + name +']
GO
ALTER ROLE [db_datareader] ADD MEMBER [UsrDB' + name +'] 
GO
USE [AppMovilAutenticacion]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [UsrDB' + name +'] 
GO
'
FROM sys.databases   
where name not in (
'master',
'tempdb',
'model',
'msdb');
GO 