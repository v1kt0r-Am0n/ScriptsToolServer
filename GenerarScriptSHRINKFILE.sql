/*
 * Script: GenerarScriptSHRINKFILE.sql
 * Descripción: Genera scripts para reducir el tamaño de archivos de base de datos
 *              Incluye opciones para archivos de datos y logs
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado será scripts para reducir archivos de base de datos
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @MinSizeMB: Tamaño mínimo para considerar reducción (default: 10)
 *    - @TargetSizeMB: Tamaño objetivo para reducir (default: 0)
 *    - @ExcludeSystemDBs: Excluir bases de datos del sistema (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 *    - @OperationType: Tipo de operación (1: SHRINKFILE, 2: SHRINKDATABASE)
 * 
 * Notas:
 * - Se recomienda ejecutar en horarios de baja actividad
 * - SHRINK puede causar fragmentación
 * - Se incluyen validaciones de estado y tamaño
 * - Se puede configurar logging de operaciones
 */

-- Declaración de variables configurables
DECLARE @MinSizeMB INT = 10;
DECLARE @TargetSizeMB INT = 0;
DECLARE @ExcludeSystemDBs BIT = 1;
DECLARE @LogToTable BIT = 0;
DECLARE @OperationType INT = 1; -- 1: SHRINKFILE, 2: SHRINKDATABASE

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DBShrinkLog')
    BEGIN
        CREATE TABLE DBShrinkLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            DatabaseName NVARCHAR(128),
            FileName NVARCHAR(128),
            FileType NVARCHAR(20),
            PreviousSizeMB DECIMAL(10,2),
            TargetSizeMB DECIMAL(10,2),
            StartTime DATETIME,
            EndTime DATETIME,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

-- Generar script para SHRINKFILE
IF @OperationType = 1
BEGIN
    SELECT '-- Script para reducir archivo de base de datos
-- Generado el: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
-- Instancia: ' + @@SERVERNAME + '
-- Base de datos: ' + d.name + '
-- Archivo: ' + m.name + '
-- Tamaño actual: ' + CAST((m.size * 8 / 1024) AS VARCHAR) + ' MB

USE [' + d.name + '];
GO

DECLARE @StartTime DATETIME = GETDATE();
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;
DECLARE @CurrentSizeMB DECIMAL(10,2) = ' + CAST((m.size * 8 / 1024) AS VARCHAR) + ';
DECLARE @TargetSizeMB DECIMAL(10,2) = ' + CAST(@TargetSizeMB AS VARCHAR) + ';

BEGIN TRY
    -- Verificar estado de la base de datos
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.databases 
        WHERE name = ''' + d.name + ''' 
        AND state = 0
    )
    BEGIN
        SET @ErrorMessage = ''Base de datos no disponible: '' + ''' + d.name + ''';
        RAISERROR(@ErrorMessage, 16, 1);
    END

    -- Verificar tamaño actual
    IF @CurrentSizeMB <= ' + CAST(@MinSizeMB AS VARCHAR) + '
    BEGIN
        SET @ErrorMessage = ''Tamaño actual ('' + CAST(@CurrentSizeMB AS VARCHAR) + '' MB) menor que mínimo requerido (' + CAST(@MinSizeMB AS VARCHAR) + ' MB)'';
        RAISERROR(@ErrorMessage, 16, 1);
    END

    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar inicio de operación
    INSERT INTO DBShrinkLog (
        DatabaseName,
        FileName,
        FileType,
        PreviousSizeMB,
        TargetSizeMB,
        StartTime,
        Status
    )
    VALUES (
        ''' + d.name + ''',
        ''' + m.name + ''',
        ''' + CASE WHEN m.type = 0 THEN ''Data'' ELSE ''Log'' END + ''',
        @CurrentSizeMB,
        @TargetSizeMB,
        @StartTime,
        ''In Progress''
    );
    SET @LogID = SCOPE_IDENTITY();' ELSE '' END + '

    -- Ejecutar SHRINKFILE
    DBCC SHRINKFILE (N''' + m.name + ''', ' + CAST(@TargetSizeMB AS VARCHAR) + ');
    
    PRINT ''Archivo reducido exitosamente: '' + ''' + m.name + ''' + 
          '' ('' + CAST(@CurrentSizeMB AS VARCHAR) + '' MB -> '' + CAST(@TargetSizeMB AS VARCHAR) + '' MB)'';
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar éxito
    UPDATE DBShrinkLog 
    SET EndTime = GETDATE(), Status = ''Success''
    WHERE LogID = @LogID;' ELSE '' END + '

END TRY
BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
    PRINT ''Error al reducir archivo: '' + @ErrorMessage;
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar error
    UPDATE DBShrinkLog 
    SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
    WHERE LogID = @LogID;' ELSE '' END + '
