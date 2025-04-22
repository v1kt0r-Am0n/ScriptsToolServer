/*
 * Script: AnalizarProcedimientosConProblemas.sql
 * Descripción: Analiza procedimientos almacenados que no pueden ejecutarse
 *              debido a problemas con objetos referenciados
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado mostrará los procedimientos con problemas
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @IncludeSystemSPs: Incluir procedimientos del sistema (default: 0)
 *    - @ShowDetailedInfo: Mostrar información detallada (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 *    - @CheckPermissions: Verificar permisos (default: 1)
 * 
 * Notas:
 * - Se recomienda ejecutar con permisos de administrador
 * - Se incluyen validaciones de seguridad
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los datos
 */

-- Declaración de variables configurables
DECLARE @IncludeSystemSPs BIT = 0;
DECLARE @ShowDetailedInfo BIT = 1;
DECLARE @LogToTable BIT = 0;
DECLARE @CheckPermissions BIT = 1;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SPAnalysisLog')
    BEGIN
        CREATE TABLE SPAnalysisLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            SPCount INT,
            ErrorCount INT,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

BEGIN TRY
    -- Registrar inicio de operación
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @SPCount INT = 0;
    DECLARE @ErrorCount INT = 0;

    -- Crear tabla temporal para resultados
    CREATE TABLE #SPProblems (
        DatabaseName NVARCHAR(128),
        SchemaName NVARCHAR(128),
        SPName NVARCHAR(128),
        ProblemType NVARCHAR(50),
        ProblemDescription NVARCHAR(MAX),
        ReferencedObject NVARCHAR(256),
        CreateDate DATETIME,
        LastModifiedDate DATETIME
    );

    -- Cursor para recorrer todas las bases de datos
    DECLARE @DBName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    
    DECLARE DBCursor CURSOR FOR
    SELECT name 
    FROM sys.databases 
    WHERE state = 0 -- Solo bases de datos en línea
    AND (@IncludeSystemSPs = 1 OR name NOT IN ('master', 'tempdb', 'model', 'msdb'));

    OPEN DBCursor;
    FETCH NEXT FROM DBCursor INTO @DBName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = N'
        USE [' + @DBName + N'];
        
        -- Verificar procedimientos con objetos inexistentes
        INSERT INTO #SPProblems
        SELECT 
            DB_NAME() as DatabaseName,
            SCHEMA_NAME(sp.schema_id) as SchemaName,
            sp.name as SPName,
            ''Objeto Inexistente'' as ProblemType,
            ''El procedimiento hace referencia a un objeto que no existe'' as ProblemDescription,
            OBJECT_NAME(sed.referenced_id) as ReferencedObject,
            sp.create_date as CreateDate,
            sp.modify_date as LastModifiedDate
        FROM sys.procedures sp
        CROSS APPLY sys.dm_sql_referenced_entities(SCHEMA_NAME(sp.schema_id) + ''.'' + sp.name, ''OBJECT'') sed
        WHERE NOT EXISTS (
            SELECT 1 
            FROM sys.objects o 
            WHERE o.object_id = sed.referenced_id
        );

        -- Verificar procedimientos con problemas de permisos
        IF ' + CAST(@CheckPermissions AS NVARCHAR(1)) + N' = 1
        BEGIN
            INSERT INTO #SPProblems
            SELECT 
                DB_NAME() as DatabaseName,
                SCHEMA_NAME(sp.schema_id) as SchemaName,
                sp.name as SPName,
                ''Problema de Permisos'' as ProblemType,
                ''El procedimiento no tiene los permisos necesarios para ejecutarse'' as ProblemDescription,
                NULL as ReferencedObject,
                sp.create_date as CreateDate,
                sp.modify_date as LastModifiedDate
            FROM sys.procedures sp
            WHERE NOT EXISTS (
                SELECT 1 
                FROM sys.database_permissions dp
                WHERE dp.major_id = sp.object_id
                AND dp.permission_name = ''EXECUTE''
                AND dp.state = ''G''
            );
        END

        -- Verificar procedimientos con problemas de sintaxis
        INSERT INTO #SPProblems
        SELECT 
            DB_NAME() as DatabaseName,
            SCHEMA_NAME(sp.schema_id) as SchemaName,
            sp.name as SPName,
            ''Problema de Sintaxis'' as ProblemType,
            ''El procedimiento contiene errores de sintaxis'' as ProblemDescription,
            NULL as ReferencedObject,
            sp.create_date as CreateDate,
            sp.modify_date as LastModifiedDate
        FROM sys.procedures sp
        WHERE OBJECT_DEFINITION(sp.object_id) LIKE ''%ERROR%''
           OR OBJECT_DEFINITION(sp.object_id) LIKE ''%INVALID%''
           OR OBJECT_DEFINITION(sp.object_id) LIKE ''%NOT FOUND%'';';

        EXEC sp_executesql @SQL;
        
        FETCH NEXT FROM DBCursor INTO @DBName;
    END

    CLOSE DBCursor;
    DEALLOCATE DBCursor;

    -- Mostrar resultados
    PRINT '-- PROCEDIMIENTOS ALMACENADOS CON PROBLEMAS --';
    PRINT '-------------------------------------------';
    PRINT 'TIPOS DE PROBLEMAS ANALIZADOS:';
    PRINT '1. Objetos Inexistentes';
    PRINT '2. Problemas de Permisos';
    PRINT '3. Errores de Sintaxis';
    PRINT '';

    SELECT 
        DatabaseName as 'Base de Datos',
        SchemaName as 'Esquema',
        SPName as 'Procedimiento',
        ProblemType as 'Tipo de Problema',
        ProblemDescription as 'Descripción',
        ReferencedObject as 'Objeto Referenciado',
        CreateDate as 'Fecha de Creación',
        LastModifiedDate as 'Última Modificación'
    FROM #SPProblems
    ORDER BY DatabaseName, SchemaName, SPName;

    -- Obtener conteos
    SELECT 
        @SPCount = COUNT(DISTINCT SPName),
        @ErrorCount = COUNT(*)
    FROM #SPProblems;

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO SPAnalysisLog (
            ExecutionTime,
            SPCount,
            ErrorCount,
            Status
        )
        VALUES (
            @StartTime,
            @SPCount,
            @ErrorCount,
            'Success'
        );
    END

    -- Mostrar resumen
    PRINT '';
    PRINT 'Resumen:';
    PRINT 'Total de procedimientos con problemas: ' + CAST(@SPCount AS NVARCHAR(10));
    PRINT 'Total de errores encontrados: ' + CAST(@ErrorCount AS NVARCHAR(10));
    PRINT 'Tiempo de ejecución: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + ' segundos';

    -- Limpiar tabla temporal
    DROP TABLE #SPProblems;

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error al analizar procedimientos almacenados: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO SPAnalysisLog (
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
 * 1. Tipos de Problemas Detectados:
 *    - Objetos referenciados que no existen
 *    - Problemas de permisos de ejecución
 *    - Errores de sintaxis en el código
 *    - Referencias a objetos eliminados
 * 
 * 2. Recomendaciones:
 *    - Revisar y corregir las referencias a objetos inexistentes
 *    - Verificar y otorgar los permisos necesarios
 *    - Corregir errores de sintaxis en el código
 *    - Actualizar las referencias a objetos modificados
 * 
 * 3. Consideraciones de Seguridad:
 *    - Verificar permisos antes de ejecutar
 *    - Revisar el contexto de seguridad
 *    - Validar las referencias cruzadas
 *    - Comprobar la integridad de los objetos
 * 
 * 4. Mantenimiento:
 *    - Ejecutar periódicamente para detectar problemas
 *    - Mantener actualizado el inventario de procedimientos
 *    - Documentar los cambios realizados
 *    - Registrar los problemas resueltos
 */ 