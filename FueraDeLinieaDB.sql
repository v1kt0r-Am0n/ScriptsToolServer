--Primero ponemos la BD en modo monousuario.
--Usamos el par�metro ROLLBACK IMMEDIATE para que se ejecute de immediato.

USE master;
GO	
ALTER DATABASE Nombre_base
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE Nombre_base
SET OFFLINE;
GO

--Si queremos devolver al estado inicial (multiusuario y en l�nea) usamos los siguientes comandos:
USE master;
GO	
ALTER DATABASE Nombre_base
SET ONLINE;
GO
ALTER DATABASE Nombre_base
SET MULTI_USER;
GO

---Generar script para la instancia
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