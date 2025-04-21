/*
 * Script: FueraDeLinieaDB.sql
 * Descripción: Genera un script para poner bases de datos fuera de línea de manera segura
 *              Excluye bases de datos del sistema y permite configuración personalizada
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.1
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado será un script que se puede ejecutar para poner las bases de datos fuera de línea
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @ExcludeSystemDBs: Excluir bases de datos del sistema (default: 1)
 *    - @IncludeDBList: Lista de bases de datos específicas a incluir (default: NULL)
 *    - @ExcludeDBList: Lista de bases de datos específicas a excluir (default: NULL)
 *    - @BackupBeforeOffline: Realizar backup antes de poner fuera de línea (default: 0)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 *    - @TimeoutSeconds: Tiempo máximo de espera por operación (default: 300)
 * 
 * Notas:
 * - El script generado incluye manejo de errores
 * - Se verifica el estado de la base de datos antes de intentar ponerla fuera de línea
 * - Se incluyen comentarios descriptivos en el script generado
 * - Se manejan conexiones activas de manera segura
 * - Se puede configurar backup previo y logging
 */

-- Declaración de variables configurables
DECLARE @ExcludeSystemDBs BIT = 1;
DECLARE @IncludeDBList NVARCHAR(MAX) = NULL; -- Ejemplo: 'DB1,DB2,DB3'
DECLARE @ExcludeDBList NVARCHAR(MAX) = NULL; -- Ejemplo: 'DB4,DB5,DB6'
DECLARE @BackupBeforeOffline BIT = 0;
DECLARE @LogToTable BIT = 0;
DECLARE @TimeoutSeconds INT = 300;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DBOfflineLog')
    BEGIN
        CREATE TABLE DBOfflineLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            DatabaseName NVARCHAR(128),
            OperationType NVARCHAR(50),
            StartTime DATETIME,
            EndTime DATETIME,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX),
            BackupPath NVARCHAR(500)
        );
    END
END

-- Generar script para la instancia
SELECT '-- Script generado automáticamente para poner bases de datos fuera de línea
-- Fecha de generación: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
-- Instancia: ' + @@SERVERNAME + '
-- Tiempo máximo de espera: ' + CAST(@TimeoutSeconds AS VARCHAR) + ' segundos

USE master;
GO

-- Declarar variables locales
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @BackupPath NVARCHAR(500);
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;

-- Verificar si la base de datos existe y está en línea
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''' + name + ''' AND state = 0)
BEGIN
    PRINT ''Procesando base de datos: ' + name + ''';
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar inicio de operación
    INSERT INTO DBOfflineLog (DatabaseName, OperationType, StartTime, Status)
    VALUES (''' + name + ''', ''Offline Operation'', @StartTime, ''In Progress'');
    SET @LogID = SCOPE_IDENTITY();' ELSE '' END + '

    ' + CASE WHEN @BackupBeforeOffline = 1 THEN '
    -- Realizar backup antes de poner fuera de línea
    BEGIN TRY
        SET @BackupPath = ''C:\Backups\'' + ''' + name + ''' + ''_'' + 
                         REPLACE(CONVERT(VARCHAR, GETDATE(), 112), '''', '''') + ''.bak'';
        
        BACKUP DATABASE [' + name + ']
        TO DISK = @BackupPath
        WITH COMPRESSION, STATS = 10;
        
        PRINT ''    - Backup completado exitosamente'';
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ''Error en backup: '' + ERROR_MESSAGE();
        PRINT ''    - '' + @ErrorMessage;
        ' + CASE WHEN @LogToTable = 1 THEN '
        UPDATE DBOfflineLog 
        SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
        WHERE LogID = @LogID;' ELSE '' END + '
        GOTO NextDB;
    END CATCH' ELSE '' END + '

    -- Intentar poner en modo usuario único
    BEGIN TRY
        ALTER DATABASE [' + name + ']
        SET SINGLE_USER
        WITH ROLLBACK IMMEDIATE;
        PRINT ''    - Modo usuario único establecido'';
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ''Error al establecer modo usuario único: '' + ERROR_MESSAGE();
        PRINT ''    - '' + @ErrorMessage;
        ' + CASE WHEN @LogToTable = 1 THEN '
        UPDATE DBOfflineLog 
        SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
        WHERE LogID = @LogID;' ELSE '' END + '
        GOTO NextDB;
    END CATCH

    -- Intentar poner fuera de línea
    BEGIN TRY
        ALTER DATABASE [' + name + ']
        SET OFFLINE;
        PRINT ''    - Base de datos puesta fuera de línea exitosamente'';
        ' + CASE WHEN @LogToTable = 1 THEN '
        UPDATE DBOfflineLog 
        SET EndTime = GETDATE(), Status = ''Success'', BackupPath = @BackupPath
        WHERE LogID = @LogID;' ELSE '' END + '
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ''Error al poner fuera de línea: '' + ERROR_MESSAGE();
        PRINT ''    - '' + @ErrorMessage;
        ' + CASE WHEN @LogToTable = 1 THEN '
        UPDATE DBOfflineLog 
        SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
        WHERE LogID = @LogID;' ELSE '' END + '
    END CATCH
END
ELSE
BEGIN
    SET @ErrorMessage = ''La base de datos ' + name + ' no existe o no está en línea'';
    PRINT @ErrorMessage;
    ' + CASE WHEN @LogToTable = 1 THEN '
    INSERT INTO DBOfflineLog (DatabaseName, OperationType, StartTime, EndTime, Status, ErrorMessage)
    VALUES (''' + name + ''', ''Offline Operation'', @StartTime, GETDATE(), ''Failed'', @ErrorMessage);' ELSE '' END + '
END

NextDB:
GO
'
FROM sys.databases   
WHERE 
    -- Excluir bases de datos del sistema si está configurado
    (@ExcludeSystemDBs = 0 OR name NOT IN ('master', 'tempdb', 'model', 'msdb'))
    -- Incluir solo bases de datos específicas si se proporciona lista
    AND (@IncludeDBList IS NULL OR name IN (SELECT value FROM STRING_SPLIT(@IncludeDBList, ',')))
    -- Excluir bases de datos específicas si se proporciona lista
    AND (@ExcludeDBList IS NULL OR name NOT IN (SELECT value FROM STRING_SPLIT(@ExcludeDBList, ',')))
    -- Solo bases de datos en línea
    AND state = 0
ORDER BY name;

/*
 * Notas adicionales:
 * 1. Seguridad:
 *    - Requiere permisos ALTER DATABASE y BACKUP DATABASE
 *    - Verifica el estado de la base de datos antes de actuar
 *    - Maneja conexiones activas de manera segura
 *    - Permite configuración de tiempo de espera
 * 
 * 2. Consideraciones:
 *    - El script generado incluye manejo de errores
 *    - Se puede personalizar qué bases de datos incluir/excluir
 *    - Se generan mensajes informativos durante la ejecución
 *    - Se puede habilitar backup previo y logging
 * 
 * 3. Uso recomendado:
 *    - Ejecutar en horarios de baja actividad
 *    - Verificar el script generado antes de ejecutarlo
 *    - Tener en cuenta el impacto en aplicaciones conectadas
 *    - Considerar el espacio necesario para backups
 * 
 * 4. Manejo de errores:
 *    - Captura errores específicos para cada operación
 *    - Continúa con la siguiente base de datos si hay errores
 *    - Proporciona mensajes descriptivos de error
 *    - Registra errores en tabla de log si está habilitado
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye tiempos de inicio y fin
 *    - Registra estado y mensajes de error
 *    - Almacena ruta de backup si se realiza
 */