--Primero ponemos la BD en modo monousuario.
--Usamos el parámetro ROLLBACK IMMEDIATE para que se ejecute de immediato.

USE master;
GO	
ALTER DATABASE CapaMedia_V2
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE CapaMedia_V2
SET OFFLINE;
GO

--Si queremos devolver al estado inicial (multiusuario y en línea) usamos los siguientes comandos:
USE master;
GO	
ALTER DATABASE CapaMedia_V2
SET ONLINE;
GO
ALTER DATABASE CapaMedia_V2
SET MULTI_USER;
GO


SELECT ' 
USE master;
GO	
ALTER DATABASE ' + name + '
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE ' + name + '
SET OFFLINE;
GO'


FROM sys.databases   
where name not in (
'master',
'tempdb',
'model',
'msdb');