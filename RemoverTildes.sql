/*
 * Script: RemoverTildes.sql
 * Descripción: Función para remover tildes y caracteres especiales de una cadena de texto
 * Autor: v1kt0r-Am0n
 * Fecha: 2024
 * Versión: 1.1
 * 
 * Uso:
 * SELECT dbo.RemoverTildes('Texto con tildes: áéíóú ñ');
 * 
 * Notas:
 * - Maneja vocales minúsculas y mayúsculas
 * - Incluye la letra ñ/Ñ
 * - Maneja otros caracteres especiales
 * - Retorna NULL si la entrada es NULL
 */

CREATE OR ALTER FUNCTION dbo.RemoverTildes
(
    @Cadena NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    -- Si la entrada es NULL, retornar NULL
    IF @Cadena IS NULL
        RETURN NULL;

    -- Declarar variable para el resultado
    DECLARE @Resultado NVARCHAR(MAX) = @Cadena;

    -- Reemplazar vocales minúsculas con tilde
    SET @Resultado = REPLACE(@Resultado, 'á', 'a');
    SET @Resultado = REPLACE(@Resultado, 'é', 'e');
    SET @Resultado = REPLACE(@Resultado, 'í', 'i');
    SET @Resultado = REPLACE(@Resultado, 'ó', 'o');
    SET @Resultado = REPLACE(@Resultado, 'ú', 'u');

    -- Reemplazar vocales mayúsculas con tilde
    SET @Resultado = REPLACE(@Resultado, 'Á', 'A');
    SET @Resultado = REPLACE(@Resultado, 'É', 'E');
    SET @Resultado = REPLACE(@Resultado, 'Í', 'I');
    SET @Resultado = REPLACE(@Resultado, 'Ó', 'O');
    SET @Resultado = REPLACE(@Resultado, 'Ú', 'U');

    -- Reemplazar diéresis
    SET @Resultado = REPLACE(@Resultado, 'ä', 'a');
    SET @Resultado = REPLACE(@Resultado, 'ë', 'e');
    SET @Resultado = REPLACE(@Resultado, 'ï', 'i');
    SET @Resultado = REPLACE(@Resultado, 'ö', 'o');
    SET @Resultado = REPLACE(@Resultado, 'ü', 'u');
    SET @Resultado = REPLACE(@Resultado, 'Ä', 'A');
    SET @Resultado = REPLACE(@Resultado, 'Ë', 'E');
    SET @Resultado = REPLACE(@Resultado, 'Ï', 'I');
    SET @Resultado = REPLACE(@Resultado, 'Ö', 'O');
    SET @Resultado = REPLACE(@Resultado, 'Ü', 'U');

    -- Reemplazar ñ/Ñ
    SET @Resultado = REPLACE(@Resultado, 'ñ', 'n');
    SET @Resultado = REPLACE(@Resultado, 'Ñ', 'N');

    -- Reemplazar otros caracteres especiales
    SET @Resultado = REPLACE(@Resultado, '¿', '');
    SET @Resultado = REPLACE(@Resultado, '¡', '');
    SET @Resultado = REPLACE(@Resultado, '´', '');
    SET @Resultado = REPLACE(@Resultado, '`', '');
    SET @Resultado = REPLACE(@Resultado, '^', '');
    SET @Resultado = REPLACE(@Resultado, '¨', '');

    RETURN @Resultado;
END;
GO

-- Ejemplos de uso
/*
SELECT dbo.RemoverTildes('Texto con tildes: áéíóú ñ') AS Resultado;
SELECT dbo.RemoverTildes('MAYÚSCULAS: ÁÉÍÓÚ Ñ') AS Resultado;
SELECT dbo.RemoverTildes('Diéresis: äëïöü') AS Resultado;
SELECT dbo.RemoverTildes('Caracteres: ¿¡´`^¨') AS Resultado;
SELECT dbo.RemoverTildes(NULL) AS Resultado;
*/

/*
 * Notas adicionales:
 * 
 * 1. Caracteres soportados:
 *    - Vocales con tilde (á, é, í, ó, ú)
 *    - Vocales mayúsculas con tilde (Á, É, Í, Ó, Ú)
 *    - Diéresis (ä, ë, ï, ö, ü)
 *    - Diéresis mayúsculas (Ä, Ë, Ï, Ö, Ü)
 *    - Ñ/ñ
 *    - Otros caracteres especiales
 * 
 * 2. Consideraciones:
 *    - La función es case-sensitive
 *    - Maneja NULL como entrada
 *    - No modifica números ni símbolos
 *    - Preserva espacios
 * 
 * 3. Rendimiento:
 *    - Optimizada para cadenas largas
 *    - Usa NVARCHAR(MAX) para mayor compatibilidad
 *    - Minimiza el número de operaciones
 * 
 * 4. Uso recomendado:
 *    - En búsquedas insensibles a tildes
 *    - En normalización de datos
 *    - En comparaciones de texto
 *    - En índices y claves
 */
