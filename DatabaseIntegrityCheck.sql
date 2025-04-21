/*
 * Script: DatabaseIntegrityCheck.sql
 * Descripción: Ejecuta verificaciones de integridad en las bases de datos del servidor
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Asegurarse de que el procedimiento dbo.DatabaseIntegrityCheck exista
 * 2. Configurar los parámetros según sea necesario
 * 3. Ejecutar el script para realizar las verificaciones
 * 
 * Notas:
 * - Realiza verificaciones de integridad física y lógica
 * - Puede ejecutarse en todas las bases de datos o en una selección específica
 * - Incluye opciones para controlar el nivel de verificación
 */

-- Configuración de parámetros
DECLARE @Databases NVARCHAR(MAX) = 'USER_DATABASES';  -- Bases de datos a verificar
DECLARE @CheckCommands NVARCHAR(MAX) = 'CHECKDB';     -- Tipo de verificación
DECLARE @PhysicalOnly CHAR(1) = 'Y';                  -- Solo verificación física
DECLARE @LogToTable CHAR(1) = 'Y';                    -- Registrar en tabla de logs
DECLARE @Execute CHAR(1) = 'Y';                       -- Ejecutar verificaciones
DECLARE @Mode INT = 2;                                -- Modo de ejecución (1: Simple, 2: Con manejo de errores)

-- Verificar existencia del procedimiento
IF NOT EXISTS (
    SELECT 1 
    FROM sys.procedures 
    WHERE name = 'DatabaseIntegrityCheck' 
    AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    RAISERROR('El procedimiento dbo.DatabaseIntegrityCheck no existe.', 16, 1);
    RETURN;
END

-- Ejecutar verificación de integridad
BEGIN TRY
    EXECUTE dbo.DatabaseIntegrityCheck
        @Databases = @Databases,
        @CheckCommands = @CheckCommands,
        @PhysicalOnly = @PhysicalOnly,
        @LogToTable = @LogToTable,
        @Execute = @Execute,
        @Mode = @Mode;

    PRINT 'Verificación de integridad completada exitosamente.';
END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;

/*
 * Notas adicionales:
 * 1. Parámetros configurables:
 *    @Databases: 
 *      - 'USER_DATABASES': Todas las bases de datos de usuario
 *      - 'SYSTEM_DATABASES': Bases de datos del sistema
 *      - 'ALL_DATABASES': Todas las bases de datos
 *      - Lista específica: 'DB1,DB2,DB3'
 * 
 *    @CheckCommands:
 *      - 'CHECKDB': Verificación completa
 *      - 'CHECKFILEGROUP': Verificación por grupo de archivos
 *      - 'CHECKTABLE': Verificación por tabla
 *      - 'CHECKALLOC': Verificación de asignación
 *      - 'CHECKCATALOG': Verificación del catálogo
 * 
 *    @PhysicalOnly:
 *      - 'Y': Solo verificación física
 *      - 'N': Verificación física y lógica
 * 
 * 2. Consideraciones de rendimiento:
 *    - Las verificaciones pueden consumir muchos recursos
 *    - Se recomienda ejecutar en horarios de bajo uso
 *    - Considerar el uso de @PhysicalOnly = 'Y' para verificaciones más rápidas
 * 
 * 3. Seguridad:
 *    - Requiere permisos de administrador de base de datos
 *    - Se recomienda ejecutar con una cuenta con privilegios suficientes
 *    - Considerar el impacto en la disponibilidad de las bases de datos
 * 
 * 4. Monitoreo:
 *    - Si @LogToTable = 'Y', los resultados se guardan en la tabla de logs
 *    - Revisar los logs para identificar problemas de integridad
 *    - Monitorear el tiempo de ejecución y los recursos utilizados
 */