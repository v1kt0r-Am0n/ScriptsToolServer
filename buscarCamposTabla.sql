/*
 * Script: buscarCamposTabla.sql
 * Descripción: Busca columnas en todas las tablas de la base de datos que coincidan con un patrón específico
 *              y muestra información detallada sobre las columnas encontradas.
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 2.0
 * 
 * Uso:
 * 1. Modificar la variable @patronBusqueda con el patrón deseado
 * 2. Ejecutar el script
 * 3. Los resultados mostrarán todas las columnas que coincidan con el patrón
 * 
 * Ejemplos de patrones:
 * - '%Usuario%' : Busca todas las columnas que contengan 'Usuario'
 * - 'Usuario%'  : Busca columnas que empiecen con 'Usuario'
 * - '%Usuario'  : Busca columnas que terminen con 'Usuario'
 */

-- Configuración de variables
DECLARE @patronBusqueda NVARCHAR(100) = '%UsuarioServicioVentas%';
DECLARE @incluirComentarios BIT = 1; -- 1 para incluir comentarios, 0 para excluirlos

-- Crear tabla temporal para almacenar resultados
IF OBJECT_ID('tempdb..#ResultadosBusqueda') IS NOT NULL
    DROP TABLE #ResultadosBusqueda;

CREATE TABLE #ResultadosBusqueda (
    Esquema NVARCHAR(128),
    Tabla NVARCHAR(128),
    Columna NVARCHAR(128),
    TipoDato NVARCHAR(128),
    TamanioMaximo INT,
    Precision INT,
    Escala INT,
    PermiteNulos NVARCHAR(3),
    EsIdentidad NVARCHAR(3),
    EsCalculado NVARCHAR(3),
    ValorPorDefecto NVARCHAR(MAX),
    Comentario NVARCHAR(MAX)
);

-- Insertar resultados en tabla temporal
INSERT INTO #ResultadosBusqueda
SELECT
    SCHEMA_NAME(so.schema_id) AS Esquema,
    so.name AS Tabla,
    sc.name AS Columna,
    st.name AS TipoDato,
    sc.max_length AS TamanioMaximo,
    sc.precision AS Precision,
    sc.scale AS Escala,
    CASE WHEN sc.is_nullable = 1 THEN 'Sí' ELSE 'No' END AS PermiteNulos,
    CASE WHEN sc.is_identity = 1 THEN 'Sí' ELSE 'No' END AS EsIdentidad,
    CASE WHEN sc.is_computed = 1 THEN 'Sí' ELSE 'No' END AS EsCalculado,
    OBJECT_DEFINITION(sc.default_object_id) AS ValorPorDefecto,
    CAST(ep.value AS NVARCHAR(MAX)) AS Comentario
FROM
    sys.objects so 
    INNER JOIN sys.columns sc ON so.object_id = sc.object_id 
    INNER JOIN sys.types st ON st.system_type_id = sc.system_type_id 
    LEFT JOIN sys.extended_properties ep ON 
        ep.major_id = sc.object_id 
        AND ep.minor_id = sc.column_id 
        AND ep.name = 'MS_Description'
WHERE
    so.type = 'U' -- Solo tablas de usuario
    AND sc.name LIKE @patronBusqueda;

-- Mostrar resultados
SELECT 
    Esquema,
    Tabla,
    Columna,
    TipoDato,
    CASE 
        WHEN TipoDato IN ('varchar', 'nvarchar', 'char', 'nchar') 
        THEN CAST(TamanioMaximo AS NVARCHAR(10)) + ' caracteres'
        WHEN TipoDato IN ('decimal', 'numeric') 
        THEN CAST(Precision AS NVARCHAR(10)) + ',' + CAST(Escala AS NVARCHAR(10))
        ELSE CAST(TamanioMaximo AS NVARCHAR(10)) + ' bytes'
    END AS Tamanio,
    PermiteNulos,
    EsIdentidad,
    EsCalculado,
    ValorPorDefecto,
    CASE WHEN @incluirComentarios = 1 THEN Comentario ELSE NULL END AS Comentario
FROM 
    #ResultadosBusqueda
ORDER BY
    Esquema,
    Tabla,
    Columna;

-- Limpiar tabla temporal
DROP TABLE #ResultadosBusqueda;

/*
 * Notas adicionales:
 * - El script ahora incluye comentarios de las columnas si están disponibles
 * - Se puede controlar si se muestran los comentarios mediante la variable @incluirComentarios
 * - Los tamaños se muestran en formato más legible (caracteres/bytes)
 * - Se utiliza una tabla temporal para mejor rendimiento con grandes volúmenes de datos
 * - Se incluye información sobre el uso de patrones de búsqueda
 * 
 * Mejoras en la versión 2.0:
 * - Agregado soporte para comentarios de columnas
 * - Mejorado el formato de visualización de tamaños
 * - Optimizado el rendimiento con tabla temporal
 * - Agregada documentación más detallada
 */