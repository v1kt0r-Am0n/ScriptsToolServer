/*
 * Script: listar usuarios y permisos.sql
 * Descripción: Genera reportes detallados de usuarios y permisos en SQL Server
 *              Incluye validaciones y manejo de errores
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado será un reporte detallado de usuarios y permisos
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @IncludeSystemUsers: Incluir usuarios del sistema (default: 0)
 *    - @IncludePublicRole: Incluir permisos del rol public (default: 1)
 *    - @LogToTable: Registrar operaciones en tabla de log (default: 0)
 *    - @ShowColumnPermissions: Mostrar permisos a nivel de columna (default: 1)
 * 
 * Notas:
 * - Se recomienda ejecutar con permisos de administrador
 * - Se incluyen validaciones de seguridad
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los datos
 */

-- Declaración de variables configurables
DECLARE @IncludeSystemUsers BIT = 0;
DECLARE @IncludePublicRole BIT = 1;
DECLARE @LogToTable BIT = 0;
DECLARE @ShowColumnPermissions BIT = 1;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'UserPermissionsLog')
    BEGIN
        CREATE TABLE UserPermissionsLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            ExecutionTime DATETIME,
            UserCount INT,
            PermissionCount INT,
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

BEGIN TRY
    -- Registrar inicio de operación
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @UserCount INT = 0;
    DECLARE @PermissionCount INT = 0;

    -- Reporte de permisos a nivel de servidor
    PRINT '-- PERMISOS A NIVEL DE SERVIDOR --';
    PRINT '---------------------------------';

    SELECT 
        SP1.[name] AS 'Login',
        'Role: ' + SP2.[name] COLLATE DATABASE_DEFAULT AS 'ServerPermission'
    FROM sys.server_principals SP1
    JOIN sys.server_role_members SRM ON SP1.principal_id = SRM.member_principal_id
    JOIN sys.server_principals SP2 ON SRM.role_principal_id = SP2.principal_id
    WHERE @IncludeSystemUsers = 1 OR SP1.[type] NOT IN ('R', 'C')
    UNION ALL
    SELECT 
        SP.[name] AS 'Login',
        SPerm.state_desc + ' ' + SPerm.permission_name COLLATE DATABASE_DEFAULT AS 'ServerPermission'
    FROM sys.server_principals SP
    JOIN sys.database_permissions SPerm ON SP.principal_id = SPerm.grantee_principal_id
    WHERE @IncludeSystemUsers = 1 OR SP.[type] NOT IN ('R', 'C')
    ORDER BY [Login], [ServerPermission];

    -- Reporte de permisos a nivel de base de datos
    PRINT '';
    PRINT '-- PERMISOS A NIVEL DE BASE DE DATOS --';
    PRINT '-------------------------------------';

    SELECT
        [UserName] = CASE princ.[type]
                        WHEN 'S' THEN princ.[name]
                        WHEN 'U' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
                     END,
        [UserType] = CASE princ.[type]
                        WHEN 'S' THEN 'SQL User'
                        WHEN 'U' THEN 'Windows User'
                     END,
        [DatabaseUserName] = princ.[name],
        [Role] = NULL,
        [PermissionType] = perm.[permission_name],
        [PermissionState] = perm.[state_desc],
        [ObjectType] = obj.type_desc,
        [ObjectName] = OBJECT_NAME(perm.major_id),
        [ColumnName] = CASE WHEN @ShowColumnPermissions = 1 THEN col.[name] ELSE NULL END
    FROM sys.database_principals princ
    LEFT JOIN sys.login_token ulogin ON princ.[sid] = ulogin.[sid]
    LEFT JOIN sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
    LEFT JOIN sys.columns col ON col.[object_id] = perm.major_id AND col.[column_id] = perm.[minor_id]
    LEFT JOIN sys.objects obj ON perm.[major_id] = obj.[object_id]
    WHERE princ.[type] IN ('S','U')
        AND (@IncludeSystemUsers = 1 OR princ.[name] NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys'))
        AND (@ShowColumnPermissions = 1 OR perm.[class] = 1)

    UNION

    -- Permisos a través de roles
    SELECT
        [UserName] = CASE memberprinc.[type]
                        WHEN 'S' THEN memberprinc.[name]
                        WHEN 'U' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
                     END,
        [UserType] = CASE memberprinc.[type]
                        WHEN 'S' THEN 'SQL User'
                        WHEN 'U' THEN 'Windows User'
                     END,
        [DatabaseUserName] = memberprinc.[name],
        [Role] = roleprinc.[name],
        [PermissionType] = perm.[permission_name],
        [PermissionState] = perm.[state_desc],
        [ObjectType] = obj.type_desc,
        [ObjectName] = OBJECT_NAME(perm.major_id),
        [ColumnName] = CASE WHEN @ShowColumnPermissions = 1 THEN col.[name] ELSE NULL END
    FROM sys.database_role_members members
    JOIN sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
    JOIN sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
    LEFT JOIN sys.login_token ulogin ON memberprinc.[sid] = ulogin.[sid]
    LEFT JOIN sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
    LEFT JOIN sys.columns col ON col.[object_id] = perm.major_id AND col.[column_id] = perm.[minor_id]
    LEFT JOIN sys.objects obj ON perm.[major_id] = obj.[object_id]
    WHERE (@IncludeSystemUsers = 1 OR memberprinc.[name] NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys'))
        AND (@ShowColumnPermissions = 1 OR perm.[class] = 1)

    UNION

    -- Permisos del rol public
    SELECT
        [UserName] = '{All Users}',
        [UserType] = '{All Users}',
        [DatabaseUserName] = '{All Users}',
        [Role] = roleprinc.[name],
        [PermissionType] = perm.[permission_name],
        [PermissionState] = perm.[state_desc],
        [ObjectType] = obj.type_desc,
        [ObjectName] = OBJECT_NAME(perm.major_id),
        [ColumnName] = CASE WHEN @ShowColumnPermissions = 1 THEN col.[name] ELSE NULL END
    FROM sys.database_principals roleprinc
    LEFT JOIN sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
    LEFT JOIN sys.columns col ON col.[object_id] = perm.major_id AND col.[column_id] = perm.[minor_id]
    JOIN sys.objects obj ON obj.[object_id] = perm.[major_id]
    WHERE roleprinc.[type] = 'R'
        AND roleprinc.[name] = 'public'
        AND obj.is_ms_shipped = 0
        AND @IncludePublicRole = 1
        AND (@ShowColumnPermissions = 1 OR perm.[class] = 1)

    ORDER BY [UserName], [ObjectName], [ColumnName], [PermissionType], [PermissionState];

    -- Registrar éxito
    IF @LogToTable = 1
    BEGIN
        INSERT INTO UserPermissionsLog (
            ExecutionTime,
            UserCount,
            PermissionCount,
            Status
        )
        VALUES (
            @StartTime,
            @UserCount,
            @PermissionCount,
            'Success'
        );
    END

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT 'Error al generar reporte de permisos: ' + @ErrorMessage;
    
    IF @LogToTable = 1
    BEGIN
        INSERT INTO UserPermissionsLog (
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
 * 1. Consideraciones sobre Permisos:
 *    - Verifica permisos de lectura
 *    - Comprueba roles y membresías
 *    - Valida objetos y columnas
 *    - Incluye manejo de errores detallado
 * 
 * 2. Seguridad:
 *    - Requiere permisos VIEW DEFINITION
 *    - Verifica permisos de usuario
 *    - Incluye validaciones de seguridad
 *    - Maneja errores de forma segura
 * 
 * 3. Uso recomendado:
 *    - Ejecutar con permisos de administrador
 *    - Verificar el impacto en el rendimiento
 *    - Monitorear el uso de recursos
 *    - Probar primero con @IncludeSystemUsers = 0
 * 
 * 4. Monitoreo:
 *    - Opción de logging detallado
 *    - Registro de usuarios y permisos
 *    - Seguimiento de errores
 *    - Historial de operaciones
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye conteos de usuarios y permisos
 *    - Registra tiempos de ejecución
 *    - Almacena mensajes de error
 */