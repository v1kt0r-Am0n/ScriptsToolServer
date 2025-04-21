USE [master]
GO

/*
 * Script: CreacionUsuarios.sql
 * Descripción: Genera scripts para crear logins y usuarios de base de datos con permisos de lectura y escritura
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script para generar los comandos SQL
 * 2. Revisar y ajustar los comandos generados según sea necesario
 * 3. Ejecutar los comandos generados para crear los usuarios
 * 
 * Notas:
 * - Genera logins y usuarios para todas las bases de datos excepto las del sistema
 * - Asigna permisos de lectura (db_datareader) y escritura (db_datawriter)
 * - Usa un formato de nombre de usuario consistente: UsrDB[nombre_base]
 */

-- Configuración de variables
DECLARE @Password NVARCHAR(100) = 'P4$$W0rdDB.'; -- Contraseña por defecto
DECLARE @DefaultDatabase NVARCHAR(128) = 'master';
DECLARE @CheckExpiration BIT = 0; -- OFF
DECLARE @CheckPolicy BIT = 0;     -- OFF

-- Generar script para crear logins
SELECT 
    '-- Crear login para la base de datos: ' + name + CHAR(13) + CHAR(10) +
    'CREATE LOGIN [UsrDB' + name + '] WITH ' + CHAR(13) + CHAR(10) +
    '    PASSWORD = N''' + @Password + ''',' + CHAR(13) + CHAR(10) +
    '    DEFAULT_DATABASE = [' + @DefaultDatabase + '],' + CHAR(13) + CHAR(10) +
    '    CHECK_EXPIRATION = ' + CASE WHEN @CheckExpiration = 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) + CHAR(10) +
    '    CHECK_POLICY = ' + CASE WHEN @CheckPolicy = 1 THEN 'ON' ELSE 'OFF' END + CHAR(13) + CHAR(10) +
    'GO' + CHAR(13) + CHAR(10)
FROM sys.databases   
WHERE name NOT IN (
    'master',
    'tempdb',
    'model',
    'msdb'
)
ORDER BY name;

-- Generar script para crear usuarios y asignar roles
SELECT 
    '-- Configurar usuario y permisos para la base de datos: ' + name + CHAR(13) + CHAR(10) +
    'USE [' + name + ']' + CHAR(13) + CHAR(10) +
    'GO' + CHAR(13) + CHAR(10) +
    '-- Crear usuario' + CHAR(13) + CHAR(10) +
    'CREATE USER [UsrDB' + name + '] FOR LOGIN [UsrDB' + name + ']' + CHAR(13) + CHAR(10) +
    'GO' + CHAR(13) + CHAR(10) +
    '-- Asignar rol de lectura' + CHAR(13) + CHAR(10) +
    'ALTER ROLE [db_datareader] ADD MEMBER [UsrDB' + name + ']' + CHAR(13) + CHAR(10) +
    'GO' + CHAR(13) + CHAR(10) +
    '-- Asignar rol de escritura' + CHAR(13) + CHAR(10) +
    'ALTER ROLE [db_datawriter] ADD MEMBER [UsrDB' + name + ']' + CHAR(13) + CHAR(10) +
    'GO' + CHAR(13) + CHAR(10)
FROM sys.databases   
WHERE name NOT IN (
    'master',
    'tempdb',
    'model',
    'msdb'
)
ORDER BY name;

/*
 * Notas adicionales:
 * 1. Seguridad:
 *    - Se recomienda cambiar la contraseña por defecto después de la creación
 *    - Considerar habilitar CHECK_POLICY para forzar políticas de contraseña
 *    - Considerar habilitar CHECK_EXPIRATION para forzar cambio periódico de contraseñas
 * 
 * 2. Permisos:
 *    - db_datareader: Permite lectura en todas las tablas
 *    - db_datawriter: Permite inserción, actualización y eliminación en todas las tablas
 *    - Considerar asignar permisos más granulares según sea necesario
 * 
 * 3. Mantenimiento:
 *    - Revisar periódicamente los usuarios y sus permisos
 *    - Documentar cualquier cambio en los permisos asignados
 *    - Mantener un registro de las contraseñas en un lugar seguro
 * 
 * 4. Consideraciones:
 *    - El script excluye las bases de datos del sistema por seguridad
 *    - Se puede modificar la lista de exclusiones según sea necesario
 *    - El formato de nombre de usuario se puede personalizar
 */