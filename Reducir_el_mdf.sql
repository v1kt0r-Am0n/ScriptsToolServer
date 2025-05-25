/*
 * Script: Reducir_el_mdf.sql
 * Descripción: Script para reducir el tamaño de archivos MDF de bases de datos
 * Autor: v1kt0r-Am0n
 * Fecha: 2024
 * Versión: 1.1
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. Los resultados mostrarán:
 *    - Scripts de reducción para cada base de datos
 *    - Información detallada de archivos
 *    - Recomendaciones de reducción
 * 
 * Notas:
 * - Requiere permisos de administrador
 * - Se recomienda hacer backup antes de ejecutar
 * - La reducción puede afectar el rendimiento
 * - Verificar espacio disponible antes de ejecutar
 */

-- Configuración de parámetros
DECLARE @TargetPercent INT = 10;           -- Porcentaje objetivo de espacio libre
DECLARE @IncludeSystemDBs BIT = 0;         -- 1 para incluir bases de datos del sistema
DECLARE @MinSizeMB INT = 100;              -- Tamaño mínimo para considerar reducción
DECLARE @ShowDetailedInfo BIT = 1;         -- 1 para mostrar información detallada
DECLARE @GenerateScripts BIT = 1;          -- 1 para generar scripts de reducción

-- Información de archivos de base de datos
IF @ShowDetailedInfo = 1
BEGIN
    SELECT 
        d.name AS [Base_Datos],
        m.name AS [Nombre_Archivo],
        m.type_desc AS [Tipo_Archivo],
        CAST(m.size * 8.0 / 1024 AS DECIMAL(10,2)) AS [Tamaño_Actual_MB],
        CAST(m.size * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS [Tamaño_Actual_GB],
        CAST(FILEPROPERTY(m.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(10,2)) AS [Espacio_Usado_MB],
        CAST((m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(10,2)) AS [Espacio_Libre_MB],
        CAST(((m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 100.0 / m.size) AS DECIMAL(5,2)) AS [Porcentaje_Libre],
        m.physical_name AS [Ruta_Física],
        CASE 
            WHEN (m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 8.0 / 1024 > @MinSizeMB 
            THEN 'RECOMENDADO'
            ELSE 'NO RECOMENDADO'
        END AS [Reducción_Recomendada]
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE (@IncludeSystemDBs = 1 OR d.database_id > 4)
        AND m.type_desc = 'ROWS'
    ORDER BY [Espacio_Libre_MB] DESC;
END

-- Generar scripts de reducción
IF @GenerateScripts = 1
BEGIN
    PRINT '-- Scripts de reducción de bases de datos';
    PRINT '-- Ejecutar con precaución y después de hacer backup';
    PRINT '';

    -- Script para reducción con porcentaje objetivo
    SELECT 
        '-- Reducción de ' + d.name + ' al ' + CAST(@TargetPercent AS VARCHAR) + '% de espacio libre' + CHAR(13) +
        'USE [' + d.name + '];' + CHAR(13) +
        'DBCC SHRINKDATABASE ([' + d.name + '], ' + CAST(@TargetPercent AS VARCHAR) + ');' + CHAR(13) +
        'GO' + CHAR(13)
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE (@IncludeSystemDBs = 1 OR d.database_id > 4)
        AND m.type_desc = 'ROWS'
        AND (m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 8.0 / 1024 > @MinSizeMB
    GROUP BY d.name;

    PRINT '';
    PRINT '-- Scripts de reducción TRUNCATEONLY (solo espacio no utilizado)';
    PRINT '';

    -- Script para reducción TRUNCATEONLY
    SELECT 
        '-- Reducción TRUNCATEONLY de ' + d.name + CHAR(13) +
        'USE [' + d.name + '];' + CHAR(13) +
        'DBCC SHRINKDATABASE ([' + d.name + '], TRUNCATEONLY);' + CHAR(13) +
        'GO' + CHAR(13)
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE (@IncludeSystemDBs = 1 OR d.database_id > 4)
        AND m.type_desc = 'ROWS'
        AND m.data_space_id = 1
        AND (m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 8.0 / 1024 > @MinSizeMB
    GROUP BY d.name;
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
 *    - Verificar espacio en disco
 *    - Monitorear el proceso
 *    - Reconstruir índices después
 * 
 * 3. Tipos de reducción:
 *    - Porcentaje: Reduce al espacio especificado
 *    - TRUNCATEONLY: Solo elimina espacio no utilizado
 * 
 * 4. Monitoreo:
 *    - Verificar el espacio liberado
 *    - Comprobar la fragmentación
 *    - Revisar el rendimiento
 */