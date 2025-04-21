/*
 * Script: GenerarScriptRECOVERY SIMPLE.sql
 * Descripción: Genera scripts para configurar el modelo de recuperación SIMPLE en bases de datos
 *              Excluye bases de datos del sistema y permite configuración personalizada
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado será un script que se puede ejecutar para configurar RECOVERY SIMPLE
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @ExcludeSystemDBs: Excluir bases de datos del sistema (default: 1)
 *    - @IncludeDBList: Lista de bases de datos específicas a incluir (default: NULL)
 *    - @ExcludeDBList: Lista de bases de datos específicas a excluir (default: NULL)
 *    - @BackupBeforeChange: Realizar backup antes del cambio (default: 0)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 * 
 * Notas:
 * - RECOVERY SIMPLE limita las opciones de recuperación
 * - Se recomienda ejecutar en horarios de baja actividad
 * - Se incluyen validaciones de estado y configuración actual
 * - Se puede configurar backup previo y logging
 */

-- Declaración de variables configurables
DECLARE @ExcludeSystemDBs BIT = 1;
DECLARE @IncludeDBList NVARCHAR(MAX) = NULL; -- Ejemplo: 'DB1,DB2,DB3'
DECLARE @ExcludeDBList NVARCHAR(MAX) = NULL; -- Ejemplo: 'DB4,DB5,DB6'
DECLARE @BackupBeforeChange BIT = 0;
DECLARE @LogToTable BIT = 0;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DBRecoveryModelLog')
    BEGIN
        CREATE TABLE DBRecoveryModelLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            DatabaseName NVARCHAR(128),
            PreviousModel NVARCHAR(20),
            NewModel NVARCHAR(20),
            StartTime DATETIME,
            EndTime DATETIME,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX),
            BackupPath NVARCHAR(500)
        );
    END
END

-- Generar script para configurar RECOVERY SIMPLE
SELECT '-- Script para configurar RECOVERY SIMPLE
-- Generado el: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
-- Instancia: ' + @@SERVERNAME + '

USE master;
GO

-- Declarar variables locales
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @BackupPath NVARCHAR(500);
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;
DECLARE @PreviousModel NVARCHAR(20);

-- Verificar estado actual y configurar RECOVERY SIMPLE
IF EXISTS (
    SELECT 1 
    FROM sys.databases 
    WHERE name = ''' + name + ''' 
    AND recovery_model_desc <> ''SIMPLE''
    AND state = 0
)
BEGIN
    PRINT ''Procesando base de datos: ' + name + ''';
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar inicio de operación
    SELECT @PreviousModel = recovery_model_desc 
    FROM sys.databases 
    WHERE name = ''' + name + ''';
    
    INSERT INTO DBRecoveryModelLog (
        DatabaseName, 
        PreviousModel, 
        NewModel, 
        StartTime, 
        Status
    )
    VALUES (
        ''' + name + ''', 
        @PreviousModel, 
        ''SIMPLE'', 
        @StartTime, 
        ''In Progress''
    );
    SET @LogID = SCOPE_IDENTITY();' ELSE '' END + '

    ' + CASE WHEN @BackupBeforeChange = 1 THEN '
    -- Realizar backup antes del cambio
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
        UPDATE DBRecoveryModelLog 
        SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
        WHERE LogID = @LogID;' ELSE '' END + '
        GOTO NextDB;
    END CATCH' ELSE '' END + '

    -- Intentar cambiar el modelo de recuperación
    BEGIN TRY
        ALTER DATABASE [' + name + '] 
        SET RECOVERY SIMPLE 
        WITH NO_WAIT;
        PRINT ''    - Modelo de recuperación cambiado exitosamente'';
        ' + CASE WHEN @LogToTable = 1 THEN '
        UPDATE DBRecoveryModelLog 
        SET EndTime = GETDATE(), Status = ''Success'', BackupPath = @BackupPath
        WHERE LogID = @LogID;' ELSE '' END + '
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ''Error al cambiar modelo de recuperación: '' + ERROR_MESSAGE();
        PRINT ''    - '' + @ErrorMessage;
        ' + CASE WHEN @LogToTable = 1 THEN '
        UPDATE DBRecoveryModelLog 
        SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
        WHERE LogID = @LogID;' ELSE '' END + '
    END CATCH
END
ELSE
BEGIN
    SET @ErrorMessage = ''La base de datos ' + name + ' ya está en modo SIMPLE o no está disponible'';
    PRINT @ErrorMessage;
    ' + CASE WHEN @LogToTable = 1 THEN '
    INSERT INTO DBRecoveryModelLog (
        DatabaseName, 
        PreviousModel, 
        NewModel, 
        StartTime, 
        EndTime, 
        Status, 
        ErrorMessage
    )
    VALUES (
        ''' + name + ''', 
        ''SIMPLE'', 
        ''SIMPLE'', 
        @StartTime, 
        GETDATE(), 
        ''Skipped'', 
        @ErrorMessage
    );' ELSE '' END + '
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
 * 1. Consideraciones sobre RECOVERY SIMPLE:
 *    - No permite recuperación a un punto en el tiempo
 *    - Reduce el tamaño del log de transacciones
 *    - Ideal para bases de datos de desarrollo o testing
 *    - No recomendado para bases de datos de producción críticas
 * 
 * 2. Seguridad:
 *    - Requiere permisos ALTER DATABASE y BACKUP DATABASE
 *    - Verifica el estado de la base de datos antes de actuar
 *    - Incluye manejo de errores para cada operación
 *    - Permite backup previo al cambio
 * 
 * 3. Uso recomendado:
 *    - Ejecutar en horarios de baja actividad
 *    - Realizar backup antes del cambio
 *    - Verificar el impacto en las aplicaciones
 *    - Monitorear el tamaño del log de transacciones
 * 
 * 4. Monitoreo:
 *    - Verificar el modelo de recuperación después del cambio
 *    - Monitorear crecimiento del log de transacciones
 *    - Revisar estadísticas de rendimiento
 *    - Considerar reorganización de índices si es necesario
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye modelo de recuperación anterior y nuevo
 *    - Registra tiempos de inicio y fin
 *    - Almacena ruta de backup si se realiza
 */

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