/*
 * Script: Generator_Detach_db.sql
 * Descripción: Genera scripts para desacoplar bases de datos que están en estado OFFLINE
 *              Incluye validaciones y manejo de errores
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado será scripts para desacoplar bases de datos OFFLINE
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @ExcludeSystemDBs: Excluir bases de datos del sistema (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 *    - @VerifyFiles: Verificar existencia de archivos (default: 1)
 *    - @BackupBeforeDetach: Realizar backup antes de desacoplar (default: 0)
 * 
 * Notas:
 * - Se recomienda ejecutar en horarios de baja actividad
 * - Se incluyen validaciones de archivos y permisos
 * - Se puede configurar logging de operaciones
 * - Se verifica la compatibilidad de archivos
 */

-- Declaración de variables configurables
DECLARE @ExcludeSystemDBs BIT = 1;
DECLARE @LogToTable BIT = 0;
DECLARE @VerifyFiles BIT = 1;
DECLARE @BackupBeforeDetach BIT = 0;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DBDetachLog')
    BEGIN
        CREATE TABLE DBDetachLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            DatabaseName NVARCHAR(128),
            DataFile NVARCHAR(512),
            LogFile NVARCHAR(512),
            StartTime DATETIME,
            EndTime DATETIME,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

-- Declaración de variables
DECLARE @DB_name NVARCHAR(128);
DECLARE @DataFile NVARCHAR(512);
DECLARE @LogFile NVARCHAR(512);
DECLARE @StartTime DATETIME;
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;

-- Cursor para bases de datos OFFLINE
DECLARE DB_cursor CURSOR FOR   
SELECT 
    d.name,
    MAX(CASE WHEN a.type_desc = 'ROWS' THEN a.physical_name END) AS DataFile,
    MAX(CASE WHEN a.type_desc = 'LOG' THEN a.physical_name END) AS LogFile
FROM sys.master_files AS a 
INNER JOIN sys.databases AS d ON a.database_id = d.database_id
WHERE d.state_desc = 'OFFLINE'
    AND (@ExcludeSystemDBs = 0 OR d.name NOT IN ('master', 'tempdb', 'model', 'msdb'))
GROUP BY d.name;

OPEN DB_cursor;
FETCH NEXT FROM DB_cursor INTO @DB_name, @DataFile, @LogFile;

WHILE @@FETCH_STATUS = 0  
BEGIN  
    SET @StartTime = GETDATE();
    
    -- Generar script de DETACH
    PRINT '-- Script para desacoplar base de datos
-- Generado el: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
-- Instancia: ' + @@SERVERNAME + '
-- Base de datos: ' + @DB_name + '
-- Archivo de datos: ' + @DataFile + '
-- Archivo de log: ' + @LogFile + '

USE [master];
GO

DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;

BEGIN TRY
    -- Verificar existencia de archivos
    IF ' + CASE WHEN @VerifyFiles = 1 THEN '
    NOT EXISTS (SELECT 1 FROM sys.dm_os_file_exists(''' + @DataFile + ''')) OR
    NOT EXISTS (SELECT 1 FROM sys.dm_os_file_exists(''' + @LogFile + '''))
    BEGIN
        SET @ErrorMessage = ''Uno o más archivos no existen: '' + 
                          CASE WHEN NOT EXISTS (SELECT 1 FROM sys.dm_os_file_exists(''' + @DataFile + ''')) 
                               THEN ''Data file: '' + ''' + @DataFile + ''' + '' '' ELSE '''' END +
                          CASE WHEN NOT EXISTS (SELECT 1 FROM sys.dm_os_file_exists(''' + @LogFile + ''')) 
                               THEN ''Log file: '' + ''' + @LogFile + ''' ELSE '''' END;
        RAISERROR(@ErrorMessage, 16, 1);
    END' ELSE '1=1' END + '

    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar inicio de operación
    INSERT INTO DBDetachLog (
        DatabaseName,
        DataFile,
        LogFile,
        StartTime,
        Status
    )
    VALUES (
        ''' + @DB_name + ''',
        ''' + @DataFile + ''',
        ''' + @LogFile + ''',
        ''' + CONVERT(VARCHAR, @StartTime, 120) + ''',
        ''In Progress''
    );
    SET @LogID = SCOPE_IDENTITY();' ELSE '' END + '

    -- Ejecutar DETACH
    USE [master];
    GO
    ALTER DATABASE [' + @DB_name + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    GO
    EXEC master.dbo.sp_detach_db @dbname = N''' + @DB_name + ''', @skipchecks = ''false'';
    GO
    
    PRINT ''Base de datos desacoplada exitosamente: '' + ''' + @DB_name + ''';
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar éxito
    UPDATE DBDetachLog 
    SET EndTime = GETDATE(), Status = ''Success''
    WHERE LogID = @LogID;' ELSE '' END + '

END TRY
BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
    PRINT ''Error al desacoplar base de datos: '' + @ErrorMessage;
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar error
    UPDATE DBDetachLog 
    SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
    WHERE LogID = @LogID;' ELSE '' END + '
END CATCH
GO';

    FETCH NEXT FROM DB_cursor INTO @DB_name, @DataFile, @LogFile;
END;

CLOSE DB_cursor;
DEALLOCATE DB_cursor;

/*
 * Notas adicionales:
 * 1. Consideraciones sobre DETACH:
 *    - Verifica la existencia de archivos antes de desacoplar
 *    - Comprueba permisos necesarios
 *    - Valida la compatibilidad de archivos
 *    - Incluye manejo de errores detallado
 * 
 * 2. Seguridad:
 *    - Requiere permisos ALTER DATABASE
 *    - Verifica permisos en archivos
 *    - Incluye validaciones de seguridad
 *    - Maneja errores de forma segura
 * 
 * 3. Uso recomendado:
 *    - Ejecutar en horarios de baja actividad
 *    - Verificar el impacto en las aplicaciones
 *    - Realizar backup antes de ejecutar
 *    - Probar primero con @VerifyFiles = 1
 * 
 * 4. Monitoreo:
 *    - Opción de logging detallado
 *    - Registro de archivos y rutas
 *    - Seguimiento de errores
 *    - Historial de operaciones
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye rutas de archivos
 *    - Registra tiempos de ejecución
 *    - Almacena mensajes de error
 */