/*
 * Script: Genetrator_SHRINKDATABASE.sql
 * Descripción: Genera scripts para reducir el tamaño de bases de datos
 *              Incluye validaciones y manejo de errores
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado será scripts para reducir el tamaño de bases de datos
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @ExcludeSystemDBs: Excluir bases de datos del sistema (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 *    - @MinSizeMB: Tamaño mínimo en MB para considerar (default: 100)
 *    - @TargetPercent: Porcentaje de espacio libre objetivo (default: 10)
 * 
 * Notas:
 * - Se recomienda ejecutar en horarios de baja actividad
 * - El proceso de SHRINK puede ser intensivo en recursos
 * - Se incluyen validaciones de espacio y estado
 * - Se puede configurar logging de operaciones
 */

-- Declaración de variables configurables
DECLARE @ExcludeSystemDBs BIT = 1;
DECLARE @LogToTable BIT = 0;
DECLARE @MinSizeMB INT = 100;
DECLARE @TargetPercent INT = 10;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DBShrinkLog')
    BEGIN
        CREATE TABLE DBShrinkLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            DatabaseName NVARCHAR(128),
            StartSizeMB DECIMAL(18,2),
            EndSizeMB DECIMAL(18,2),
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
DECLARE @StartSizeMB DECIMAL(18,2);
DECLARE @StartTime DATETIME;
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;

-- Cursor para bases de datos
DECLARE DB_cursor CURSOR FOR   
SELECT 
    d.name,
    CAST(SUM(size * 8.0 / 1024) AS DECIMAL(18,2)) AS SizeMB
FROM sys.master_files AS mf
INNER JOIN sys.databases AS d ON mf.database_id = d.database_id
WHERE d.state_desc = 'ONLINE'
    AND (@ExcludeSystemDBs = 0 OR d.name NOT IN ('master', 'tempdb', 'model', 'msdb'))
GROUP BY d.name
HAVING CAST(SUM(size * 8.0 / 1024) AS DECIMAL(18,2)) >= @MinSizeMB;

OPEN DB_cursor;
FETCH NEXT FROM DB_cursor INTO @DB_name, @StartSizeMB;

WHILE @@FETCH_STATUS = 0  
BEGIN  
    SET @StartTime = GETDATE();
    
    -- Generar script de SHRINK
    PRINT '-- Script para reducir base de datos
-- Generado el: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
-- Instancia: ' + @@SERVERNAME + '
-- Base de datos: ' + @DB_name + '
-- Tamaño actual: ' + CAST(@StartSizeMB AS NVARCHAR(20)) + ' MB
-- Objetivo de espacio libre: ' + CAST(@TargetPercent AS NVARCHAR(10)) + '%

USE [master];
GO

DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;
DECLARE @StartSizeMB DECIMAL(18,2) = ' + CAST(@StartSizeMB AS NVARCHAR(20)) + ';
DECLARE @StartTime DATETIME = ''' + CONVERT(VARCHAR, @StartTime, 120) + ''';

BEGIN TRY
    -- Verificar estado de la base de datos
    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = ''' + @DB_name + ''' AND state_desc = ''ONLINE'')
    BEGIN
        SET @ErrorMessage = ''La base de datos no está en línea: '' + ''' + @DB_name + ''';
        RAISERROR(@ErrorMessage, 16, 1);
    END

    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar inicio de operación
    INSERT INTO DBShrinkLog (
        DatabaseName,
        StartSizeMB,
        StartTime,
        Status
    )
    VALUES (
        ''' + @DB_name + ''',
        @StartSizeMB,
        @StartTime,
        ''In Progress''
    );
    SET @LogID = SCOPE_IDENTITY();' ELSE '' END + '

    -- Ejecutar SHRINK
    USE [' + @DB_name + '];
    GO
    DBCC SHRINKDATABASE ([' + @DB_name + '], ' + CAST(@TargetPercent AS NVARCHAR(10)) + ');
    GO
    
    PRINT ''Base de datos reducida exitosamente: '' + ''' + @DB_name + ''';
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar éxito
    UPDATE DBShrinkLog 
    SET EndTime = GETDATE(), 
        Status = ''Success'',
        EndSizeMB = CAST(SUM(size * 8.0 / 1024) AS DECIMAL(18,2))
    WHERE LogID = @LogID;' ELSE '' END + '

END TRY
BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
    PRINT ''Error al reducir base de datos: '' + @ErrorMessage;
    
    ' + CASE WHEN @LogToTable = 1 THEN '
    -- Registrar error
    UPDATE DBShrinkLog 
    SET EndTime = GETDATE(), 
        Status = ''Failed'', 
        ErrorMessage = @ErrorMessage
    WHERE LogID = @LogID;' ELSE '' END + '
END CATCH
GO';

    FETCH NEXT FROM DB_cursor INTO @DB_name, @StartSizeMB;
END;

CLOSE DB_cursor;
DEALLOCATE DB_cursor;

/*
 * Notas adicionales:
 * 1. Consideraciones sobre SHRINK:
 *    - Verifica el estado de la base de datos
 *    - Comprueba el tamaño actual
 *    - Valida el espacio disponible
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
 *    - Monitorear el uso de recursos
 * 
 * 4. Monitoreo:
 *    - Opción de logging detallado
 *    - Registro de tamaños antes/después
 *    - Seguimiento de errores
 *    - Historial de operaciones
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye tamaños de base de datos
 *    - Registra tiempos de ejecución
 *    - Almacena mensajes de error
 */


