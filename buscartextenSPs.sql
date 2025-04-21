/*
 * Script: buscartextenSPs.sql
 * Descripción: Busca procedimientos almacenados que contengan un patrón específico en su definición
 *              y muestra información relevante sobre ellos.
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Modificar la variable @patronBusqueda con el texto a buscar
 * 2. Ejecutar el script
 * 3. Los resultados mostrarán los procedimientos que contengan el patrón
 */

-- Configuración de variables
DECLARE @patronBusqueda NVARCHAR(100) = '%SELECT *%';
DECLARE @tipoObjeto CHAR(2) = 'P'; -- P para procedimientos almacenados

-- Crear tabla temporal para almacenar resultados
IF OBJECT_ID('tempdb..#ResultadosBusqueda') IS NOT NULL
    DROP TABLE #ResultadosBusqueda;

CREATE TABLE #ResultadosBusqueda (
    NombreProcedimiento NVARCHAR(128),
    Esquema NVARCHAR(128),
    FechaCreacion DATETIME,
    FechaModificacion DATETIME,
    Definicion NVARCHAR(MAX)
);

-- Insertar resultados en tabla temporal
INSERT INTO #ResultadosBusqueda
SELECT DISTINCT
    o.name AS NombreProcedimiento,
    SCHEMA_NAME(o.schema_id) AS Esquema,
    o.create_date AS FechaCreacion,
    o.modify_date AS FechaModificacion,
    OBJECT_DEFINITION(o.object_id) AS Definicion
FROM
    sys.objects o
    INNER JOIN sys.sql_modules m ON o.object_id = m.object_id
WHERE
    o.type = @tipoObjeto
    AND m.definition LIKE @patronBusqueda;

-- Mostrar resultados
SELECT 
    Esquema,
    NombreProcedimiento,
    CONVERT(VARCHAR, FechaCreacion, 103) AS FechaCreacion,
    CONVERT(VARCHAR, FechaModificacion, 103) AS FechaModificacion,
    CASE 
        WHEN LEN(Definicion) > 200 
        THEN LEFT(Definicion, 200) + '...' 
        ELSE Definicion 
    END AS DefinicionCorta
FROM 
    #ResultadosBusqueda
ORDER BY
    Esquema,
    NombreProcedimiento;

-- Limpiar tabla temporal
DROP TABLE #ResultadosBusqueda;

/*
 * Notas:
 * - El script busca en la definición de los procedimientos almacenados
 * - Por defecto busca 'SELECT *' que es una práctica no recomendada
 * - Se puede modificar @patronBusqueda para buscar otros patrones
 * - Se puede cambiar @tipoObjeto para buscar en otros tipos de objetos
 * 
 * Tipos de objetos comunes:
 * P = Procedimiento almacenado
 * V = Vista
 * FN = Función escalar
 * TF = Función con valores de tabla
 * TR = Trigger
 */
