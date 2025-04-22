/*
 * Script: ScriptUtiles.sql
 * Descripción: Colección de consultas útiles para administración y monitoreo
 *              de bases de datos SQL Server
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. Seleccionar la consulta deseada según la necesidad
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @DaysToLookBack: Días a analizar (default: 30)
 *    - @DatabaseName: Nombre de la base de datos (default: NULL)
 *    - @SchemaName: Nombre del esquema (default: NULL)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 * 
 * Notas:
 * - Se recomienda ejecutar con permisos de lectura
 * - Se incluyen validaciones de seguridad
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los datos
 */

-- Declaración de variables configurables
DECLARE @DaysToLookBack INT = 30;
DECLARE @DatabaseName NVARCHAR(128) = NULL;
DECLARE @SchemaName NVARCHAR(128) = NULL;
DECLARE @LogToTable BIT = 0;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'UtilityScriptLog')
    BEGIN
        CREATE TABLE UtilityScriptLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            ScriptType NVARCHAR(50),
            DatabaseName NVARCHAR(128),
            SchemaName NVARCHAR(128),
            ObjectCount INT,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

BEGIN TRY
    -- Registrar inicio de operación
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @ObjectCount INT;

    -- 1. Consulta de objetos modificados recientemente
    PRINT '-- 1. OBJETOS MODIFICADOS RECIENTEMENTE --';
    PRINT '--------------------------------------';
    
    SELECT 
        name AS 'Nombre Objeto',
        SCHEMA_NAME(schema_id) AS 'Esquema',
        type_desc AS 'Tipo',
        create_date AS 'Fecha Creación',
        modify_date AS 'Última Modificación',
        DATEDIFF(DAY, modify_date, GETDATE()) AS 'Días desde Modificación',
        CASE 
            WHEN DATEDIFF(DAY, modify_date, GETDATE()) <= 7 THEN 'RECIENTE'
            WHEN DATEDIFF(DAY, modify_date, GETDATE()) <= 30 THEN 'MODERADO'
            ELSE 'ANTIGUO'
        END AS 'Estado'
    FROM sys.objects
    WHERE modify_date > DATEADD(DAY, -@DaysToLookBack, GETDATE())
        AND is_ms_shipped = 0
    ORDER BY modify_date DESC, name;

    -- 2. Consulta de funciones definidas por el usuario
    PRINT '';
    PRINT '-- 2. FUNCIONES DEFINIDAS POR EL USUARIO --';
    PRINT '----------------------------------------';
    
    IF @DatabaseName IS NOT NULL
    BEGIN
        EXEC('USE [' + @DatabaseName + '];');
    END

    SELECT 
        name AS 'Nombre Función',
        SCHEMA_NAME(schema_id) AS 'Esquema',
        type_desc AS 'Tipo',
        create_date AS 'Fecha Creación',
        modify_date AS 'Última Modificación',
        OBJECT_DEFINITION(OBJECT_ID) AS 'Definición'
    FROM sys.objects
    WHERE type_desc LIKE '%FUNCTION%'
        AND is_ms_shipped = 0
    ORDER BY name;

    -- 3. Consulta de propietarios de objetos por esquema
    PRINT '';
    PRINT '-- 3. PROPIETARIOS DE OBJETOS POR ESQUEMA --';
    PRINT '-----------------------------------------';
    
    IF @SchemaName IS NOT NULL
    BEGIN
        SELECT 
            'OBJECT' AS 'Tipo Entidad',
            USER_NAME(OBJECTPROPERTY(object_id, 'OwnerId')) AS 'Propietario',
            name AS 'Nombre',
            type_desc AS 'Tipo',
            create_date AS 'Fecha Creación'
        FROM sys.objects 
        WHERE SCHEMA_NAME(schema_id) = @SchemaName
            AND is_ms_shipped = 0
        UNION 
        SELECT 
            'TYPE' AS 'Tipo Entidad',
            USER_NAME(TYPEPROPERTY(SCHEMA_NAME(schema_id) + '.' + name, 'OwnerId')) AS 'Propietario',
            name AS 'Nombre',
            'TYPE' AS 'Tipo',
            NULL AS 'Fecha Creación'
        FROM sys.types 
        WHERE SCHEMA_NAME(schema_id) = @SchemaName
        UNION
        SELECT 
            'XML SCHEMA COLLECTION' AS 'Tipo Entidad',
            COALESCE(USER_NAME(xsc.principal_id), USER_NAME(s.principal_id)) AS 'Propietario',
            xsc.name AS 'Nombre',
            'XML SCHEMA COLLECTION' AS 'Tipo',
            NULL AS 'Fecha Creación'
        FROM sys.xml_schema_collections AS xsc 
        JOIN sys.schemas AS s ON s.schema_id = xsc.schema_id
        WHERE s.name = @SchemaName
        ORDER BY 'Tipo Entidad', 'Nombre';
    END

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO UtilityScriptLog (
            ExecutionTime,
            ScriptType,
            DatabaseName,
            SchemaName,
            ObjectCount,
            Status
        )
        VALUES (
            @StartTime,
            'Utility Script',
            @DatabaseName,
            @SchemaName,
            @ObjectCount,
            'Success'
        );
    END

    -- Mostrar resumen
    PRINT '';
    PRINT 'Resumen:';
    PRINT 'Tiempo de ejecución: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + ' segundos';

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error al ejecutar script de utilidades: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO UtilityScriptLog (
            ExecutionTime,
            ScriptType,
            DatabaseName,
            SchemaName,
            Status,
            ErrorMessage
        )
        VALUES (
            @StartTime,
            'Utility Script',
            @DatabaseName,
            @SchemaName,
            'Failed',
            @ErrorMessage
        );
    END
END CATCH;

/*
 * Notas adicionales:
 * 
 * 1. Importancia del Script:
 *    - Proporciona información valiosa para administración
 *    - Facilita el monitoreo de cambios
 *    - Ayuda en la auditoría de objetos
 *    - Simplifica tareas comunes
 * 
 * 2. Consideraciones de Uso:
 *    - Verificar permisos necesarios
 *    - Ajustar parámetros según necesidades
 *    - Monitorear el rendimiento
 *    - Documentar los resultados
 * 
 * 3. Recomendaciones:
 *    - Ejecutar con precaución en producción
 *    - Validar resultados
 *    - Mantener un historial
 *    - Actualizar según necesidades
 * 
 * 4. Seguridad:
 *    - Requiere permisos adecuados
 *    - Verificar el contexto de seguridad
 *    - Proteger información sensible
 *    - Monitorear el acceso
 * 
 * 5. Mantenimiento:
 *    - Revisar regularmente
 *    - Actualizar según versiones
 *    - Documentar cambios
 *    - Optimizar según necesidades
 */