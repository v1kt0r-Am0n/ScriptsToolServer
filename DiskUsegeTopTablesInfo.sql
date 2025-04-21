/*
 * Script: DiskUsegeTopTablesInfo.sql
 * Descripción: Consulta que muestra información detallada sobre el uso de espacio de las tablas
 *              en una base de datos SQL Server, incluyendo tamaño de datos, índices y espacio no utilizado
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.1
 * 
 * Uso:
 * 1. Ejecutar el script en la base de datos deseada
 * 2. Los resultados mostrarán las tablas más grandes por espacio reservado
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @TopTables: Número de tablas a mostrar (default: 1000)
 *    - @MinSizeMB: Tamaño mínimo en MB para incluir una tabla (default: 0)
 *    - @ShowSystemTables: Incluir tablas del sistema (default: 0)
 * 
 * Notas:
 * - Muestra información detallada de espacio por tabla
 * - Incluye número de filas y columnas
 * - Calcula espacio de índices y espacio no utilizado
 * - Manejo robusto de errores
 * - Formato de salida mejorado
 */

-- Declaración de variables configurables
DECLARE @TopTables INT = 1000;
DECLARE @MinSizeMB INT = 0;
DECLARE @ShowSystemTables BIT = 0;

BEGIN TRY 
    -- Consulta principal para obtener información de uso de espacio
    SELECT TOP (@TopTables)
        (ROW_NUMBER() OVER(ORDER BY (a1.reserved + ISNULL(a4.reserved,0)) DESC))%2 AS l1,
        a3.name AS [SchemaName],
        'TBL_*****' + SUBSTRING(a2.name,9,LEN(a2.name)) AS [TableName],
        a1.rows AS RowCount,
        (a1.reserved + ISNULL(a4.reserved,0)) * 8 AS ReservedKB,
        a1.data * 8 AS DataKB,
        (CASE 
            WHEN (a1.used + ISNULL(a4.used,0)) > a1.data 
            THEN (a1.used + ISNULL(a4.used,0)) - a1.data 
            ELSE 0 
        END) * 8 AS IndexSizeKB,
        (CASE 
            WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used 
            THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used 
            ELSE 0 
        END) * 8 AS UnusedKB,
        (SELECT COUNT(*) FROM Information_Schema.Columns WHERE Table_Name = a2.name) AS ColumnCount,
        -- Cálculo de porcentajes
        CAST((a1.data * 8.0) / NULLIF((a1.reserved + ISNULL(a4.reserved,0)) * 8, 0) * 100 AS DECIMAL(5,2)) AS DataPercentage,
        CAST(((CASE 
            WHEN (a1.used + ISNULL(a4.used,0)) > a1.data 
            THEN (a1.used + ISNULL(a4.used,0)) - a1.data 
            ELSE 0 
        END) * 8.0) / NULLIF((a1.reserved + ISNULL(a4.reserved,0)) * 8, 0) * 100 AS DECIMAL(5,2)) AS IndexPercentage,
        CAST(((CASE 
            WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used 
            THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used 
            ELSE 0 
        END) * 8.0) / NULLIF((a1.reserved + ISNULL(a4.reserved,0)) * 8, 0) * 100 AS DECIMAL(5,2)) AS UnusedPercentage
    FROM    
        -- Subconsulta para obtener estadísticas de particiones
        (SELECT
            ps.object_id,
            SUM(CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows],
            SUM(ps.reserved_page_count) AS reserved,
            SUM(CASE   
                WHEN (ps.index_id < 2) 
                THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) 
            END) AS data,
            SUM(ps.used_page_count) AS used
        FROM sys.dm_db_partition_stats ps
        GROUP BY ps.object_id) AS a1

    -- Join para obtener información de tablas internas
    LEFT OUTER JOIN (
        SELECT
            it.parent_id,
            SUM(ps.reserved_page_count) AS reserved,
            SUM(ps.used_page_count) AS used
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
        WHERE it.internal_type IN (202,204)
        GROUP BY it.parent_id
    ) AS a4 ON (a4.parent_id = a1.object_id)

    -- Joins para obtener nombres de objetos y esquemas
    INNER JOIN sys.all_objects a2 ON (a1.object_id = a2.object_id)
    INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)

    -- Filtro para excluir tablas del sistema (si no se solicitan)
    WHERE (@ShowSystemTables = 1 OR (a2.type <> N'S' AND a2.type <> N'IT'))
    AND (a1.reserved + ISNULL(a4.reserved,0)) * 8 >= @MinSizeMB * 1024
    ORDER BY ReservedKB DESC;

END TRY
BEGIN CATCH
    -- Manejo de errores detallado
    SELECT
        -100 AS ErrorIndicator,
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine;
END CATCH;

/*
 * Notas adicionales:
 * 1. Columnas del resultado:
 *    - l1: Indicador de fila par/impar para formato
 *    - SchemaName: Nombre del esquema
 *    - TableName: Nombre de la tabla (enmascarado)
 *    - RowCount: Número de filas
 *    - ReservedKB: Espacio total reservado en KB
 *    - DataKB: Espacio usado por datos en KB
 *    - IndexSizeKB: Espacio usado por índices en KB
 *    - UnusedKB: Espacio no utilizado en KB
 *    - ColumnCount: Número de columnas
 *    - DataPercentage: Porcentaje de espacio usado por datos
 *    - IndexPercentage: Porcentaje de espacio usado por índices
 *    - UnusedPercentage: Porcentaje de espacio no utilizado
 * 
 * 2. Consideraciones:
 *    - Los tamaños se muestran en KB (multiplicados por 8)
 *    - Se pueden excluir tablas del sistema
 *    - Se incluyen tablas internas relacionadas
 *    - Se puede filtrar por tamaño mínimo
 *    - Se muestran porcentajes de uso de espacio
 * 
 * 3. Manejo de errores:
 *    - Captura y muestra información detallada de errores
 *    - Incluye número, severidad, estado y mensaje
 *    - Muestra procedimiento y línea donde ocurrió el error
 * 
 * 4. Rendimiento:
 *    - La consulta está optimizada para minimizar el impacto en el servidor
 *    - Se recomienda ejecutar en horarios de baja actividad
 *    - El filtrado por tamaño mínimo ayuda a reducir el resultado
 * 
 * 5. Seguridad:
 *    - Requiere permisos de lectura en vistas del sistema
 *    - Los nombres de tablas se enmascaran por seguridad
 *    - Se pueden excluir tablas del sistema para mayor seguridad
 */
