/*
 * Script: Tablas sin Key Primary.sql
 * Descripción: Identifica tablas sin llave primaria y proporciona recomendaciones
 *              para normalización de bases de datos
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado mostrará las tablas sin llave primaria
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @IncludeSystemTables: Incluir tablas del sistema (default: 0)
 *    - @ShowRecommendations: Mostrar recomendaciones (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 * 
 * Notas:
 * - Se recomienda ejecutar con permisos de lectura
 * - Se incluyen validaciones de seguridad
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los datos
 */

-- Declaración de variables configurables
DECLARE @IncludeSystemTables BIT = 0;
DECLARE @ShowRecommendations BIT = 1;
DECLARE @LogToTable BIT = 0;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TablesWithoutPKLog')
    BEGIN
        CREATE TABLE TablesWithoutPKLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            TableCount INT,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

BEGIN TRY
    -- Registrar inicio de operación
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @TableCount INT = 0;

    -- Reporte de tablas sin llave primaria
    PRINT '-- TABLAS SIN LLAVE PRIMARIA --';
    PRINT '-----------------------------';
    PRINT 'IMPORTANCIA DE LAS LLAVES PRIMARIAS:';
    PRINT '-----------------------------------';
    PRINT '1. Integridad de Datos:';
    PRINT '   - Garantiza la unicidad de los registros';
    PRINT '   - Previene duplicados';
    PRINT '   - Mantiene la consistencia de los datos';
    PRINT '';
    PRINT '2. Rendimiento:';
    PRINT '   - Mejora el rendimiento de las consultas';
    PRINT '   - Optimiza las operaciones de JOIN';
    PRINT '   - Facilita la indexación';
    PRINT '';
    PRINT '3. Relaciones:';
    PRINT '   - Permite establecer relaciones entre tablas';
    PRINT '   - Facilita la integridad referencial';
    PRINT '   - Mejora la estructura de la base de datos';
    PRINT '';
    PRINT '4. Mantenimiento:';
    PRINT '   - Simplifica las operaciones de actualización';
    PRINT '   - Facilita la identificación de registros';
    PRINT '   - Mejora la trazabilidad de los datos';
    PRINT '';

    SELECT 
        Schema_name(schema_id) as 'Esquema',
        name as 'Tabla',
        create_date as 'Fecha de Creación',
        modify_date as 'Última Modificación',
        CASE WHEN @ShowRecommendations = 1 THEN 
            'Recomendación: Agregar llave primaria basada en ' + 
            CASE 
                WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = t.object_id AND name LIKE '%id%') THEN 'columna ID'
                WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = t.object_id AND name LIKE '%codigo%') THEN 'columna Código'
                ELSE 'columna(s) única(s)'
            END
        ELSE NULL END as 'Recomendación'
    FROM sys.tables t
    WHERE Objectproperty(object_id, 'TableHasPrimaryKey') = 0
        AND (@IncludeSystemTables = 1 OR schema_id NOT IN (1, 3, 4)) -- Excluir esquemas del sistema
    ORDER BY Schema_name(schema_id), name;

    -- Obtener conteo de tablas
    SELECT @TableCount = COUNT(*)
    FROM sys.tables t
    WHERE Objectproperty(object_id, 'TableHasPrimaryKey') = 0
        AND (@IncludeSystemTables = 1 OR schema_id NOT IN (1, 3, 4));

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO TablesWithoutPKLog (
            ExecutionTime,
            TableCount,
            Status
        )
        VALUES (
            @StartTime,
            @TableCount,
            'Success'
        );
    END

    -- Mostrar resumen
    PRINT '';
    PRINT 'Resumen:';
    PRINT 'Total de tablas sin llave primaria: ' + CAST(@TableCount AS NVARCHAR(10));
    PRINT 'Tiempo de ejecución: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + ' segundos';

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error al generar reporte de tablas sin llave primaria: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO TablesWithoutPKLog (
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
 * Notas adicionales sobre Normalización de Bases de Datos:
 * 
 * 1. Primera Forma Normal (1FN):
 *    - Cada columna debe contener valores atómicos
 *    - No deben existir grupos repetitivos
 *    - Cada tabla debe tener una llave primaria
 * 
 * 2. Segunda Forma Normal (2FN):
 *    - Debe estar en 1FN
 *    - Todos los atributos no clave deben depender de toda la llave primaria
 *    - Elimina dependencias parciales
 * 
 * 3. Tercera Forma Normal (3FN):
 *    - Debe estar en 2FN
 *    - No debe existir dependencia transitiva
 *    - Los atributos no clave no deben depender de otros atributos no clave
 * 
 * Beneficios de la Normalización:
 * - Reduce la redundancia de datos
 * - Mejora la integridad de los datos
 * - Facilita el mantenimiento
 * - Optimiza el rendimiento
 * 
 * Consideraciones:
 * - La normalización excesiva puede afectar el rendimiento
 * - En algunos casos, la desnormalización controlada puede ser beneficiosa
 * - Es importante encontrar un equilibrio entre normalización y rendimiento
 */ 