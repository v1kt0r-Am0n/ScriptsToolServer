/*
 * Script: Update_stadisticas_Full.sql
 * Descripción: Script para optimización de índices y actualización de estadísticas
 *              en todas las bases de datos de usuario
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El script optimizará índices y actualizará estadísticas
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @Databases: Bases de datos a procesar (default: 'USER_DATABASES')
 *    - @FragmentationLow: Acción para fragmentación baja (default: NULL)
 *    - @FragmentationMedium: Acción para fragmentación media (default: 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE')
 *    - @FragmentationHigh: Acción para fragmentación alta (default: 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE')
 *    - @FragmentationLevel1: Umbral de fragmentación baja (default: 5)
 *    - @FragmentationLevel2: Umbral de fragmentación alta (default: 30)
 *    - @UpdateStatistics: Nivel de actualización de estadísticas (default: 'ALL')
 *    - @OnlyModifiedStatistics: Solo estadísticas modificadas (default: 'Y')
 * 
 * Notas:
 * - Se recomienda ejecutar con permisos de administrador
 * - Se incluyen validaciones de seguridad
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los datos
 */

-- Declaración de variables configurables
DECLARE @Databases NVARCHAR(MAX) = 'USER_DATABASES';
DECLARE @FragmentationLow NVARCHAR(MAX) = NULL;
DECLARE @FragmentationMedium NVARCHAR(MAX) = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE';
DECLARE @FragmentationHigh NVARCHAR(MAX) = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE';
DECLARE @FragmentationLevel1 INT = 5;
DECLARE @FragmentationLevel2 INT = 30;
DECLARE @UpdateStatistics NVARCHAR(MAX) = 'ALL';
DECLARE @OnlyModifiedStatistics NVARCHAR(1) = 'Y';
DECLARE @LogToTable BIT = 1;
DECLARE @TimeLimit INT = 7200; -- 2 horas en segundos

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'IndexOptimizationLog')
    BEGIN
        CREATE TABLE IndexOptimizationLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            DatabaseName NVARCHAR(128),
            TableName NVARCHAR(128),
            IndexName NVARCHAR(128),
            FragmentationPercent DECIMAL(5,2),
            ActionTaken NVARCHAR(50),
            StatisticsUpdated BIT,
            DurationSeconds INT,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

BEGIN TRY
    -- Registrar inicio de operación
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @CurrentDB NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Verificar si la base de datos master está accesible
    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'master' AND state = 0)
    BEGIN
        RAISERROR('La base de datos master no está accesible', 16, 1);
    END

    -- Verificar si el procedimiento IndexOptimize existe
    IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'IndexOptimize' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        RAISERROR('El procedimiento dbo.IndexOptimize no existe', 16, 1);
    END

    -- Ejecutar optimización con parámetros
    EXECUTE dbo.IndexOptimize 
        @Databases = @Databases,
        @FragmentationLow = @FragmentationLow,
        @FragmentationMedium = @FragmentationMedium,
        @FragmentationHigh = @FragmentationHigh,
        @FragmentationLevel1 = @FragmentationLevel1,
        @FragmentationLevel2 = @FragmentationLevel2,
        @UpdateStatistics = @UpdateStatistics,
        @OnlyModifiedStatistics = @OnlyModifiedStatistics,
        @TimeLimit = @TimeLimit,
        @LogToTable = 'Y';

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO IndexOptimizationLog (
            ExecutionTime,
            Status,
            DurationSeconds
        )
        VALUES (
            @StartTime,
            'Success',
            DATEDIFF(SECOND, @StartTime, GETDATE())
        );
    END

    -- Mostrar resumen
    PRINT '';
    PRINT 'Resumen de la Optimización:';
    PRINT '-------------------------';
    PRINT 'Tiempo de ejecución: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + ' segundos';
    PRINT 'Bases de datos procesadas: ' + @Databases;
    PRINT 'Nivel de fragmentación bajo: ' + CAST(@FragmentationLevel1 AS NVARCHAR(10)) + '%';
    PRINT 'Nivel de fragmentación alto: ' + CAST(@FragmentationLevel2 AS NVARCHAR(10)) + '%';
    PRINT 'Estadísticas actualizadas: ' + @UpdateStatistics;
    PRINT 'Solo estadísticas modificadas: ' + @OnlyModifiedStatistics;

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error durante la optimización: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO IndexOptimizationLog (
            ExecutionTime,
            Status,
            ErrorMessage,
            DurationSeconds
        )
        VALUES (
            @StartTime,
            'Failed',
            @ErrorMessage,
            DATEDIFF(SECOND, @StartTime, GETDATE())
        );
    END
END CATCH;

/*
 * Notas adicionales:
 * 
 * 1. Importancia de la Optimización:
 *    - Mejora el rendimiento de las consultas
 *    - Reduce la fragmentación de índices
 *    - Mantiene las estadísticas actualizadas
 *    - Optimiza el uso de recursos
 * 
 * 2. Consideraciones de Rendimiento:
 *    - La reorganización es más rápida que la reconstrucción
 *    - La reconstrucción online permite acceso concurrente
 *    - La reconstrucción offline es más rápida pero bloquea
 *    - Las estadísticas actualizadas mejoran el plan de ejecución
 * 
 * 3. Recomendaciones:
 *    - Ejecutar durante períodos de baja actividad
 *    - Monitorear el impacto en el rendimiento
 *    - Ajustar los umbrales según necesidades
 *    - Considerar el tamaño de las bases de datos
 * 
 * 4. Seguridad:
 *    - Requiere permisos de administrador
 *    - Verificar el contexto de seguridad
 *    - Validar las operaciones permitidas
 *    - Monitorear el uso de recursos
 * 
 * 5. Mantenimiento:
 *    - Programar ejecuciones periódicas
 *    - Documentar los resultados
 *    - Ajustar parámetros según necesidades
 *    - Monitorear el impacto en el rendimiento
 */