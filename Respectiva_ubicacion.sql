/*
 * Script: Respectiva_ubicacion.sql
 * Descripción: Script para analizar y gestionar la ubicación de archivos de bases de datos
 * Autor: v1kt0r-Am0n
 * Fecha: 2024
 * Versión: 1.1
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. Los resultados mostrarán:
 *    - Información detallada de archivos
 *    - Bases de datos offline
 *    - Scripts para mover archivos
 *    - Recomendaciones de ubicación
 * 
 * Notas:
 * - Requiere permisos de administrador
 * - Verificar espacio disponible antes de mover archivos
 * - Hacer backup antes de realizar cambios
 * - Considerar el impacto en el rendimiento
 */

-- Configuración de parámetros
DECLARE @ShowDetailedInfo BIT = 1;                    -- 1 para mostrar información detallada
DECLARE @IncludeSystemDBs BIT = 0;                    -- 1 para incluir bases de datos del sistema
DECLARE @MinSizeMB INT = 100;                         -- Tamaño mínimo para mostrar
DECLARE @NewDataPath NVARCHAR(256) = 'H:\DATA.DBDESASQLCLU1\';  -- Nueva ruta para archivos de datos
DECLARE @NewLogPath NVARCHAR(256) = 'F:\LOG.DBDESASQLCLU1\';    -- Nueva ruta para archivos de log

-- 1. Información detallada de todas las bases de datos
IF @ShowDetailedInfo = 1
BEGIN
    PRINT '-- Información detallada de bases de datos';
    PRINT '-- Incluye tamaño, ubicación y estado';
    PRINT '';

    SELECT 
        d.database_id,
        d.name AS [Base_Datos],
        a.name AS [Nombre_Archivo],
        a.physical_name AS [Ubicación_Física],
        a.type_desc AS [Tipo_Archivo],
        CAST(a.size * 8.0 / 1024 AS DECIMAL(10,2)) AS [Tamaño_MB],
        CAST(a.size * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS [Tamaño_GB],
        d.recovery_model_desc AS [Modelo_Recuperación],
        d.state_desc AS [Estado],
        d.compatibility_level AS [Nivel_Compatibilidad],
        CASE 
            WHEN a.size * 8.0 / 1024 > 1024 THEN 'GRANDE'
            WHEN a.size * 8.0 / 1024 > 100 THEN 'MEDIANO'
            ELSE 'PEQUEÑO'
        END AS [Clasificación_Tamaño]
    FROM sys.master_files a 
    INNER JOIN sys.databases d ON a.database_id = d.database_id
    WHERE (@IncludeSystemDBs = 1 OR d.database_id > 4)
        AND a.size * 8.0 / 1024 >= @MinSizeMB
    ORDER BY a.type_desc, a.size DESC;
END

-- 2. Bases de datos offline
PRINT '';
PRINT '-- Bases de datos offline';
PRINT '-- Requieren atención para restaurar';
PRINT '';

SELECT 
    d.database_id,
    d.name AS [Base_Datos],
    a.name AS [Nombre_Archivo],
    a.physical_name AS [Ubicación_Actual],
    a.type_desc AS [Tipo_Archivo],
    CAST(a.size * 8.0 / 1024 AS DECIMAL(10,2)) AS [Tamaño_MB],
    d.recovery_model_desc AS [Modelo_Recuperación],
    d.state_desc AS [Estado]
FROM sys.master_files a 
INNER JOIN sys.databases d ON a.database_id = d.database_id
WHERE d.state_desc = 'OFFLINE'
ORDER BY a.physical_name;

-- 3. Scripts para mover archivos de datos
PRINT '';
PRINT '-- Scripts para mover archivos de datos';
PRINT '-- Ejecutar con precaución y después de hacer backup';
PRINT '';

SELECT 
    '-- Mover archivo de datos de ' + d.name + CHAR(13) +
    'MOVE "' + a.physical_name + '" TO "' + 
    @NewDataPath + d.name + '.mdf"' AS [Script_Mover_Datos]
FROM sys.master_files a 
INNER JOIN sys.databases d ON a.database_id = d.database_id
WHERE d.state_desc = 'OFFLINE' 
    AND a.type_desc = 'ROWS'
ORDER BY a.physical_name;

-- 4. Scripts para mover archivos de log
PRINT '';
PRINT '-- Scripts para mover archivos de log';
PRINT '-- Ejecutar con precaución y después de hacer backup';
PRINT '';

SELECT 
    '-- Mover archivo de log de ' + d.name + CHAR(13) +
    'MOVE "' + a.physical_name + '" TO "' + 
    @NewLogPath + a.name + '.ldf"' AS [Script_Mover_Log]
FROM sys.master_files a 
INNER JOIN sys.databases d ON a.database_id = d.database_id
WHERE d.state_desc = 'OFFLINE' 
    AND a.type_desc = 'LOG'
ORDER BY a.physical_name;

-- 5. Script para adjuntar base de datos
PRINT '';
PRINT '-- Script para adjuntar base de datos';
PRINT '-- Ajustar nombres y rutas según necesidad';
PRINT '';

SELECT 
    'USE [master]' + CHAR(13) +
    'GO' + CHAR(13) +
    'CREATE DATABASE [' + d.name + '] ON' + CHAR(13) +
    '( FILENAME = N''' + @NewDataPath + d.name + '.mdf'' ),' + CHAR(13) +
    '( FILENAME = N''' + @NewLogPath + a.name + '.ldf'' )' + CHAR(13) +
    'FOR ATTACH' + CHAR(13) +
    'GO' AS [Script_Adjuntar_DB]
FROM sys.master_files a 
INNER JOIN sys.databases d ON a.database_id = d.database_id
WHERE d.state_desc = 'OFFLINE'
    AND a.type_desc = 'ROWS'
ORDER BY d.name;

/*
 * Notas adicionales:
 * 
 * 1. Consideraciones de rendimiento:
 *    - Separar archivos de datos y log en diferentes discos
 *    - Considerar el tamaño de los archivos
 *    - Monitorear el espacio disponible
 *    - Planificar el crecimiento
 * 
 * 2. Recomendaciones:
 *    - Hacer backup antes de mover archivos
 *    - Verificar permisos de acceso
 *    - Probar en ambiente de desarrollo
 *    - Documentar cambios realizados
 * 
 * 3. Pasos para mover archivos:
 *    - Hacer backup completo
 *    - Desconectar la base de datos
 *    - Mover archivos físicamente
 *    - Adjuntar la base de datos
 *    - Verificar integridad
 * 
 * 4. Monitoreo:
 *    - Verificar espacio en disco
 *    - Comprobar rendimiento
 *    - Revisar logs de error
 *    - Validar backups
 */
