USE [master]
GO

/*
 * Script: CommandExecute.sql
 * Descripción: Procedimiento almacenado para ejecutar comandos SQL de manera controlada y segura
 *              con capacidades de logging y manejo de errores.
 * Autor: Ola Hallengren
 * Fecha: 21/07/2019
 * Versión: 2018-07-16 18:32:21
 * 
 * Fuente: https://ola.hallengren.com
 * Licencia: https://ola.hallengren.com/license.html
 * GitHub: https://github.com/olahallengren/sql-server-maintenance-solution
 */

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CommandExecute]
    @Command nvarchar(max),                    -- Comando SQL a ejecutar
    @CommandType nvarchar(max),                -- Tipo de comando (ej: 'BACKUP', 'DBCC', etc.)
    @Mode int,                                 -- Modo de ejecución (1: Simple, 2: Con manejo de errores)
    @Comment nvarchar(max) = NULL,             -- Comentario opcional sobre el comando
    @DatabaseName nvarchar(max) = NULL,        -- Nombre de la base de datos
    @SchemaName nvarchar(max) = NULL,          -- Nombre del esquema
    @ObjectName nvarchar(max) = NULL,          -- Nombre del objeto
    @ObjectType nvarchar(max) = NULL,          -- Tipo de objeto
    @IndexName nvarchar(max) = NULL,           -- Nombre del índice
    @IndexType int = NULL,                     -- Tipo de índice
    @StatisticsName nvarchar(max) = NULL,      -- Nombre de las estadísticas
    @PartitionNumber int = NULL,               -- Número de partición
    @ExtendedInfo xml = NULL,                  -- Información extendida en formato XML
    @LockMessageSeverity int = 16,             -- Severidad del mensaje para bloqueos (10: Info, 16: Error)
    @LogToTable nvarchar(max),                 -- Indicador para guardar log en tabla ('Y'/'N')
    @Execute nvarchar(max)                     -- Indicador para ejecutar comando ('Y'/'N')
