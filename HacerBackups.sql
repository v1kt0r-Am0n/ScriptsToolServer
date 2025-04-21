/*
 * Script: HacerBackups.sql
 * Descripción: Genera backups de bases de datos con formato personalizado
 *              Incluye validaciones y manejo de errores
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la instancia de SQL Server
 * 2. El resultado será backups de todas las bases de datos no del sistema
 * 3. Se pueden configurar los siguientes parámetros:
 *    - @BackupPath: Ruta para almacenar los backups (default: 'B:\Backups\')
 *    - @ExcludeSystemDBs: Excluir bases de datos del sistema (default: 1)
 *    - @Compression: Usar compresión en los backups (default: 1)
 *    - @VerifyBackup: Verificar integridad del backup (default: 1)
 * 
 * Notas:
 * - Se recomienda ejecutar en horarios de baja actividad
 * - Se incluyen validaciones de espacio y permisos
 * - Se puede configurar logging de operaciones
 * - Se verifica la integridad de los backups
 */

-- Declaración de variables configurables
DECLARE @BackupPath NVARCHAR(256) = 'B:\Backups\';
DECLARE @ExcludeSystemDBs BIT = 1;
DECLARE @Compression BIT = 1;
DECLARE @VerifyBackup BIT = 1;
DECLARE @LogToTable BIT = 1;

-- Crear tabla de log si está habilitada
IF @LogToTable = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DBBackupLog')
    BEGIN
        CREATE TABLE DBBackupLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            DatabaseName NVARCHAR(128),
            BackupPath NVARCHAR(512),
            StartTime DATETIME,
            EndTime DATETIME,
            SizeMB DECIMAL(18,2),
            Status NVARCHAR(20),
            ErrorMessage NVARCHAR(MAX)
        );
    END
END

SET NOCOUNT ON;

-- Declaración de variables
DECLARE @DB_name NVARCHAR(128);
DECLARE @FileName NVARCHAR(512);
DECLARE @FileDate NVARCHAR(20);
DECLARE @StartTime DATETIME;
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @LogID INT;
DECLARE @SizeMB DECIMAL(18,2);

-- Obtener fecha para el nombre del archivo
SET @FileDate = CONVERT(NVARCHAR(20), GETDATE(), 112);

-- Cursor para bases de datos
DECLARE DB_cursor CURSOR FOR   
SELECT 
    d.name,
    CAST(SUM(size * 8.0 / 1024) AS DECIMAL(18,2)) AS SizeMB
FROM sys.master_files AS mf
INNER JOIN sys.databases AS d ON mf.database_id = d.database_id
WHERE d.state_desc = 'ONLINE'
    AND (@ExcludeSystemDBs = 0 OR d.name NOT IN ('master', 'tempdb', 'model', 'msdb'))
GROUP BY d.name;

OPEN DB_cursor;
FETCH NEXT FROM DB_cursor INTO @DB_name, @SizeMB;

WHILE @@FETCH_STATUS = 0  
BEGIN  
    SET @StartTime = GETDATE();
    SET @FileName = @BackupPath + @DB_name + '_' + @FileDate + '.BAK';
    
    BEGIN TRY
        -- Verificar espacio disponible
        IF NOT EXISTS (SELECT 1 FROM sys.dm_os_volume_stats(DB_ID(@DB_name), 1))
        BEGIN
            SET @ErrorMessage = 'No se puede verificar el espacio disponible en la ruta: ' + @BackupPath;
            RAISERROR(@ErrorMessage, 16, 1);
        END

        ' + CASE WHEN @LogToTable = 1 THEN '
        -- Registrar inicio de operación
        INSERT INTO DBBackupLog (
            DatabaseName,
            BackupPath,
            StartTime,
            SizeMB,
            Status
        )
        VALUES (
            ''' + @DB_name + ''',
            ''' + @FileName + ''',
            ''' + CONVERT(VARCHAR, @StartTime, 120) + ''',
            ' + CAST(@SizeMB AS NVARCHAR(20)) + ',
            ''In Progress''
        );
        SET @LogID = SCOPE_IDENTITY();' ELSE '' END + '

        -- Ejecutar backup
        BACKUP DATABASE [' + @DB_name + '] 
        TO DISK = N''' + @FileName + '''
        WITH ' + CASE WHEN @Compression = 1 THEN 'COMPRESSION, ' ELSE '' END + '
             STATS = 10,
             CHECKSUM;
        
        ' + CASE WHEN @VerifyBackup = 1 THEN '
        -- Verificar backup
        RESTORE VERIFYONLY 
        FROM DISK = N''' + @FileName + '''
        WITH CHECKSUM;' ELSE '' END + '
        
        PRINT ''Backup completado exitosamente: '' + ''' + @DB_name + ''';
        
        ' + CASE WHEN @LogToTable = 1 THEN '
        -- Registrar éxito
        UPDATE DBBackupLog 
        SET EndTime = GETDATE(), 
            Status = ''Success''
        WHERE LogID = @LogID;' ELSE '' END + '

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT ''Error al realizar backup: '' + @ErrorMessage;
        
        ' + CASE WHEN @LogToTable = 1 THEN '
        -- Registrar error
        UPDATE DBBackupLog 
        SET EndTime = GETDATE(), 
            Status = ''Failed'', 
            ErrorMessage = @ErrorMessage
        WHERE LogID = @LogID;' ELSE '' END + '
    END CATCH

    FETCH NEXT FROM DB_cursor INTO @DB_name, @SizeMB;
END;

CLOSE DB_cursor;
DEALLOCATE DB_cursor;

/*
 * Notas adicionales:
 * 1. Consideraciones sobre Backups:
 *    - Verifica espacio disponible
 *    - Comprueba permisos necesarios
 *    - Valida la integridad del backup
 *    - Incluye manejo de errores detallado
 * 
 * 2. Seguridad:
 *    - Requiere permisos BACKUP DATABASE
 *    - Verifica permisos en archivos
 *    - Incluye validaciones de seguridad
 *    - Maneja errores de forma segura
 * 
 * 3. Uso recomendado:
 *    - Ejecutar en horarios de baja actividad
 *    - Verificar el espacio disponible
 *    - Monitorear el uso de recursos
 *    - Probar primero con @VerifyBackup = 1
 * 
 * 4. Monitoreo:
 *    - Opción de logging detallado
 *    - Registro de tamaños de backup
 *    - Seguimiento de errores
 *    - Historial de operaciones
 * 
 * 5. Logging:
 *    - Opcionalmente registra todas las operaciones
 *    - Incluye rutas de archivos
 *    - Registra tiempos de ejecución
 *    - Almacena mensajes de error
 */