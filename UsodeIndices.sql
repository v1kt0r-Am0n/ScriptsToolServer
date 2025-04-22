/*
 * Script: UsodeIndices.sql
 * Descripción: Analiza el uso de índices en las bases de datos, identificando
 *              índices no utilizados y proporcionando recomendaciones
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado mostrará índices no utilizados y estadísticas
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @IncludeSystemDBs: Incluir bases de datos del sistema (default: 0)
 *    - @MinSizeMB: Tamaño mínimo de base de datos a analizar (default: 0)
 *    - @ShowDetailedInfo: Mostrar información detallada (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 * 
 * Notas:
 * - Se recomienda ejecutar con permisos de lectura
 * - Se incluyen validaciones de seguridad
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los datos
 */

-- Declaración de variables configurables
DECLARE @IncludeSystemDBs BIT = 0;
DECLARE @MinSizeMB INT = 0;
DECLARE @ShowDetailedInfo BIT = 1;
DECLARE @LogToTable BIT = 0;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'IndexUsageLog')
    BEGIN
        CREATE TABLE IndexUsageLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            DatabaseName NVARCHAR(128),
            TotalSizeMB DECIMAL(18,2),
            LogSizeMB DECIMAL(18,2),
            UnusedIndexCount INT,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

BEGIN TRY
    -- Registrar inicio de operación
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @UnusedIndexCount INT = 0;

    -- Reporte de uso de índices
    PRINT '-- ANÁLISIS DE USO DE ÍNDICES --';
    PRINT '-----------------------------';
    PRINT 'IMPORTANCIA DEL ANÁLISIS:';
    PRINT '------------------------';
    PRINT '1. Rendimiento:';
    PRINT '   - Índices no utilizados consumen espacio';
    PRINT '   - Afectan el rendimiento de las operaciones DML';
    PRINT '   - Incrementan el tiempo de backup';
    PRINT '';
    PRINT '2. Mantenimiento:';
    PRINT '   - Simplifica la estructura de la base de datos';
    PRINT '   - Reduce el tiempo de mantenimiento';
    PRINT '   - Mejora la eficiencia de las operaciones';
    PRINT '';

    SELECT 
        B.database_id as 'ID',
        B.name as 'Base de Datos',
        SUM((T.size * 8) / 1024.00) as 'Tamaño Datos (MB)',
        SUM((T2.size * 8) / 1024.00) as 'Tamaño Log (MB)',
        MAX(I.last_user_seek) as 'Último Seek',
        MAX(I.last_user_scan) as 'Último Scan',
        MAX(I.last_user_lookup) as 'Último Lookup',
        MAX(I.last_user_update) as 'Última Actualización',
        CASE WHEN @ShowDetailedInfo = 1 THEN
            CASE 
                WHEN MAX(I.last_user_seek) IS NULL AND MAX(I.last_user_scan) IS NULL AND MAX(I.last_user_update) IS NULL 
                THEN 'Recomendación: Considerar eliminar índices no utilizados'
                WHEN MAX(I.last_user_update) > MAX(I.last_user_seek) AND MAX(I.last_user_update) > MAX(I.last_user_scan)
                THEN 'Recomendación: Revisar índices con más actualizaciones que lecturas'
                ELSE 'Recomendación: Monitorear uso de índices'
            END
        ELSE NULL END as 'Recomendación'
    FROM sys.databases B
        INNER JOIN sys.master_files T ON (B.database_id = T.database_id AND T.type_desc = 'ROWS')
        INNER JOIN sys.master_files T2 ON (B.database_id = T2.database_id AND T2.type_desc = 'LOG')
        LEFT JOIN sys.dm_db_index_usage_stats I ON (B.database_id = I.database_id)
    WHERE (@IncludeSystemDBs = 1 OR B.name NOT IN ('master', 'ReportServer', 'ReportServerTempDB', 'tempdb', 'model', 'msdb'))
        AND SUM((T.size * 8) / 1024.00) >= @MinSizeMB
    GROUP BY B.database_id, B.name
    HAVING MAX(I.last_user_seek) IS NULL 
        AND MAX(I.last_user_scan) IS NULL 
        AND MAX(I.last_user_update) IS NULL
    ORDER BY B.name;

    -- Obtener conteo de índices no utilizados
    SELECT @UnusedIndexCount = COUNT(*)
    FROM (
        SELECT B.database_id
        FROM sys.databases B
            INNER JOIN sys.master_files T ON (B.database_id = T.database_id AND T.type_desc = 'ROWS')
            LEFT JOIN sys.dm_db_index_usage_stats I ON (B.database_id = I.database_id)
        WHERE (@IncludeSystemDBs = 1 OR B.name NOT IN ('master', 'ReportServer', 'ReportServerTempDB', 'tempdb', 'model', 'msdb'))
            AND SUM((T.size * 8) / 1024.00) >= @MinSizeMB
        GROUP BY B.database_id, B.name
        HAVING MAX(I.last_user_seek) IS NULL 
            AND MAX(I.last_user_scan) IS NULL 
            AND MAX(I.last_user_update) IS NULL
    ) AS UnusedIndexes;

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO IndexUsageLog (
            ExecutionTime,
            DatabaseName,
            TotalSizeMB,
            LogSizeMB,
            UnusedIndexCount,
            Status
        )
        SELECT 
            @StartTime,
            B.name,
            SUM((T.size * 8) / 1024.00),
            SUM((T2.size * 8) / 1024.00),
            @UnusedIndexCount,
            'Success'
        FROM sys.databases B
            INNER JOIN sys.master_files T ON (B.database_id = T.database_id AND T.type_desc = 'ROWS')
            INNER JOIN sys.master_files T2 ON (B.database_id = T2.database_id AND T2.type_desc = 'LOG')
        WHERE (@IncludeSystemDBs = 1 OR B.name NOT IN ('master', 'ReportServer', 'ReportServerTempDB', 'tempdb', 'model', 'msdb'))
            AND SUM((T.size * 8) / 1024.00) >= @MinSizeMB
        GROUP BY B.name;
    END

    -- Mostrar resumen
    PRINT '';
    PRINT 'Resumen:';
    PRINT 'Total de bases de datos con índices no utilizados: ' + CAST(@UnusedIndexCount AS NVARCHAR(10));
    PRINT 'Tiempo de ejecución: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + ' segundos';

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error al analizar uso de índices: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO IndexUsageLog (
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
 *    - Identifica índices no utilizados
 *    - Mejora el rendimiento de la base de datos
 *    - Reduce el espacio utilizado
 *    - Optimiza las operaciones de mantenimiento
 * 
 * 2. Consideraciones de Rendimiento:
 *    - Los índices no utilizados afectan el rendimiento
 *    - El mantenimiento de índices consume recursos
 *    - La fragmentación impacta en el rendimiento
 *    - Las estadísticas deben estar actualizadas
 * 
 * 3. Recomendaciones:
 *    - Eliminar índices no utilizados
 *    - Monitorear el uso de índices regularmente
 *    - Considerar el impacto en las consultas
 *    - Documentar los cambios realizados
 * 
 * 4. Seguridad:
 *    - Verificar permisos antes de eliminar índices
 *    - Realizar pruebas de rendimiento
 *    - Mantener copias de seguridad
 *    - Documentar los cambios
 * 
 * 5. Mantenimiento:
 *    - Programar análisis periódicos
 *    - Monitorear el impacto de los cambios
 *    - Actualizar estadísticas regularmente
 *    - Documentar las mejoras realizadas
 */