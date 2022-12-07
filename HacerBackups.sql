-- El nombre del fichero tendrá este Formato DB_YYYYDDMM.BAK 

DECLARE @name VARCHAR(50) -- Nombre de la Base de Datos
DECLARE @path VARCHAR(256) -- Ruta para las copias de seguridad
DECLARE @fileName VARCHAR(256) -- Nombre del Fichero
DECLARE @fileDate VARCHAR(20) -- Usado para el nombre del fichero

-- Ruta para las copias de seguridad
SET @path = 'B:\Backups\' -- Formato del nombre del fichero
SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) -- excluir estas bases datos
DECLARE db_cursor CURSOR FOR SELECT name FROM master.dbo.sysdatabases WHERE name NOT IN ('master','model','msdb','tempdb')

OPEN db_cursor FETCH NEXT FROM db_cursor INTO @name 

WHILE @@FETCH_STATUS = 0
BEGIN
SET @fileName = @path + @name + '_' + @fileDate + '.BAK'
BACKUP DATABASE @name TO DISK = @fileName
FETCH NEXT FROM db_cursor INTO @name
END
CLOSE db_cursor
DEALLOCATE db_cursor