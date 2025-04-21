/*
 * Script: CrearCarpeta.sql
 * Descripción: Crea una carpeta con formato de fecha en la ruta especificada
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Asegurarse de que el usuario tenga permisos para ejecutar xp_cmdshell
 * 2. Verificar que la ruta base exista y tenga permisos de escritura
 * 3. Ejecutar el script para crear la carpeta
 * 
 * Notas:
 * - El formato de la carpeta es: AAAA/MM/DD
 * - Se crea en la ruta base especificada
 * - Incluye manejo de errores y validaciones
 */

-- Configuración de variables
DECLARE @RutaBase NVARCHAR(255) = 'D:\FilesRDL\';  -- Ruta base donde se creará la carpeta
DECLARE @FechaActual DATE = GETDATE();
DECLARE @Anio VARCHAR(4) = CONVERT(VARCHAR(4), YEAR(@FechaActual));
DECLARE @Mes VARCHAR(2) = RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@FechaActual)), 2);
DECLARE @Dia VARCHAR(2) = RIGHT('0' + CONVERT(VARCHAR(2), DAY(@FechaActual)), 2);
DECLARE @RutaCompleta NVARCHAR(255);
DECLARE @Comando NVARCHAR(4000);
DECLARE @Resultado INT;
DECLARE @MensajeError NVARCHAR(4000);

-- Construir ruta completa
SET @RutaCompleta = @RutaBase + @Anio + @Mes + @Dia;

-- Verificar si xp_cmdshell está habilitado
IF NOT EXISTS (
    SELECT 1 
    FROM sys.configurations 
    WHERE name = 'xp_cmdshell' 
    AND value_in_use = 1
)
BEGIN
    RAISERROR('xp_cmdshell no está habilitado. Es necesario habilitarlo para ejecutar este script.', 16, 1);
    RETURN;
END

-- Verificar si la ruta base existe
SET @Comando = 'IF NOT EXIST "' + @RutaBase + '" (EXIT 1)';
EXEC @Resultado = xp_cmdshell @Comando, NO_OUTPUT;

IF @Resultado = 1
BEGIN
    SET @MensajeError = 'La ruta base ' + @RutaBase + ' no existe.';
    RAISERROR(@MensajeError, 16, 1);
    RETURN;
END

-- Verificar permisos de escritura en la ruta base
SET @Comando = 'ECHO test > "' + @RutaBase + 'test.tmp"';
EXEC @Resultado = xp_cmdshell @Comando, NO_OUTPUT;

IF @Resultado = 1
BEGIN
    SET @MensajeError = 'No se tienen permisos de escritura en la ruta ' + @RutaBase;
    RAISERROR(@MensajeError, 16, 1);
    RETURN;
END

-- Eliminar archivo de prueba
SET @Comando = 'DEL "' + @RutaBase + 'test.tmp"';
EXEC xp_cmdshell @Comando, NO_OUTPUT;

-- Crear la carpeta
SET @Comando = 'MKDIR "' + @RutaCompleta + '"';
EXEC @Resultado = xp_cmdshell @Comando, NO_OUTPUT;

IF @Resultado = 1
BEGIN
    SET @MensajeError = 'Error al crear la carpeta ' + @RutaCompleta;
    RAISERROR(@MensajeError, 16, 1);
    RETURN;
END

-- Verificar que la carpeta se creó correctamente
SET @Comando = 'IF NOT EXIST "' + @RutaCompleta + '" (EXIT 1)';
EXEC @Resultado = xp_cmdshell @Comando, NO_OUTPUT;

IF @Resultado = 0
BEGIN
    PRINT 'Carpeta creada exitosamente: ' + @RutaCompleta;
END
ELSE
BEGIN
    SET @MensajeError = 'Error al verificar la creación de la carpeta ' + @RutaCompleta;
    RAISERROR(@MensajeError, 16, 1);
END

/*
 * Notas adicionales:
 * 1. Seguridad:
 *    - Requiere permisos para ejecutar xp_cmdshell
 *    - Verifica permisos de escritura antes de crear la carpeta
 *    - Valida la existencia de la ruta base
 * 
 * 2. Manejo de errores:
 *    - Verifica si xp_cmdshell está habilitado
 *    - Valida la existencia de la ruta base
 *    - Verifica permisos de escritura
 *    - Confirma la creación de la carpeta
 * 
 * 3. Consideraciones:
 *    - La ruta base debe existir antes de ejecutar el script
 *    - El usuario debe tener permisos de escritura en la ruta
 *    - Se recomienda ejecutar con una cuenta con privilegios suficientes
 * 
 * 4. Personalización:
 *    - Se puede modificar @RutaBase para cambiar la ubicación
 *    - El formato de fecha se puede ajustar según necesidades
 *    - Se pueden agregar más validaciones según sea necesario
 */
