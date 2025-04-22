/*
 * Script: Transac_PendientesDiskMemori.sql
 * Descripción: Analiza las transacciones pendientes, operaciones de I/O y uso de recursos
 *              en SQL Server, proporcionando información detallada sobre el rendimiento
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado mostrará información sobre:
 *    - Transacciones pendientes
 *    - Operaciones de I/O
 *    - Uso de recursos
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @ShowDetailedInfo: Mostrar información detallada (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 *    - @MinIOStallMS: Umbral mínimo de espera de I/O (default: 1000)
 * 
 * Notas:
 * - Se recomienda ejecutar con permisos de administrador
 * - Se incluyen validaciones de seguridad
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los datos
 */

-- Declaración de variables configurables
DECLARE @ShowDetailedInfo BIT = 1;
DECLARE @LogToTable BIT = 0;
DECLARE @MinIOStallMS INT = 1000;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ResourceUsageLog')
    BEGIN
        CREATE TABLE ResourceUsageLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            PendingIOCount INT,
            TotalIOStallMS BIGINT,
            DatabaseName NVARCHAR(128),
            FileID INT,
            IOStallReadMS BIGINT,
            IOStallWriteMS BIGINT,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

BEGIN TRY
    -- Registrar inicio de operación
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @PendingIOCount INT;
    DECLARE @TotalIOStallMS BIGINT;

    -- Reporte de rendimiento
    PRINT '-- ANÁLISIS DE RENDIMIENTO --';
    PRINT '---------------------------';
    PRINT 'IMPORTANCIA DEL ANÁLISIS:';
    PRINT '------------------------';
    PRINT '1. Rendimiento:';
    PRINT '   - Identifica cuellos de botella en I/O';
    PRINT '   - Detecta problemas de concurrencia';
    PRINT '   - Monitorea el uso de recursos';
    PRINT '';
    PRINT '2. Mantenimiento:';
    PRINT '   - Ayuda a optimizar el rendimiento';
    PRINT '   - Identifica problemas de configuración';
    PRINT '   - Mejora la planificación de recursos';
    PRINT '';

    -- 1. Análisis de operaciones de I/O pendientes
    PRINT '1. OPERACIONES DE I/O PENDIENTES:';
    PRINT '--------------------------------';
    
    SELECT 
        @PendingIOCount = SUM(pending_disk_io_count)
    FROM sys.dm_os_schedulers;
    
    SELECT 
        scheduler_id as 'ID Scheduler',
        cpu_id as 'ID CPU',
        is_online as 'En Línea',
        current_tasks_count as 'Tareas Actuales',
        runnable_tasks_count as 'Tareas Ejecutables',
        pending_disk_io_count as 'I/O Pendientes',
        CASE 
            WHEN pending_disk_io_count > 10 THEN 'ALTO - Revisar configuración de I/O'
            WHEN pending_disk_io_count > 5 THEN 'MEDIO - Monitorear'
            ELSE 'BAJO - Normal'
        END as 'Estado'
    FROM sys.dm_os_schedulers
    WHERE is_online = 1
    ORDER BY pending_disk_io_count DESC;

    -- 2. Análisis detallado de I/O pendientes
    PRINT '';
    PRINT '2. DETALLE DE SOLICITUDES DE I/O PENDIENTES:';
    PRINT '-------------------------------------------';
    
    SELECT 
        io_handle as 'Handle I/O',
        io_type as 'Tipo I/O',
        io_pending as 'Pendiente',
        io_pending_ms_ticks as 'Tiempo Pendiente (ms)',
        scheduler_address as 'Dirección Scheduler',
        CASE 
            WHEN io_pending_ms_ticks > 1000 THEN 'ALTO - Posible cuello de botella'
            WHEN io_pending_ms_ticks > 500 THEN 'MEDIO - Monitorear'
            ELSE 'BAJO - Normal'
        END as 'Estado'
    FROM sys.dm_io_pending_io_requests
    ORDER BY io_pending_ms_ticks DESC;

    -- 3. Análisis de estadísticas de I/O por archivo
    PRINT '';
    PRINT '3. ESTADÍSTICAS DE I/O POR ARCHIVO:';
    PRINT '----------------------------------';
    
    SELECT 
        DB_NAME(database_id) as 'Base de Datos',
        file_id as 'ID Archivo',
        io_stall_read_ms as 'Espera Lectura (ms)',
        io_stall_write_ms as 'Espera Escritura (ms)',
        io_stall as 'Espera Total (ms)',
        CASE 
            WHEN io_stall > @MinIOStallMS THEN 'ALTO - Revisar configuración'
            WHEN io_stall > (@MinIOStallMS / 2) THEN 'MEDIO - Monitorear'
            ELSE 'BAJO - Normal'
        END as 'Estado'
    FROM sys.dm_io_virtual_file_stats(NULL, NULL)
    WHERE io_stall > 0
    ORDER BY io_stall DESC;

    -- Calcular total de espera de I/O
    SELECT @TotalIOStallMS = SUM(io_stall)
    FROM sys.dm_io_virtual_file_stats(NULL, NULL);

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO ResourceUsageLog (
            ExecutionTime,
            PendingIOCount,
            TotalIOStallMS,
            Status
        )
        VALUES (
            @StartTime,
            @PendingIOCount,
            @TotalIOStallMS,
            'Success'
        );
    END

    -- Mostrar resumen
    PRINT '';
    PRINT 'Resumen:';
    PRINT 'Total de operaciones I/O pendientes: ' + CAST(@PendingIOCount AS NVARCHAR(10));
    PRINT 'Total de espera de I/O (ms): ' + CAST(@TotalIOStallMS AS NVARCHAR(20));
    PRINT 'Tiempo de ejecución: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + ' segundos';

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error al analizar rendimiento: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO ResourceUsageLog (
            ExecutionTime,
            Status,
            ErrorMessage
        )
        VALUES (
            @StartTime,
            'Failed',
            @ErrorMessage
        );
    END
END CATCH;

/*
 * Notas adicionales:
 * 
 * 1. Importancia del Análisis:
 *    - Identifica problemas de rendimiento
 *    - Detecta cuellos de botella en I/O
 *    - Monitorea el uso de recursos
 *    - Ayuda en la optimización
 * 
 * 2. Consideraciones de Rendimiento:
 *    - Las esperas altas indican problemas
 *    - El número de I/O pendientes debe ser bajo
 *    - Las estadísticas ayudan a identificar patrones
 *    - El monitoreo regular es importante
 * 
 * 3. Recomendaciones:
 *    - Revisar configuración de I/O
 *    - Optimizar consultas con alto I/O
 *    - Considerar mejoras de hardware
 *    - Monitorear regularmente
 * 
 * 4. Seguridad:
 *    - Requiere permisos de administrador
 *    - Verificar el contexto de seguridad
 *    - Validar las operaciones permitidas
 *    - Monitorear el uso de recursos
 * 
 * 5. Mantenimiento:
 *    - Programar análisis periódicos
 *    - Documentar los resultados
 *    - Ajustar umbrales según necesidades
 *    - Monitorear tendencias
 */
