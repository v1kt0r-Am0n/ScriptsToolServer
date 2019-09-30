USE master
DECLARE curkillproc
CURSOR FOR
SELECT spid,dbs.name AS dbname
FROM master..sysprocesses pro, master..sysdatabases dbs
WHERE pro.dbid = dbs.dbid
AND dbs.name = 'SCICentralesDeRiesgo'
FOR READ ONLY 
DECLARE @varspid AS integer
DECLARE @vardbname AS varchar(256)
DECLARE @numUsers AS integer
SET @numUsers = 0
OPEN curkillproc
FETCH NEXT FROM curkillproc
INTO @varspid, @vardbname
WHILE @@fetch_status = 0
BEGIN
EXEC('kill ' + @varspid)
SET @numUsers = @numUsers + 1
FETCH NEXT FROM curkillproc INTO @varspid, @vardbname
END
CLOSE curkillproc
DEALLOCATE curkillproc
SELECT @numUsers as NumUsersDisconnected


SELECT * FROM sys.server_principals where type='S'
and name not in ('guest','INFORMATION_SCHEMA','sys')



USE [CMC_COBRANZAS]
GO
CREATE USER [UsrSCILocal] FOR LOGIN [UsrSCILocal]
GO
USE [CMC_COBRANZAS]
GO
ALTER ROLE [db_owner] ADD MEMBER [UsrSCILocal]
GO





USE [PRODCreditos]
GO
CREATE USER [CREDIVALORES\flopez] FOR LOGIN [CREDIVALORES\flopez]
GO
USE [PRODCreditos]
GO
ALTER ROLE [db_owner] ADD MEMBER [CREDIVALORES\flopez]
GO
