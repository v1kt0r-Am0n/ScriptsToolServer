/*
 * Script: detach_db.sql
 * Descripción: Desconecta (detach) una base de datos específica y muestra información
 *              sobre las bases de datos del servidor
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Reemplazar '_nombre de la base_' con el nombre de la base de datos a desconectar
 * 2. Ejecutar el script para desconectar la base de datos
 * 3. Revisar el resultado para confirmar la operación
 * 
 * Notas:
 * - Requiere permisos de administrador del servidor
 * - No opera en bases de datos del sistema
 * - Genera script para desconectar múltiples bases de datos
 */

USE [master];
GO

-- Configuración de variables
DECLARE @NombreBaseDatos NVARCHAR(128) = '_nombre de la base_';
DECLARE @Mensaje NVARCHAR(4000);
DECLARE @BasesExcluidas TABLE (NombreBase NVARCHAR(128));
DECLARE @Resultado INT;

-- Lista de bases de datos excluidas
INSERT INTO @BasesExcluidas (NombreBase)
VALUES 
    ('master'),
    ('tempdb'),
    ('model'),
    ('msdb'),
    ('ReportServer'),
    ('ReportServerTempDB'),
    ('Tfs_Configuration'),
    ('Tfs_DefaultCollection'),
    ('Tfs_PDV_Crediuno');

-- Verificar que la base de datos existe
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @NombreBaseDatos)
BEGIN
    SET @Mensaje = 'La base de datos ' + QUOTENAME(@NombreBaseDatos) + ' no existe.';
    RAISERROR(@Mensaje, 16, 1);
    RETURN;
END

-- Verificar que no es una base de datos excluida
IF EXISTS (SELECT 1 FROM @BasesExcluidas WHERE NombreBase = @NombreBaseDatos)
BEGIN
    SET @Mensaje = 'No se puede desconectar la base de datos ' + QUOTENAME(@NombreBaseDatos) + ' porque está en la lista de exclusiones.';
    RAISERROR(@Mensaje, 16, 1);
    RETURN;
END

-- Verificar que no hay conexiones activas
IF EXISTS (
    SELECT 1 
    FROM sys.dm_exec_sessions 
    WHERE database_id = DB_ID(@NombreBaseDatos)
)
BEGIN
    SET @Mensaje = 'Existen conexiones activas en la base de datos ' + QUOTENAME(@NombreBaseDatos) + 
                   '. Por favor, desconecte todos los usuarios antes de continuar.';
    RAISERROR(@Mensaje, 16, 1);
    RETURN;
END

-- Intentar desconectar la base de datos
BEGIN TRY
    EXEC @Resultado = master.dbo.sp_detach_db @dbname = @NombreBaseDatos;
    
    IF @Resultado = 0
        PRINT 'Base de datos ' + QUOTENAME(@NombreBaseDatos) + ' desconectada exitosamente.';
    ELSE
        RAISERROR('Error al desconectar la base de datos.', 16, 1);
END TRY
BEGIN CATCH
    SET @Mensaje = 'Error al desconectar la base de datos: ' + ERROR_MESSAGE();
    RAISERROR(@Mensaje, 16, 1);
END CATCH;

-- Mostrar información de bases de datos disponibles
SELECT 
    name AS NombreBaseDatos,
    database_id AS ID,
    create_date AS FechaCreacion,
    recovery_model_desc AS ModeloRecuperacion,
    state_desc AS Estado,
    user_access_desc AS AccesoUsuario,
    compatibility_level AS NivelCompatibilidad
FROM 
    sys.databases   
WHERE 
    name NOT IN (SELECT NombreBase FROM @BasesExcluidas)
ORDER BY 
    name;

-- Generar script para desconectar múltiples bases de datos
SELECT 
    'EXEC master.dbo.sp_detach_db @dbname = N''' + name + ''''
    + ' -- ' + 
    CASE 
        WHEN state_desc = 'ONLINE' THEN 'Base de datos en línea'
        WHEN state_desc = 'OFFLINE' THEN 'Base de datos fuera de línea'
        ELSE 'Estado: ' + state_desc
    END AS ScriptDesconexion
FROM 
    sys.databases   
WHERE 
    name NOT IN (SELECT NombreBase FROM @BasesExcluidas)
ORDER BY 
    name;

/*
 * Notas adicionales:
 * 1. Seguridad:
 *    - Requiere permisos de administrador del servidor
 *    - No opera en bases de datos del sistema
 *    - Verifica conexiones activas antes de desconectar
 *    - Lista de bases de datos excluidas configurable
 * 
 * 2. Consideraciones:
 *    - Asegurarse de que no haya transacciones activas
 *    - Verificar que no haya procesos en ejecución
 *    - Considerar el impacto en las aplicaciones
 *    - Hacer backup antes de desconectar
 * 
 * 3. Monitoreo:
 *    - Muestra información detallada de las bases de datos
 *    - Genera script para desconectar múltiples bases
 *    - Incluye estado y comentarios en el script generado
 * 
 * 4. Mejoras:
 *    - Manejo de errores mejorado
 *    - Validaciones de seguridad
 *    - Información detallada de bases de datos
 *    - Script generado con comentarios útiles
 */
