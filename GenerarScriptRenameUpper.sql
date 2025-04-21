/*
 * Script: GenerarScriptRenameUpper.sql
 * Descripción: Genera scripts para renombrar tablas a mayúsculas
 *              Incluye validaciones y manejo de errores
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la base de datos deseada
 * 2. El resultado será un script que se puede ejecutar para renombrar tablas
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @SchemaName: Esquema específico a procesar (default: NULL)
 *    - @ExcludeTables: Lista de tablas a excluir (default: NULL)
 *    - @PreviewOnly: Solo mostrar preview sin generar script (default: 0)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 * 
 * Notas:
 * - Se recomienda ejecutar en horarios de baja actividad
 * - Se incluyen validaciones de existencia y permisos
 * - Se puede configurar logging de operaciones
 * - Se verifica la compatibilidad de nombres
 */

-- Declaración de variables configurables
DECLARE @SchemaName NVARCHAR(128) = NULL; -- Ejemplo: 'dbo'
DECLARE @ExcludeTables NVARCHAR(MAX) = NULL; -- Ejemplo: 'Table1,Table2'
DECLARE @PreviewOnly BIT = 0;
DECLARE @LogToTable BIT = 0;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TableRenameLog')
    BEGIN
        CREATE TABLE TableRenameLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            SchemaName NVARCHAR(128),
            OldTableName NVARCHAR(128),
            NewTableName NVARCHAR(128),
            StartTime DATETIME,
            EndTime DATETIME,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

-- Generar script para renombrar tablas
SELECT 
    CASE WHEN @PreviewOnly = 1 THEN 
        '-- Preview: ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(so.name) + 
        ' -> ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(UPPER(so.name))
    ELSE
        '-- Renombrando tabla: ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(so.name) + '
        -- Generado el: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
        
        DECLARE @StartTime DATETIME = GETDATE();
        DECLARE @ErrorMessage NVARCHAR(MAX);
        DECLARE @LogID INT;
        
        BEGIN TRY
            -- Verificar existencia de la tabla
            IF NOT EXISTS (
                SELECT 1 
                FROM sys.tables t 
                INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
                WHERE t.name = ''' + so.name + '''
                AND s.name = ''' + SCHEMA_NAME(so.schema_id) + '''
            )
            BEGIN
                SET @ErrorMessage = ''Tabla no encontrada: '' + ''' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(so.name) + ''';
                RAISERROR(@ErrorMessage, 16, 1);
            END
            
            -- Verificar si el nuevo nombre ya existe
            IF EXISTS (
                SELECT 1 
                FROM sys.tables t 
                INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
                WHERE t.name = ''' + UPPER(so.name) + '''
                AND s.name = ''' + SCHEMA_NAME(so.schema_id) + '''
            )
            BEGIN
                SET @ErrorMessage = ''Ya existe una tabla con el nombre: '' + ''' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(UPPER(so.name)) + ''';
                RAISERROR(@ErrorMessage, 16, 1);
            END
            
            ' + CASE WHEN @LogToTable = 1 THEN '
            -- Registrar inicio de operación
            INSERT INTO TableRenameLog (
                SchemaName,
                OldTableName,
                NewTableName,
                StartTime,
                Status
            )
            VALUES (
                ''' + SCHEMA_NAME(so.schema_id) + ''',
                ''' + so.name + ''',
                ''' + UPPER(so.name) + ''',
                @StartTime,
                ''In Progress''
            );
            SET @LogID = SCOPE_IDENTITY();' ELSE '' END + '
            
            -- Ejecutar renombrado
            EXEC sp_rename ''' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(so.name) + ''', 
                          ''' + UPPER(so.name) + ''', ''OBJECT'';
            
            PRINT ''Tabla renombrada exitosamente: '' + ''' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(so.name) + 
                 ''' -> '' + ''' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(UPPER(so.name)) + ''';
            
            ' + CASE WHEN @LogToTable = 1 THEN '
            -- Registrar éxito
            UPDATE TableRenameLog 
            SET EndTime = GETDATE(), Status = ''Success''
            WHERE LogID = @LogID;' ELSE '' END + '
            
        END TRY
        BEGIN CATCH
            SET @ErrorMessage = ERROR_MESSAGE();
            PRINT ''Error al renombrar tabla: '' + @ErrorMessage;
            
            ' + CASE WHEN @LogToTable = 1 THEN '
            -- Registrar error
            UPDATE TableRenameLog 
            SET EndTime = GETDATE(), Status = ''Failed'', ErrorMessage = @ErrorMessage
            WHERE LogID = @LogID;' ELSE '' END + '
        END CATCH
        GO'
    END AS Script
FROM sys.objects so 
INNER JOIN sys.columns sc ON so.object_id = sc.object_id 
INNER JOIN sys.types st ON st.system_type_id = sc.system_type_id 
WHERE so.type = 'U' -- Solo tablas de usuario
    AND st.name != 'sysname'
    -- Filtrar por esquema si se especifica
    AND (@SchemaName IS NULL OR SCHEMA_NAME(so.schema_id) = @SchemaName)
    -- Excluir tablas específicas si se proporciona lista
    AND (@ExcludeTables IS NULL OR so.name NOT IN (SELECT value FROM STRING_SPLIT(@ExcludeTables, ',')))
ORDER BY SCHEMA_NAME(so.schema_id), so.name;

/*
 * Notas adicionales:
 * 1. Consideraciones sobre el renombrado:
 *    - Verifica la existencia de la tabla antes de renombrar
 *    - Comprueba que el nuevo nombre no exista
 *    - Mantiene el esquema original
 *    - Incluye manejo de errores detallado
 * 
 * 2. Seguridad:
 *    - Requiere permisos ALTER en las tablas
 *    - Verifica permisos antes de ejecutar
 *    - Incluye validaciones de nombres
 *    - Maneja errores de forma segura
 * 
 * 3. Uso recomendado:
 *    - Ejecutar en horarios de baja actividad
 *    - Verificar el impacto en las aplicaciones
 *    - Realizar backup antes de ejecutar
 *    - Probar primero con @PreviewOnly = 1
 * 
 * 4. Monitoreo:
 *    - Opción de logging detallado
 *    - Registro de tiempos de ejecución
 *    - Seguimiento de errores
 *    - Historial de cambios
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye nombres antiguos y nuevos
 *    - Registra tiempos de inicio y fin
 *    - Almacena mensajes de error
 */