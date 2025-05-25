/*
 * Script: ReducirLog.sql
 * Descripción: Script para reducir el tamaño de archivos de log cambiando temporalmente el modelo de recuperación
 * Autor: v1kt0r-Am0n
 * Fecha: 2024
 * Versión: 1.1
 * 
 * Uso:
 * 1. Configurar los parámetros al inicio del script
 * 2. Ejecutar el script en la instancia de SQL Server
 * 3. El script realizará:
 *    - Backup del log antes de la operación
 *    - Cambio temporal a modelo SIMPLE
 *    - Reducción del log
 *    - Restauración del modelo original
 * 
 * Notas:
 * - Requiere permisos de administrador
 * - Se recomienda hacer backup completo antes de ejecutar
 * - La operación puede afectar el rendimiento
 * - Verificar espacio disponible antes de ejecutar
 * - Asegurarse de que no hay transacciones activas largas
 */

-- Configuración de parámetros
DECLARE @DatabaseName NVARCHAR(128) = 'nombre_base';    -- Nombre de la base de datos
DECLARE @LogFileName NVARCHAR(128) = 'nombre_base_log'; -- Nombre del archivo de log
DECLARE @TargetSizeMB INT = 1;                          -- Tamaño objetivo en MB
DECLARE @BackupLog BIT = 1;                             -- 1 para hacer backup del log antes
DECLARE @BackupPath NVARCHAR(256) = 'C:\Backups\';      -- Ruta para backups
DECLARE @ShowDetailedInfo BIT = 1;                      -- 1 para mostrar información detallada

-- Validar que la base de datos existe
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName)
BEGIN
    RAISERROR('La base de datos %s no existe.', 16, 1, @DatabaseName);
    RETURN;
END

-- Validar que el archivo de log existe
IF NOT EXISTS (
    SELECT 1 
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE d.name = @DatabaseName 
    AND m.name = @LogFileName
    AND m.type_desc = 'LOG'
)
BEGIN
    RAISERROR('El archivo de log %s no existe en la base de datos %s.', 16, 1, @LogFileName, @DatabaseName);
    RETURN;
END

-- Mostrar información detallada si está habilitado
IF @ShowDetailedInfo = 1
BEGIN
    SELECT 
        d.name AS [Base_Datos],
        d.recovery_model_desc AS [Modelo_Recuperación_Actual],
        m.name AS [Nombre_Archivo_Log],
        CAST(m.size * 8.0 / 1024 AS DECIMAL(10,2)) AS [Tamaño_Actual_MB],
        CAST(FILEPROPERTY(m.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(10,2)) AS [Espacio_Usado_MB],
        CAST((m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(10,2)) AS [Espacio_Libre_MB],
        m.physical_name AS [Ruta_Física]
    FROM sys.master_files m
    INNER JOIN sys.databases d ON m.database_id = d.database_id
    WHERE d.name = @DatabaseName
    AND m.name = @LogFileName;
END

-- Guardar el modelo de recuperación actual
DECLARE @CurrentRecoveryModel NVARCHAR(60);
SELECT @CurrentRecoveryModel = recovery_model_desc 
FROM sys.databases 
WHERE name = @DatabaseName;

-- Hacer backup del log si está habilitado
IF @BackupLog = 1
BEGIN
    DECLARE @BackupFileName NVARCHAR(256) = @BackupPath + @DatabaseName + '_Log_' + 
        REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR, GETDATE(), 120), ':', ''), '-', ''), ' ', '_') + '.trn';
    
    PRINT '-- Realizando backup del log...';
    BACKUP LOG @DatabaseName TO DISK = @BackupFileName WITH INIT;
    PRINT '-- Backup del log completado: ' + @BackupFileName;
END

-- Cambiar a modelo SIMPLE
PRINT '-- Cambiando a modelo de recuperación SIMPLE...';
ALTER DATABASE @DatabaseName SET RECOVERY SIMPLE;
GO

-- Reducir el archivo de log
PRINT '-- Reduciendo archivo de log...';
DBCC SHRINKFILE (@LogFileName, @TargetSizeMB);
GO

-- Restaurar el modelo de recuperación original
PRINT '-- Restaurando modelo de recuperación original...';
ALTER DATABASE @DatabaseName SET RECOVERY @CurrentRecoveryModel;
GO

-- Verificar el resultado
PRINT '-- Verificando resultado de la operación...';
SELECT 
    d.name AS [Base_Datos],
    d.recovery_model_desc AS [Modelo_Recuperación_Final],
    m.name AS [Nombre_Archivo_Log],
    CAST(m.size * 8.0 / 1024 AS DECIMAL(10,2)) AS [Tamaño_Final_MB],
    CAST(FILEPROPERTY(m.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(10,2)) AS [Espacio_Usado_MB],
    CAST((m.size - FILEPROPERTY(m.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(10,2)) AS [Espacio_Libre_MB]
FROM sys.master_files m
INNER JOIN sys.databases d ON m.database_id = d.database_id
WHERE d.name = @DatabaseName
AND m.name = @LogFileName;

/*
 * Notas adicionales:
 * 
 * 1. Consideraciones de rendimiento:
 *    - La reducción puede causar fragmentación
 *    - Puede afectar el rendimiento durante la operación
 *    - Se recomienda ejecutar en horarios de baja carga
 * 
 * 2. Recomendaciones:
 *    - Hacer backup completo antes de ejecutar
 *    - Verificar transacciones activas
 *    - Monitorear el proceso
 *    - Revisar el espacio liberado
 * 
 * 3. Pasos realizados:
 *    - Backup del log (si está habilitado)
 *    - Cambio a modelo SIMPLE
 *    - Reducción del log
 *    - Restauración del modelo original
 * 
 * 4. Monitoreo:
 *    - Verificar el espacio liberado
 *    - Comprobar el modelo de recuperación
 *    - Revisar el rendimiento
 *    - Monitorear el crecimiento
 */