END CATCH
GO'
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE 
        -- Excluir bases de datos del sistema si está configurado
        (@ExcludeSystemDBs = 0 OR d.name NOT IN ('master', 'tempdb', 'model', 'msdb'))
        -- Solo archivos de log o datos según configuración
        AND (
            (m.type = 1 AND m.name LIKE '%log%') OR
            (m.type = 0 AND m.physical_name LIKE '%mdf%')
        )
        -- Solo archivos mayores al tamaño mínimo
        AND (m.size * 8 / 1024) > @MinSizeMB
    ORDER BY d.name, m.name;
END
ELSE
BEGIN
    -- Generar script para SHRINKDATABASE
    SELECT '-- Script para reducir base de datos
-- Generado el: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
-- Instancia: ' + @@SERVERNAME + '
-- Base de datos: ' + d.name + '
-- Tamaño actual: ' + CAST((SUM(m.size) * 8 / 1024) AS VARCHAR) + ' MB

USE [' + d.name + '];
GO

DECLARE @StartTime DATETIME = GETDATE();
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;
DECLARE @CurrentSizeMB DECIMAL(10,2) = ' + CAST((SUM(m.size) * 8 / 1024) AS VARCHAR) + ';
DECLARE @TargetSizeMB DECIMAL(10,2) = ' + CAST(@TargetSizeMB AS VARCHAR) + ';

BEGIN TRY
    -- Verificar estado de la base de datos
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.databases 
        WHERE name = ''' + d.name + ''' 
        AND state = 0
    )
    BEGIN
        SET @ErrorMessage = ''Base de datos no disponible: '' + ''' + d.name + ''';
        RAISERROR(@ErrorMessage, 16, 1);
    END

    -- Verificar tamaño actual
    IF @CurrentSizeMB <= ' + CAST(@MinSizeMB AS VARCHAR) + '
    BEGIN
        SET @ErrorMessage = ''Tamaño actual ('' + CAST(@CurrentSizeMB AS VARCHAR) + '' MB) menor que mínimo requerido (' + CAST(@MinSizeMB AS VARCHAR) + ' MB)'';
        RAISERROR(@ErrorMessage, 16, 1);
    END

    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar inicio de operación
    INSERT INTO DBShrinkLog (
        DatabaseName,
        FileName,
        FileType,
        PreviousSizeMB,
        TargetSizeMB,
        StartTime,
        Status
    )
    VALUES (
        ''' + d.name + ''',
        ''ALL'',
        ''Database'',
        @CurrentSizeMB,
        @TargetSizeMB,
        @StartTime,
        ''In Progress''
    );
    SET @LogID = SCOPE_IDENTITY();' ELSE '' END + '

    -- Ejecutar SHRINKDATABASE
    DBCC SHRINKDATABASE (N''' + d.name + ''', ' + CAST(@TargetSizeMB AS VARCHAR) + ');
    
    PRINT ''Base de datos reducida exitosamente: '' + ''' + d.name + ''' + 
          '' ('' + CAST(@CurrentSizeMB AS VARCHAR) + '' MB -> '' + CAST(@TargetSizeMB AS VARCHAR) + '' MB)'';
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar éxito
    UPDATE DBShrinkLog 
    SET EndTime = GETDATE(), Status = ''Success''
    WHERE LogID = @LogID;' ELSE '' END + '

END TRY
BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
    PRINT ''Error al reducir base de datos: '' + @ErrorMessage;
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar error
    UPDATE DBShrinkLog 
    SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
    WHERE LogID = @LogID;' ELSE '' END + '
END CATCH
GO'
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE 
        -- Excluir bases de datos del sistema si está configurado
        (@ExcludeSystemDBs = 0 OR d.name NOT IN ('master', 'tempdb', 'model', 'msdb'))
        -- Solo archivos de datos
        AND m.type = 0
        AND m.physical_name LIKE '%mdf%'
    GROUP BY d.name
    HAVING SUM(m.size * 8 / 1024) > @MinSizeMB
    ORDER BY d.name;
END

/*
 * Notas adicionales:
 * 1. Consideraciones sobre SHRINK:
 *    - Puede causar fragmentación de índices
 *    - Afecta el rendimiento durante la operación
 *    - El espacio liberado vuelve al sistema operativo
 *    - Se recomienda reorganizar índices después
 * 
 * 2. Seguridad:
 *    - Requiere permisos ALTER DATABASE
 *    - Verifica el estado de la base de datos
 *    - Incluye manejo de errores
 *    - Valida tamaños antes de operar
 * 
 * 3. Uso recomendado:
 *    - Ejecutar en horarios de baja actividad
 *    - Monitorear el impacto en el rendimiento
 *    - Realizar backup antes de ejecutar
 *    - Considerar reorganización de índices
 * 
 * 4. Monitoreo:
 *    - Opción de logging detallado
 *    - Registro de tamaños antes y después
 *    - Seguimiento de errores
 *    - Historial de operaciones
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye tamaños y tipos de archivo
 *    - Registra tiempos de ejecución
 *    - Almacena mensajes de error
 */

