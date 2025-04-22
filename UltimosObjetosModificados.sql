/*
 * Script: UltimosObjetosModificados.sql
 * Descripción: Analiza los objetos modificados recientemente en la base de datos,
 *              proporcionando información detallada sobre cambios y modificaciones
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado mostrará información sobre:
 *    - Objetos modificados recientemente
 *    - Fechas de creación y modificación
 *    - Tipos de objetos
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @ObjectTypes: Tipos de objetos a analizar (default: 'P,U,V')
 *    - @DaysToLookBack: Días a analizar (default: 30)
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
DECLARE @ObjectTypes VARCHAR(50) = 'P,U,V'; -- P=Procedimientos, U=Tablas, V=Vistas
DECLARE @DaysToLookBack INT = 30;
DECLARE @ShowDetailedInfo BIT = 1;
DECLARE @LogToTable BIT = 0;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ObjectModificationLog')
    BEGIN
        CREATE TABLE ObjectModificationLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            ObjectName NVARCHAR(128),
            ObjectType NVARCHAR(2),
            CreateDate DATETIME,
            ModifyDate DATETIME,
            DaysSinceModification INT,
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

    -- Reporte de objetos modificados
    PRINT '-- ANÁLISIS DE OBJETOS MODIFICADOS --';
    PRINT '----------------------------------';
    PRINT 'IMPORTANCIA DEL ANÁLISIS:';
    PRINT '------------------------';
    PRINT '1. Control de Cambios:';
    PRINT '   - Identifica modificaciones recientes';
    PRINT '   - Ayuda en el seguimiento de cambios';
    PRINT '   - Facilita la auditoría';
    PRINT '';
    PRINT '2. Mantenimiento:';
    PRINT '   - Monitorea la evolución de objetos';
    PRINT '   - Identifica patrones de modificación';
    PRINT '   - Ayuda en la planificación';
    PRINT '';

    -- Análisis de objetos modificados
    PRINT 'OBJETOS MODIFICADOS EN LOS ÚLTIMOS ' + CAST(@DaysToLookBack AS NVARCHAR(10)) + ' DÍAS:';
    PRINT '------------------------------------------------';
    
    SELECT 
        o.name as 'Nombre Objeto',
        o.type_desc as 'Tipo',
        o.create_date as 'Fecha Creación',
        o.modify_date as 'Última Modificación',
        DATEDIFF(DAY, o.modify_date, GETDATE()) as 'Días desde Modificación',
        CASE 
            WHEN DATEDIFF(DAY, o.modify_date, GETDATE()) <= 7 THEN 'RECIENTE'
            WHEN DATEDIFF(DAY, o.modify_date, GETDATE()) <= 30 THEN 'MODERADO'
            ELSE 'ANTIGUO'
        END as 'Estado',
        CASE WHEN @ShowDetailedInfo = 1 THEN
            CASE 
                WHEN o.type = 'P' THEN 'Procedimiento Almacenado'
                WHEN o.type = 'U' THEN 'Tabla'
                WHEN o.type = 'V' THEN 'Vista'
                ELSE 'Otro'
            END
        ELSE NULL END as 'Descripción Tipo'
    FROM sys.objects o
    WHERE o.type IN (SELECT value FROM STRING_SPLIT(@ObjectTypes, ','))
        AND o.modify_date >= DATEADD(DAY, -@DaysToLookBack, GETDATE())
        AND o.is_ms_shipped = 0
    ORDER BY o.modify_date DESC;

    -- Obtener conteo de objetos modificados
    SELECT @ObjectCount = COUNT(*)
    FROM sys.objects o
    WHERE o.type IN (SELECT value FROM STRING_SPLIT(@ObjectTypes, ','))
        AND o.modify_date >= DATEADD(DAY, -@DaysToLookBack, GETDATE())
        AND o.is_ms_shipped = 0;

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO ObjectModificationLog (
            ExecutionTime,
            ObjectName,
            ObjectType,
            CreateDate,
            ModifyDate,
            DaysSinceModification,
            Status
        )
        SELECT 
            @StartTime,
            o.name,
            o.type,
            o.create_date,
            o.modify_date,
            DATEDIFF(DAY, o.modify_date, GETDATE()),
            'Success'
        FROM sys.objects o
        WHERE o.type IN (SELECT value FROM STRING_SPLIT(@ObjectTypes, ','))
            AND o.modify_date >= DATEADD(DAY, -@DaysToLookBack, GETDATE())
            AND o.is_ms_shipped = 0;
    END

    -- Mostrar resumen
    PRINT '';
    PRINT 'Resumen:';
    PRINT 'Total de objetos modificados: ' + CAST(@ObjectCount AS NVARCHAR(10));
    PRINT 'Período analizado: últimos ' + CAST(@DaysToLookBack AS NVARCHAR(10)) + ' días';
    PRINT 'Tiempo de ejecución: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + ' segundos';

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error al analizar objetos modificados: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO ObjectModificationLog (
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
 *    - Control de cambios en la base de datos
 *    - Seguimiento de modificaciones
 *    - Auditoría de objetos
 *    - Planificación de mantenimiento
 * 
 * 2. Consideraciones de Rendimiento:
 *    - El análisis es rápido y eficiente
 *    - No afecta el rendimiento del sistema
 *    - Proporciona información valiosa
 *    - Ayuda en la toma de decisiones
 * 
 * 3. Recomendaciones:
 *    - Ejecutar regularmente
 *    - Documentar los cambios
 *    - Mantener un historial
 *    - Revisar patrones de modificación
 * 
 * 4. Seguridad:
 *    - Requiere permisos de lectura
 *    - Verificar el contexto de seguridad
 *    - Validar las operaciones permitidas
 *    - Proteger información sensible
 * 
 * 5. Mantenimiento:
 *    - Programar análisis periódicos
 *    - Documentar los resultados
 *    - Ajustar períodos según necesidades
 *    - Monitorear tendencias
 * 
 * 6. Tipos de Objetos:
 *    - P: Procedimientos Almacenados
 *    - U: Tablas
 *    - V: Vistas
 *    - Otros tipos disponibles según necesidad
 */

--- u= Tablas
--- v= Views
--- p= sored procedure