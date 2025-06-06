/*
 * Script: Reducir_log_transacciones.sql
 * Descripción: Script para reducir el tamaño de archivos LDF (logs de transacciones)
 * Autor: v1kt0r-Am0n
 * Fecha: 2024
 * Versión: 1.1
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. Los resultados mostrarán:
 *    - Scripts de reducción para cada archivo de log
 *    - Información detallada de logs
 *    - Recomendaciones de reducción
 * 
 * Notas:
 * - Requiere permisos de administrador
 * - Se recomienda hacer backup antes de ejecutar
 * - La reducción puede afectar el rendimiento
 * - Verificar espacio disponible antes de ejecutar
 * - Asegurarse de que no hay transacciones activas largas
 */

-- Configuración de parámetros
DECLARE @TargetSizeMB INT = 1;             -- Tamaño objetivo en MB
DECLARE @IncludeSystemDBs BIT = 0;         -- 1 para incluir bases de datos del sistema
DECLARE @MinSizeMB INT = 10;               -- Tamaño mínimo para considerar reducción
DECLARE @ShowDetailedInfo BIT = 1;         -- 1 para mostrar información detallada
DECLARE @GenerateScripts BIT = 1;          -- 1 para generar scripts de reducción
DECLARE @CheckVLF BIT = 1;                 -- 1 para verificar VLFs

-- Información de archivos de log
IF @ShowDetailedInfo = 1
BEGIN
    SELECT 
        d.name AS [Base_Datos],
        m.name AS [Nombre_Archivo_Log],
        m.type_desc AS [Tipo_Archivo],
        CAST(m.size * 8.0 / 1024 AS DECIMAL(10,2)) AS [Tamaño_Actual_MB],
        CAST(m.size * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS [Tamaño_Actual_GB],
        CAST(FILEPROPERTY(m.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(10,2)) AS [Espacio_Usado_MB],
        CAST((m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(10,2)) AS [Espacio_Libre_MB],
        CAST(((m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 100.0 / m.size) AS DECIMAL(5,2)) AS [Porcentaje_Libre],
        m.physical_name AS [Ruta_Física],
        d.recovery_model_desc AS [Modelo_Recuperación],
        CASE 
            WHEN (m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 8.0 / 1024 > @MinSizeMB 
            THEN 'RECOMENDADO'
            ELSE 'NO RECOMENDADO'
        END AS [Reducción_Recomendada]
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE (@IncludeSystemDBs = 1 OR d.database_id > 4)
        AND m.type_desc = 'LOG'
        AND m.name LIKE '%log%'
    ORDER BY [Espacio_Libre_MB] DESC;
END

-- Verificar VLFs si está habilitado
IF @CheckVLF = 1
BEGIN
    PRINT '-- Información de VLFs por base de datos';
    PRINT '-- Un número alto de VLFs puede afectar el rendimiento';
    PRINT '';

    SELECT 
        DB_NAME(database_id) AS [Base_Datos],
        COUNT(*) AS [Número_VLFs],
        CASE 
            WHEN COUNT(*) > 100 THEN 'ALTO - Considerar reducción'
            WHEN COUNT(*) > 50 THEN 'MEDIO - Monitorear'
            ELSE 'BAJO - OK'
        END AS [Estado_VLFs]
    FROM sys.dm_db_log_info(NULL)
    WHERE (@IncludeSystemDBs = 1 OR database_id > 4)
    GROUP BY database_id
    ORDER BY [Número_VLFs] DESC;
END

-- Generar scripts de reducción
IF @GenerateScripts = 1
BEGIN
    PRINT '-- Scripts de reducción de logs de transacciones';
    PRINT '-- Ejecutar con precaución y después de hacer backup';
    PRINT '-- Asegurarse de que no hay transacciones activas largas';
    PRINT '';

    -- Script para reducción de logs
    SELECT 
        '-- Reducción de log de ' + d.name + ' a ' + CAST(@TargetSizeMB AS VARCHAR) + ' MB' + CHAR(13) +
        'USE [' + d.name + '];' + CHAR(13) +
        '-- Verificar espacio usado antes' + CHAR(13) +
        'DBCC LOGINFO;' + CHAR(13) +
        '-- Reducir el archivo de log' + CHAR(13) +
        'DBCC SHRINKFILE ([' + m.name + '], ' + CAST(@TargetSizeMB AS VARCHAR) + ');' + CHAR(13) +
        '-- Verificar espacio usado después' + CHAR(13) +
        'DBCC LOGINFO;' + CHAR(13) +
        'GO' + CHAR(13)
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE (@IncludeSystemDBs = 1 OR d.database_id > 4)
        AND m.type_desc = 'LOG'
        AND m.name LIKE '%log%'
        AND (m.size * 8.0 / 1024) > @MinSizeMB
    ORDER BY d.name;

    -- Script para verificar y limpiar logs
    PRINT '';
    PRINT '-- Scripts para verificar y limpiar logs';
    PRINT '';

    SELECT 
        '-- Limpieza de log de ' + d.name + CHAR(13) +
        'USE [' + d.name + '];' + CHAR(13) +
        '-- Verificar estado del log' + CHAR(13) +
        'DBCC LOGINFO;' + CHAR(13) +
        '-- Forzar punto de control' + CHAR(13) +
        'CHECKPOINT;' + CHAR(13) +
        '-- Reducir el archivo de log' + CHAR(13) +
        'DBCC SHRINKFILE ([' + m.name + '], ' + CAST(@TargetSizeMB AS VARCHAR) + ');' + CHAR(13) +
        'GO' + CHAR(13)
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE (@IncludeSystemDBs = 1 OR d.database_id > 4)
        AND m.type_desc = 'LOG'
        AND m.name LIKE '%log%'
        AND (m.size * 8.0 / 1024) > @MinSizeMB
    ORDER BY d.name;
END

/*
 * Notas adicionales:
 * 
 * 1. Consideraciones de rendimiento:
 *    - La reducción puede causar fragmentación
 *    - Puede afectar el rendimiento durante la operación
 *    - Se recomienda ejecutar en horarios de baja carga
 * 
 * 2. Recomendaciones:
 *    - Hacer backup antes de ejecutar
 *    - Verificar transacciones activas
 *    - Monitorear el proceso
 *    - Revisar el número de VLFs
 * 
 * 3. Tipos de reducción:
 *    - Reducción a tamaño específico
 *    - Limpieza y reducción
 *    - Verificación de VLFs
 * 
 * 4. Monitoreo:
 *    - Verificar el espacio liberado
 *    - Comprobar el número de VLFs
 *    - Revisar el rendimiento
 *    - Monitorear el crecimiento
 */