AS
BEGIN
    /*
     * Descripción detallada:
     * Este procedimiento permite ejecutar comandos SQL de manera controlada, con las siguientes características:
     * - Validación de parámetros
     * - Manejo de errores configurable
     * - Logging de ejecución
     * - Medición de tiempo de ejecución
     * - Soporte para diferentes modos de ejecución
     * 
     * Parámetros obligatorios:
     * @Command: Comando SQL a ejecutar
     * @CommandType: Tipo de comando (máximo 60 caracteres)
     * @Mode: 1 (Simple) o 2 (Con manejo de errores)
     * @LogToTable: 'Y' para guardar log, 'N' para no guardar
     * @Execute: 'Y' para ejecutar, 'N' para solo validar
     * 
     * Requisitos:
     * - Nivel de compatibilidad de base de datos >= 90
     * - ANSI_NULLS y QUOTED_IDENTIFIER deben estar activados
     * - Si @LogToTable = 'Y', debe existir la tabla dbo.CommandLog
     */

    SET NOCOUNT ON

    -- Declaración de variables
    DECLARE @StartMessage nvarchar(max)
    DECLARE @EndMessage nvarchar(max)
    DECLARE @ErrorMessage nvarchar(max)
    DECLARE @ErrorMessageOriginal nvarchar(max)
    DECLARE @Severity int
    DECLARE @StartTime datetime
    DECLARE @EndTime datetime
    DECLARE @StartTimeSec datetime
    DECLARE @EndTimeSec datetime
    DECLARE @ID int
    DECLARE @Error int
    DECLARE @ReturnCode int

    SET @Error = 0
    SET @ReturnCode = 0

    -- Validación de requisitos básicos
    IF NOT (SELECT [compatibility_level] FROM sys.databases WHERE database_id = DB_ID()) >= 90
    BEGIN
        SET @ErrorMessage = 'La base de datos ' + QUOTENAME(DB_NAME(DB_ID())) + ' debe tener nivel de compatibilidad 90 o superior.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF NOT (SELECT uses_ansi_nulls FROM sys.sql_modules WHERE [object_id] = @@PROCID) = 1
    BEGIN
        SET @ErrorMessage = 'ANSI_NULLS debe estar activado para este procedimiento almacenado.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF NOT (SELECT uses_quoted_identifier FROM sys.sql_modules WHERE [object_id] = @@PROCID) = 1
    BEGIN
        SET @ErrorMessage = 'QUOTED_IDENTIFIER debe estar activado para este procedimiento almacenado.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF @LogToTable = 'Y' AND NOT EXISTS (
        SELECT * FROM sys.objects objects 
        INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] 
        WHERE objects.[type] = 'U' 
        AND schemas.[name] = 'dbo' 
        AND objects.[name] = 'CommandLog'
    )
    BEGIN
        SET @ErrorMessage = 'La tabla CommandLog no existe. Descargue https://ola.hallengren.com/scripts/CommandLog.sql.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF @Error <> 0
    BEGIN
        SET @ReturnCode = @Error
        GOTO ReturnCode
    END

    -- Validación de parámetros de entrada
    IF @Command IS NULL OR @Command = ''
    BEGIN
        SET @ErrorMessage = 'El valor del parámetro @Command no es válido.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF @CommandType IS NULL OR @CommandType = '' OR LEN(@CommandType) > 60
    BEGIN
        SET @ErrorMessage = 'El valor del parámetro @CommandType no es válido.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF @Mode NOT IN(1,2) OR @Mode IS NULL
    BEGIN
        SET @ErrorMessage = 'El valor del parámetro @Mode no es válido.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF @LockMessageSeverity NOT IN(10,16) OR @LockMessageSeverity IS NULL
    BEGIN
        SET @ErrorMessage = 'El valor del parámetro @LockMessageSeverity no es válido.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF @LogToTable NOT IN('Y','N') OR @LogToTable IS NULL
    BEGIN
        SET @ErrorMessage = 'El valor del parámetro @LogToTable no es válido.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF @Execute NOT IN('Y','N') OR @Execute IS NULL
    BEGIN
        SET @ErrorMessage = 'El valor del parámetro @Execute no es válido.'
        RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT
        SET @Error = @@ERROR
    END

    IF @Error <> 0
    BEGIN
        SET @ReturnCode = @Error
        GOTO ReturnCode
    END

    -- Registro de información inicial
    SET @StartTime = GETDATE()
    SET @StartTimeSec = CONVERT(datetime,CONVERT(nvarchar,@StartTime,120),120)

    SET @StartMessage = 'Fecha y hora: ' + CONVERT(nvarchar,@StartTimeSec,120)
    RAISERROR(@StartMessage, 10, 1) WITH NOWAIT

    SET @StartMessage = 'Comando: ' + @Command
    SET @StartMessage = REPLACE(@StartMessage,'%','%%')
    RAISERROR(@StartMessage, 10, 1) WITH NOWAIT

    IF @Comment IS NOT NULL
    BEGIN
        SET @StartMessage = 'Comentario: ' + @Comment
        SET @StartMessage = REPLACE(@StartMessage,'%','%%')
        RAISERROR(@StartMessage, 10, 1) WITH NOWAIT
    END

    IF @LogToTable = 'Y'
    BEGIN
        INSERT INTO dbo.CommandLog (
            DatabaseName, SchemaName, ObjectName, ObjectType, 
            IndexName, IndexType, StatisticsName, PartitionNumber, 
            ExtendedInfo, CommandType, Command, StartTime
        )
        VALUES (
            @DatabaseName, @SchemaName, @ObjectName, @ObjectType, 
            @IndexName, @IndexType, @StatisticsName, @PartitionNumber, 
            @ExtendedInfo, @CommandType, @Command, @StartTime
        )
    END

    SET @ID = SCOPE_IDENTITY()

    -- Ejecución del comando
    IF @Mode = 1 AND @Execute = 'Y'
    BEGIN
        EXECUTE(@Command)
        SET @Error = @@ERROR
        SET @ReturnCode = @Error
    END

    IF @Mode = 2 AND @Execute = 'Y'
    BEGIN
        BEGIN TRY
            EXECUTE(@Command)
        END TRY
        BEGIN CATCH
            SET @Error = ERROR_NUMBER()
            SET @ErrorMessageOriginal = ERROR_MESSAGE()

            SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'')
            SET @Severity = CASE WHEN ERROR_NUMBER() IN(1205,1222) THEN @LockMessageSeverity ELSE 16 END
            RAISERROR(@ErrorMessage, @Severity, 1) WITH NOWAIT

            IF NOT (ERROR_NUMBER() IN(1205,1222) AND @LockMessageSeverity = 10)
            BEGIN
                SET @ReturnCode = ERROR_NUMBER()
            END
        END CATCH
    END

    -- Registro de información final
    SET @EndTime = GETDATE()
    SET @EndTimeSec = CONVERT(datetime,CONVERT(varchar,@EndTime,120),120)

    SET @EndMessage = 'Resultado: ' + CASE 
        WHEN @Execute = 'N' THEN 'No Ejecutado' 
        WHEN @Error = 0 THEN 'Exitoso' 
        ELSE 'Fallido' 
    END
    RAISERROR(@EndMessage, 10, 1) WITH NOWAIT

    SET @EndMessage = 'Duración: ' + CASE 
        WHEN DATEDIFF(ss,@StartTimeSec, @EndTimeSec)/(24*3600) > 0 
        THEN CAST(DATEDIFF(ss,@StartTimeSec, @EndTimeSec)/(24*3600) AS nvarchar) + '.' 
        ELSE '' 
    END + CONVERT(nvarchar,@EndTimeSec - @StartTimeSec,108)
    RAISERROR(@EndMessage, 10, 1) WITH NOWAIT

    SET @EndMessage = 'Fecha y hora: ' + CONVERT(nvarchar,@EndTimeSec,120) + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@EndMessage, 10, 1) WITH NOWAIT

    IF @LogToTable = 'Y'
    BEGIN
        UPDATE dbo.CommandLog
        SET EndTime = @EndTime,
            ErrorNumber = CASE WHEN @Execute = 'N' THEN NULL ELSE @Error END,
            ErrorMessage = @ErrorMessageOriginal
        WHERE ID = @ID
    END

    ReturnCode:
    IF @ReturnCode <> 0
    BEGIN
        RETURN @ReturnCode
    END
END
