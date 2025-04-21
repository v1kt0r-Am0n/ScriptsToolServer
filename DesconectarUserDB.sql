/*
 * Script: DesconectarUserDB.sql
 * Descripción: Desconecta todos los usuarios de una base de datos específica
 *              y muestra información sobre los usuarios del servidor
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Reemplazar '_nombre de la base_' con el nombre de la base de datos
 * 2. Ejecutar el script para desconectar usuarios
 * 3. Revisar el resultado para confirmar las desconexiones
 * 
 * Notas:
 * - Requiere permisos de administrador del servidor
 * - Desconecta todos los usuarios de la base de datos especificada
 * - Muestra información sobre los usuarios del servidor
 */

USE master;
GO

-- Configuración de variables
DECLARE @NombreBaseDatos NVARCHAR(128) = '_nombre de la base_';
DECLARE @SPID INT;
DECLARE @NombreDB NVARCHAR(128);
DECLARE @NumUsuariosDesconectados INT = 0;
DECLARE @Mensaje NVARCHAR(4000);

-- Verificar que la base de datos existe
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @NombreBaseDatos)
BEGIN
    SET @Mensaje = 'La base de datos ' + QUOTENAME(@NombreBaseDatos) + ' no existe.';
    RAISERROR(@Mensaje, 16, 1);
    RETURN;
END

-- Verificar que no es una base de datos del sistema
IF @NombreBaseDatos IN ('master', 'tempdb', 'model', 'msdb')
BEGIN
    SET @Mensaje = 'No se pueden desconectar usuarios de bases de datos del sistema: ' + QUOTENAME(@NombreBaseDatos);
    RAISERROR(@Mensaje, 16, 1);
    RETURN;
END

-- Crear cursor para desconectar usuarios
DECLARE curDesconectarUsuarios CURSOR FOR
    SELECT 
        sp.spid,
        db.name AS dbname
    FROM 
        sys.sysprocesses sp
        INNER JOIN sys.databases db ON sp.dbid = db.database_id
    WHERE 
        db.name = @NombreBaseDatos
        AND sp.spid > 50  -- Excluir procesos del sistema
        AND sp.spid <> @@SPID  -- Excluir la conexión actual
    FOR READ ONLY;

-- Iniciar proceso de desconexión
BEGIN TRY
    OPEN curDesconectarUsuarios;
    
    FETCH NEXT FROM curDesconectarUsuarios
    INTO @SPID, @NombreDB;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC('KILL ' + @SPID);
            SET @NumUsuariosDesconectados = @NumUsuariosDesconectados + 1;
        END TRY
        BEGIN CATCH
            SET @Mensaje = 'Error al desconectar SPID ' + CAST(@SPID AS NVARCHAR(10)) + ': ' + ERROR_MESSAGE();
            PRINT @Mensaje;
        END CATCH
        
        FETCH NEXT FROM curDesconectarUsuarios
        INTO @SPID, @NombreDB;
    END;
    
    CLOSE curDesconectarUsuarios;
    DEALLOCATE curDesconectarUsuarios;
    
    -- Mostrar resultado
    PRINT 'Se desconectaron ' + CAST(@NumUsuariosDesconectados AS NVARCHAR(10)) + ' usuarios de la base de datos ' + QUOTENAME(@NombreBaseDatos);
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('global', 'curDesconectarUsuarios') >= 0
    BEGIN
        CLOSE curDesconectarUsuarios;
        DEALLOCATE curDesconectarUsuarios;
    END
    
    SET @Mensaje = 'Error durante el proceso de desconexión: ' + ERROR_MESSAGE();
    RAISERROR(@Mensaje, 16, 1);
END CATCH;

-- Mostrar información de usuarios del servidor
SELECT 
    name AS NombreUsuario,
    type_desc AS TipoUsuario,
    create_date AS FechaCreacion,
    default_database_name AS BaseDatosPorDefecto,
    is_disabled AS Deshabilitado
FROM 
    sys.server_principals 
WHERE 
    type = 'S'  -- Usuarios SQL
    AND name NOT IN ('guest', 'INFORMATION_SCHEMA', 'sys')
ORDER BY 
    name;

/*
 * Notas adicionales:
 * 1. Seguridad:
 *    - Requiere permisos de administrador del servidor
 *    - No desconecta procesos del sistema (SPID <= 50)
 *    - No desconecta la conexión actual
 *    - No opera en bases de datos del sistema
 * 
 * 2. Consideraciones:
 *    - Las desconexiones son forzadas (KILL)
 *    - Se recomienda notificar a los usuarios antes de ejecutar
 *    - Verificar que no haya transacciones críticas en curso
 *    - Considerar el impacto en las aplicaciones conectadas
 * 
 * 3. Monitoreo:
 *    - Se muestra el número de usuarios desconectados
 *    - Se listan los errores durante el proceso
 *    - Se muestra información de usuarios del servidor
 * 
 * 4. Mejoras:
 *    - Manejo de errores mejorado
 *    - Validaciones de seguridad
 *    - Información detallada de usuarios
 *    - Exclusión de procesos del sistema
 */


