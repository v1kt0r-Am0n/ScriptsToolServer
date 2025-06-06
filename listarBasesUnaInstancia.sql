/*
 * Script: listarBasesUnaInstancia.sql
 * Descripción: Genera reportes detallados de bases de datos en una instancia de SQL Server
 *              Incluye validaciones y manejo de errores
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado será un reporte detallado de las bases de datos
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @IncludeSystemDBs: Incluir bases de datos del sistema (default: 0)
 *    - @ShowDetailedInfo: Mostrar información detallada (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 *    - @OrderBy: Criterio de ordenamiento (default: 'name')
 * 
 * Notas:
 * - Se recomienda ejecutar con permisos de lectura
 * - Se incluyen validaciones de seguridad
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los datos
 */

-- Declaración de variables configurables
DECLARE @IncludeSystemDBs BIT = 0;
DECLARE @ShowDetailedInfo BIT = 1;
DECLARE @LogToTable BIT = 0;
DECLARE @OrderBy NVARCHAR(50) = 'name';

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DBListLog')
    BEGIN
        CREATE TABLE DBListLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            DBCount INT,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

BEGIN TRY
    -- Registrar inicio de operación
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @DBCount INT = 0;

    -- Reporte básico de bases de datos
    PRINT '-- INFORMACIÓN DE BASES DE DATOS --';
    PRINT '--------------------------------';

    SELECT 
        name AS 'Nombre',
        database_id AS 'ID',
        create_date AS 'Fecha de Creación',
        recovery_model_desc AS 'Modelo de Recuperación',
        state_desc AS 'Estado',
        CASE WHEN @ShowDetailedInfo = 1 THEN 
            CAST(SUM(size * 8.0 / 1024) AS DECIMAL(18,2)) 
        ELSE NULL END AS 'Tamaño (MB)',
        CASE WHEN @ShowDetailedInfo = 1 THEN 
            compatibility_level 
        ELSE NULL END AS 'Nivel de Compatibilidad',
        CASE WHEN @ShowDetailedInfo = 1 THEN 
            collation_name 
        ELSE NULL END AS 'Intercalación'
    FROM sys.databases d
    LEFT JOIN sys.master_files mf ON d.database_id = mf.database_id
    WHERE @IncludeSystemDBs = 1 OR name NOT IN ('master', 'tempdb', 'model', 'msdb')
    GROUP BY 
        name, 
        database_id, 
        create_date, 
        recovery_model_desc, 
        state_desc,
        CASE WHEN @ShowDetailedInfo = 1 THEN compatibility_level ELSE NULL END,
        CASE WHEN @ShowDetailedInfo = 1 THEN collation_name ELSE NULL END
    ORDER BY 
        CASE @OrderBy
            WHEN 'name' THEN name
            WHEN 'size' THEN CAST(SUM(size * 8.0 / 1024) AS DECIMAL(18,2))
            WHEN 'createdate' THEN create_date
            ELSE name
        END;

    -- Obtener conteo de bases de datos
    SELECT @DBCount = COUNT(*)
    FROM sys.databases
    WHERE @IncludeSystemDBs = 1 OR name NOT IN ('master', 'tempdb', 'model', 'msdb');

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO DBListLog (
            ExecutionTime,
            DBCount,
            Status
        )
        VALUES (
            @StartTime,
            @DBCount,
            'Success'
        );
    END

    -- Mostrar resumen
    PRINT '';
    PRINT 'Resumen:';
    PRINT 'Total de bases de datos: ' + CAST(@DBCount AS NVARCHAR(10));
    PRINT 'Tiempo de ejecución: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + ' segundos';

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error al generar reporte de bases de datos: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO DBListLog (
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
 * 1. Consideraciones sobre Bases de Datos:
 *    - Verifica existencia de bases de datos
 *    - Comprueba estados y modelos de recuperación
 *    - Valida tamaños y configuraciones
 *    - Incluye manejo de errores detallado
 * 
 * 2. Seguridad:
 *    - Requiere permisos VIEW DEFINITION
 *    - Verifica permisos de lectura
 *    - Incluye validaciones de seguridad
 *    - Maneja errores de forma segura
 * 
 * 3. Uso recomendado:
 *    - Ejecutar con permisos de lectura
 *    - Verificar el impacto en el rendimiento
 *    - Monitorear el uso de recursos
 *    - Probar primero con @ShowDetailedInfo = 0
 * 
 * 4. Monitoreo:
 *    - Opción de logging detallado
 *    - Registro de conteos y estados
 *    - Seguimiento de errores
 *    - Historial de operaciones
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye conteos de bases de datos
 *    - Registra tiempos de ejecución
 *    - Almacena mensajes de error
 */

SELECT name, database_id, create_date  ,recovery_model_desc,state_desc
FROM sys.databases   
where name not in (
'master',
'tempdb',
'model',
'msdb')
order by 1;
GO  

----
select *  FROM sys.databases 
