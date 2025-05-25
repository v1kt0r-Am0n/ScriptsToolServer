/*
 * Script: RecursosDBCpu.sql
 * Descripción: Análisis detallado del uso de CPU por base de datos
 * Autor: v1kt0r-Am0n
 * Fecha: 2024
 * Versión: 1.2
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. Los resultados mostrarán:
 *    - Uso de CPU por base de datos
 *    - Estadísticas de procesos
 *    - Métricas de rendimiento
 *    - Recomendaciones basadas en el uso
 * 
 * Notas:
 * - Requiere permisos de lectura en DMVs
 * - Se recomienda ejecutar en horarios de baja carga
 * - Los resultados pueden variar según la carga del servidor
 */

-- Configuración de parámetros
DECLARE @IncludeSystemDBs BIT = 0;  -- 1 para incluir bases de datos del sistema
DECLARE @MinCPUTimeMs BIGINT = 1000; -- Tiempo mínimo de CPU para mostrar
DECLARE @ShowDetailedInfo BIT = 1;  -- 1 para mostrar información detallada
DECLARE @ShowWaitStats BIT = 1;     -- 1 para mostrar estadísticas de espera

-- Análisis de uso de CPU por base de datos
WITH DB_CPU_Stats AS (
    SELECT 
        DatabaseID,
        DB_Name(DatabaseID) AS [DatabaseName],
        SUM(total_worker_time) AS [CPU_Time_Ms],
        SUM(total_elapsed_time) AS [Total_Time_Ms],
        SUM(total_logical_reads) AS [Logical_Reads],
        SUM(total_physical_reads) AS [Physical_Reads],
        SUM(total_logical_writes) AS [Logical_Writes],
        SUM(total_rows) AS [Total_Rows],
        SUM(execution_count) AS [Execution_Count],
        COUNT(*) AS [Query_Count],
        MAX(last_execution_time) AS [Last_Execution_Time],
        MIN(creation_time) AS [First_Execution_Time]
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY (
        SELECT CONVERT(int, value) AS [DatabaseID] 
        FROM sys.dm_exec_plan_attributes(qs.plan_handle)
        WHERE attribute = N'dbid'
    ) AS F_DB
    GROUP BY DatabaseID
)
SELECT 
    ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [Posición],
    DatabaseName,
    [CPU_Time_Ms],
    [Total_Time_Ms],
    [Logical_Reads],
    [Physical_Reads],
    [Logical_Writes],
    [Total_Rows],
    [Execution_Count],
    [Query_Count],
    [Last_Execution_Time],
    [First_Execution_Time],
    CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPU_Porcentaje],
    CAST([Logical_Reads] * 1.0 / SUM([Logical_Reads]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [Reads_Porcentaje],
    CAST([Physical_Reads] * 1.0 / SUM([Physical_Reads]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [Physical_Reads_Porcentaje],
    CASE 
        WHEN [CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 > 50 THEN 'ALTO'
        WHEN [CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 > 20 THEN 'MEDIO'
        ELSE 'BAJO'
    END AS [Nivel_Uso],
    CASE
        WHEN [Physical_Reads] > [Logical_Reads] * 0.5 THEN 'ALTO'
        WHEN [Physical_Reads] > [Logical_Reads] * 0.2 THEN 'MEDIO'
        ELSE 'BAJO'
    END AS [Nivel_IO]
FROM DB_CPU_Stats
WHERE (@IncludeSystemDBs = 1 OR DatabaseID > 4)
    AND DatabaseID <> 32767 -- ResourceDB
    AND [CPU_Time_Ms] >= @MinCPUTimeMs
ORDER BY [CPU_Time_Ms] DESC
OPTION (RECOMPILE);

-- Análisis de procesos actuales
DECLARE @total_cpu INT;
SELECT @total_cpu = SUM(cpu) 
FROM sys.sysprocesses sp (NOLOCK)
JOIN sys.sysdatabases sb (NOLOCK) ON sp.dbid = sb.dbid;

IF @ShowDetailedInfo = 1
BEGIN
    -- Información detallada de procesos
    SELECT 
        sb.name AS [Base_Datos],
        @total_cpu AS [CPU_Total_Sistema],
        SUM(cpu) AS [CPU_Base_Datos],
        CONVERT(DECIMAL(4,1), CONVERT(DECIMAL(17,2),SUM(cpu)) / CONVERT(DECIMAL(17,2),@total_cpu)*100) AS [Porcentaje_CPU],
        COUNT(*) AS [Procesos_Activos],
        SUM(CASE WHEN sp.status = 'runnable' THEN 1 ELSE 0 END) AS [Procesos_Ejecutándose],
        SUM(CASE WHEN sp.status = 'sleeping' THEN 1 ELSE 0 END) AS [Procesos_Dormidos],
        MAX(sp.cpu) AS [Max_CPU_Proceso],
        AVG(sp.cpu) AS [Promedio_CPU_Proceso],
        SUM(sp.physical_io) AS [Total_IO_Físico],
        SUM(sp.memusage) AS [Uso_Memoria],
        MAX(sp.waittime) AS [Max_Tiempo_Espera],
        AVG(sp.waittime) AS [Promedio_Tiempo_Espera]
    FROM sys.sysprocesses sp (NOLOCK)
    JOIN sys.sysdatabases sb (NOLOCK) ON sp.dbid = sb.dbid
    WHERE (@IncludeSystemDBs = 1 OR sb.dbid > 4)
    GROUP BY sb.name
    ORDER BY [Porcentaje_CPU] DESC;

    -- Estadísticas de espera si está habilitado
    IF @ShowWaitStats = 1
    BEGIN
        SELECT 
            DB_NAME(database_id) AS [Base_Datos],
            wait_type AS [Tipo_Espera],
            waiting_tasks_count AS [Tareas_Esperando],
            wait_time_ms AS [Tiempo_Espera_Total],
            signal_wait_time_ms AS [Tiempo_Espera_Señal],
            CAST(wait_time_ms * 1.0 / SUM(wait_time_ms) OVER() * 100.0 AS DECIMAL(5, 2)) AS [Porcentaje_Espera]
        FROM sys.dm_db_wait_stats
        WHERE database_id > 4
            AND wait_time_ms > 0
        ORDER BY wait_time_ms DESC;
    END

    -- Recomendaciones basadas en el uso
    PRINT '=== RECOMENDACIONES ===';
    PRINT '1. Bases de datos con uso ALTO:';
    PRINT '   - Revisar consultas más costosas';
    PRINT '   - Optimizar índices';
    PRINT '   - Considerar particionamiento';
    PRINT '   - Analizar planes de ejecución';
    PRINT '';
    PRINT '2. Bases de datos con uso MEDIO:';
    PRINT '   - Monitorear tendencias de uso';
    PRINT '   - Revisar planes de ejecución';
    PRINT '   - Optimizar consultas frecuentes';
    PRINT '';
    PRINT '3. Bases de datos con uso BAJO:';
    PRINT '   - Verificar si son necesarias';
    PRINT '   - Considerar consolidación';
    PRINT '   - Revisar políticas de mantenimiento';
    PRINT '';
    PRINT '4. Recomendaciones de IO:';
    PRINT '   - Optimizar índices para reducir lecturas físicas';
    PRINT '   - Considerar más memoria para buffer pool';
    PRINT '   - Revisar fragmentación de índices';
    PRINT '';
    PRINT '5. Recomendaciones generales:';
    PRINT '   - Revisar configuración de SQL Server';
    PRINT '   - Monitorear recursos del sistema';
    PRINT '   - Mantener estadísticas actualizadas';
    PRINT '   - Implementar mantenimiento regular';
END

/*
 * Notas adicionales:
 * 
 * 1. Interpretación de resultados:
 *    - CPU_Time_Ms: Tiempo total de CPU en milisegundos
 *    - Total_Time_Ms: Tiempo total de ejecución
 *    - Logical_Reads: Lecturas lógicas realizadas
 *    - Physical_Reads: Lecturas físicas realizadas
 *    - Total_Rows: Total de filas procesadas
 *    - Execution_Count: Número de ejecuciones
 *    - Query_Count: Número de consultas únicas
 * 
 * 2. Consideraciones:
 *    - Los resultados son acumulativos desde el último reinicio
 *    - El uso de CPU puede variar significativamente
 *    - Se recomienda monitorear en diferentes momentos
 *    - Las estadísticas de espera ayudan a identificar cuellos de botella
 * 
 * 3. Acciones recomendadas:
 *    - Identificar consultas problemáticas
 *    - Optimizar índices
 *    - Revisar planes de ejecución
 *    - Considerar particionamiento
 *    - Monitorear tendencias
 *    - Analizar patrones de espera
 *    - Optimizar configuración de memoria
 */