/*
 * Script: GenerarScriptAUTO_SHRINK.sql
 * Descripción: Genera scripts para configurar AUTO_SHRINK y RECOVERY SIMPLE en bases de datos
 *              Excluye bases de datos del sistema y permite configuración personalizada
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado serán dos scripts que se pueden ejecutar para:
 *    - Configurar RECOVERY SIMPLE
 *    - Habilitar AUTO_SHRINK
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @ExcludeSystemDBs: Excluir bases de datos del sistema (default: 1)
 *    - @IncludeDBList: Lista de bases de datos específicas a incluir (default: NULL)
 *    - @ExcludeDBList: Lista de bases de datos específicas a excluir (default: NULL)
 * 
 * Notas:
 * - AUTO_SHRINK puede causar fragmentación y afectar el rendimiento
 * - RECOVERY SIMPLE limita las opciones de recuperación
 * - Se recomienda ejecutar en horarios de baja actividad
 * - Se incluyen validaciones de estado y configuración actual
 */

-- Declaración de variables configurables
DECLARE @ExcludeSystemDBs BIT = 1;
DECLARE @IncludeDBList NVARCHAR(MAX) = NULL; -- Ejemplo: 'DB1,DB2,DB3'
DECLARE @ExcludeDBList NVARCHAR(MAX) = NULL; -- Ejemplo: 'DB4,DB5,DB6'

-- Generar script para configurar RECOVERY SIMPLE
SELECT '-- Script para configurar RECOVERY SIMPLE
-- Generado el: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
-- Instancia: ' + @@SERVERNAME + '

USE master;
GO

-- Verificar estado actual y configurar RECOVERY SIMPLE
IF EXISTS (
    SELECT 1 
    FROM sys.databases 
    WHERE name = ''' + name + ''' 
    AND recovery_model_desc <> ''SIMPLE''
    AND state = 0
)
BEGIN
    PRINT ''Configurando RECOVERY SIMPLE para: ' + name + ''';
    
    BEGIN TRY
        ALTER DATABASE [' + name + '] 
        SET RECOVERY SIMPLE 
        WITH NO_WAIT;
        PRINT ''    - Configuración exitosa'';
    END TRY
    BEGIN CATCH
        PRINT ''    - Error: '' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT ''La base de datos ' + name + ' ya está en modo SIMPLE o no está disponible'';
END
GO
'
FROM sys.databases   
WHERE 
    -- Excluir bases de datos del sistema si está configurado
    (@ExcludeSystemDBs = 0 OR name NOT IN ('master', 'tempdb', 'model', 'msdb'))
    -- Incluir solo bases de datos específicas si se proporciona lista
    AND (@IncludeDBList IS NULL OR name IN (SELECT value FROM STRING_SPLIT(@IncludeDBList, ',')))
    -- Excluir bases de datos específicas si se proporciona lista
    AND (@ExcludeDBList IS NULL OR name NOT IN (SELECT value FROM STRING_SPLIT(@ExcludeDBList, ',')))
    -- Solo bases de datos en línea
    AND state = 0
ORDER BY name;

-- Separador entre scripts
PRINT 'GO';
PRINT '-- =============================================';
PRINT 'GO';

-- Generar script para configurar AUTO_SHRINK
SELECT '-- Script para configurar AUTO_SHRINK
-- Generado el: ' + CONVERT(VARCHAR, GETDATE(), 120) + '
-- Instancia: ' + @@SERVERNAME + '

USE master;
GO

-- Verificar estado actual y configurar AUTO_SHRINK
IF EXISTS (
    SELECT 1 
    FROM sys.databases 
    WHERE name = ''' + name + ''' 
    AND is_auto_shrink_on = 0
    AND state = 0
)
BEGIN
    PRINT ''Configurando AUTO_SHRINK para: ' + name + ''';
    
    BEGIN TRY
        ALTER DATABASE [' + name + '] 
        SET AUTO_SHRINK ON 
        WITH NO_WAIT;
        PRINT ''    - Configuración exitosa'';
    END TRY
    BEGIN CATCH
        PRINT ''    - Error: '' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT ''La base de datos ' + name + ' ya tiene AUTO_SHRINK habilitado o no está disponible'';
END
GO
'
FROM sys.databases   
WHERE 
    -- Excluir bases de datos del sistema si está configurado
    (@ExcludeSystemDBs = 0 OR name NOT IN ('master', 'tempdb', 'model', 'msdb'))
    -- Incluir solo bases de datos específicas si se proporciona lista
    AND (@IncludeDBList IS NULL OR name IN (SELECT value FROM STRING_SPLIT(@IncludeDBList, ',')))
    -- Excluir bases de datos específicas si se proporciona lista
    AND (@ExcludeDBList IS NULL OR name NOT IN (SELECT value FROM STRING_SPLIT(@ExcludeDBList, ',')))
    -- Solo bases de datos en línea
    AND state = 0
ORDER BY name;

/*
 * Notas adicionales:
 * 1. Consideraciones sobre RECOVERY SIMPLE:
 *    - No permite recuperación a un punto en el tiempo
 *    - Reduce el tamaño del log de transacciones
 *    - Ideal para bases de datos de desarrollo o testing
 *    - No recomendado para bases de datos de producción críticas
 * 
 * 2. Consideraciones sobre AUTO_SHRINK:
 *    - Puede causar fragmentación de índices
 *    - Puede afectar el rendimiento durante la operación
 *    - El espacio liberado vuelve al sistema operativo
 *    - Se recomienda monitorear el impacto en el rendimiento
 * 
 * 3. Seguridad:
 *    - Requiere permisos ALTER DATABASE
 *    - Verifica el estado de la base de datos antes de actuar
 *    - Incluye manejo de errores para cada operación
 * 
 * 4. Uso recomendado:
 *    - Ejecutar en horarios de baja actividad
 *    - Monitorear el impacto en el rendimiento
 *    - Considerar alternativas como SHRINKFILE manual
 *    - Realizar backup antes de aplicar cambios
 * 
 * 5. Monitoreo:
 *    - Verificar fragmentación después de AUTO_SHRINK
 *    - Monitorear crecimiento del log de transacciones
 *    - Revisar estadísticas de rendimiento
 *    - Considerar reorganización de índices si es necesario
 */
