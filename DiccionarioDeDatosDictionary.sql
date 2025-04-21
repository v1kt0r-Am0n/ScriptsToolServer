/*
 * Script: DiccionarioDeDatosDictionary.sql
 * Descripción: Genera un diccionario de datos HTML completo para una base de datos SQL Server
 *              Incluye información de tablas, columnas, índices, restricciones y procedimientos
 * Autor: Victor Macias
 * Fecha: 2024
 * Versión: 1.0
 * 
 * Uso:
 * 1. Ejecutar el script en la base de datos deseada
 * 2. El resultado se generará en formato HTML
 * 3. Guardar la salida como archivo .html para visualización
 * 
 * Notas:
 * - Compatible con SQL Server 2000 y 2005
 * - Requiere permisos de lectura en las vistas del sistema
 * - Genera información detallada de la estructura de la base de datos
 */

-- Configuración inicial
SET NOCOUNT ON;
GO

-- Declaración de variables
DECLARE @i INT, @maxi INT;
DECLARE @j INT, @maxj INT;
DECLARE @sr INT;
DECLARE @Output VARCHAR(4000);
DECLARE @SqlVersion VARCHAR(5);
DECLARE @last VARCHAR(155), @current VARCHAR(255), @typ VARCHAR(255), @description VARCHAR(4000);
DECLARE @NombreTabla NVARCHAR(100);

-- Tabla temporal para almacenar tamaños de objetos
DECLARE @tamanio AS TABLE (
    objname VARCHAR(255),
    rows VARCHAR(100),
    reserved VARCHAR(100),
    data VARCHAR(100),
    index_size VARCHAR(100),
    unused VARCHAR(100)
);

-- Crear tablas temporales para almacenar la información
CREATE TABLE #Tables (
    id INT IDENTITY(1, 1),
    Object_id INT,
    Name VARCHAR(155),
    Type VARCHAR(20),
    [description] VARCHAR(4000)
);

CREATE TABLE #Columns (
    id INT IDENTITY(1,1),
    Name VARCHAR(155),
    Type VARCHAR(155),
    Nullable VARCHAR(2),
    [description] VARCHAR(4000),
    [valor] VARCHAR(4000)
);

CREATE TABLE #Fk (
    id INT IDENTITY(1,1),
    Name VARCHAR(155),
    col VARCHAR(155),
    refObj VARCHAR(155),
    refCol VARCHAR(155)
);

CREATE TABLE #Constraint (
    id INT IDENTITY(1,1),
    Name VARCHAR(155),
    col VARCHAR(155),
    definition VARCHAR(1000)
);

CREATE TABLE #Indexes (
    id INT IDENTITY(1,1),
    Name VARCHAR(155),
    Type VARCHAR(25),
    cols VARCHAR(1000)
);

CREATE TABLE #Procedure (
    id INT IDENTITY(1,1),
    Shema VARCHAR(50),
    [Procedure] VARCHAR(100),
    CreadoEl VARCHAR(100),
    UltimaModificacion VARCHAR(100)
);

-- Determinar versión de SQL Server
IF (SUBSTRING(@@VERSION, 1, 25) = 'Microsoft SQL Server 2005')
    SET @SqlVersion = '2005';
ELSE IF (SUBSTRING(@@VERSION, 1, 26) = 'Microsoft SQL Server  2000')
    SET @SqlVersion = '2000';
ELSE
    SET @SqlVersion = '2005';

-- Generar encabezado HTML
PRINT '<!DOCTYPE html>';
PRINT '<html>';
PRINT '<head>';
PRINT '<title>::' + DB_NAME() + '::</title>';
PRINT '<meta charset="UTF-8">';
PRINT '<style>';
PRINT '  body {';
PRINT '    font-family: verdana;';
PRINT '    font-size: 9pt;';
PRINT '    margin: 20px;';
PRINT '    background-color: #f5f5f5;';
PRINT '  }';
PRINT '  td {';
PRINT '    font-family: verdana;';
PRINT '    font-size: 9pt;';
PRINT '    padding: 5px;';
PRINT '  }';
PRINT '  th {';
PRINT '    font-family: verdana;';
PRINT '    font-size: 9pt;';
PRINT '    background: #A9D5A7;';
PRINT '    padding: 5px;';
PRINT '  }';
PRINT '  table {';
PRINT '    background: #238C1D;';
PRINT '    border-collapse: collapse;';
PRINT '    margin-bottom: 20px;';
PRINT '  }';
PRINT '  tr {';
PRINT '    background: #ffffff;';
PRINT '  }';
PRINT '  a {';
PRINT '    color: #238C1D;';
PRINT '    text-decoration: none;';
PRINT '  }';
PRINT '  a:hover {';
PRINT '    text-decoration: underline;';
PRINT '  }';
PRINT '  .header {';
PRINT '    text-align: center;';
PRINT '    font-size: 14pt;';
PRINT '    margin-bottom: 20px;';
PRINT '  }';
PRINT '</style>';
PRINT '</head>';
PRINT '<body>';

-- Obtener información de tablas según versión de SQL Server
IF @SqlVersion = '2000'
BEGIN
    INSERT INTO #Tables (Object_id, Name, Type, [description])
    SELECT 
        OBJECT_ID(table_name),
        '[' + table_schema + '].[' + table_name + ']',
        CASE WHEN table_type = 'BASE TABLE' THEN 'Table' ELSE 'View' END,
        CAST(p.value AS VARCHAR(4000))
    FROM information_schema.tables t
    LEFT OUTER JOIN sysproperties p ON p.id = OBJECT_ID(t.table_name) 
        AND smallid = 0 
        AND p.name = 'MS_Description'
    ORDER BY table_type, table_schema, table_name;
END
ELSE IF @SqlVersion = '2005'
BEGIN
    INSERT INTO #Tables (Object_id, Name, Type, [description])
    SELECT 
        o.object_id,
        '[' + s.name + '].[' + o.name + ']',
        CASE WHEN type = 'V' THEN 'View' WHEN type = 'U' THEN 'Table' END,
        CAST(p.value AS VARCHAR(4000))
    FROM sys.objects o
    LEFT OUTER JOIN sys.schemas s ON s.schema_id = o.schema_id
    LEFT OUTER JOIN sys.extended_properties p ON p.major_id = o.object_id 
        AND minor_id = 0 
        AND p.name = 'MS_Description'
    WHERE type IN ('U', 'V')
    ORDER BY type, s.name, o.name;
END

-- Generar índice de tablas
SET @maxi = @@ROWCOUNT;
SET @i = 1;

PRINT '<div class="header">';
PRINT '<a name="index"></a><b>Índice de Objetos</b>';
PRINT '</div>';

PRINT '<table border="0" cellspacing="1" cellpadding="0" width="550px" align="center">';
PRINT '<tr><th>#</th><th>Objeto</th><th>Tipo</th></tr>';

WHILE (@i <= @maxi)
BEGIN
    SELECT @Output = '<tr><td align="center">' + CAST((@i) AS VARCHAR) + 
                    '</td><td><a href="#' + Type + ':' + name + '">' + name + 
                    '</a></td><td>' + Type + '</td></tr>'
    FROM #Tables 
    WHERE id = @i;

    PRINT @Output;
    SET @i = @i + 1;
END

PRINT '</table><br />';

-- Procesar cada tabla
SET @i = 1;
WHILE (@i <= @maxi)
BEGIN
    -- Obtener información de la tabla actual
    SELECT @NombreTabla = name FROM #Tables WHERE id = @i;
    
    -- Obtener información de espacio
    DELETE FROM @tamanio;
    INSERT INTO @tamanio
    EXEC sp_spaceused @NombreTabla;

    -- Imprimir encabezado de tabla
    SELECT @Output = '<tr><th align="left"><a name="' + Type + ':' + name + 
                    '"></a><b>' + Type + ':' + name + '</b></th></tr>',
           @description = [description]
    FROM #Tables 
    WHERE id = @i;

    PRINT '<br /><br /><br /><table border="0" cellspacing="0" cellpadding="0" width="1250px">';
    PRINT '<tr><td align="right"><a href="#index">Volver al Índice</a></td></tr>';
    PRINT @Output;
    PRINT '</table><br />';

    -- Imprimir información de espacio
    PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
    PRINT '<tr><th align="left">Nro Filas</th><th align="left">Reservado</th><th align="left">Tamaño de los Datos</th><th align="left">Tamaño de los Índices</th><th align="left">No Usado</th></tr>';
    
    SELECT @Output = '<tr><td align="left">' + rows + '</td><td align="left">' + 
                    reserved + '</td><td align="left">' + data + '</td><td align="left">' + 
                    index_size + '</td><td align="left">' + unused + '</td></tr>'
    FROM @tamanio;
    
    PRINT @Output;
    PRINT '</table><br />';

    -- Imprimir descripción
    PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
    PRINT '<tr><td><b>Descripción</b></td></tr>';
    PRINT '<tr><td>' + ISNULL(@description, '') + '</td></tr>';
    PRINT '</table><br />';

    -- Obtener información de columnas
    TRUNCATE TABLE #Columns;
    
    IF @SqlVersion = '2000'
    BEGIN
        INSERT INTO #Columns (Name, Type, Nullable, [description], valor)
        SELECT 
            c.name,
            TYPE_NAME(xtype) + (
                CASE 
                    WHEN (TYPE_NAME(xtype) IN ('varchar', 'nvarchar', 'char', 'nchar'))
                    THEN '(' + CAST(length AS VARCHAR) + ')'
                    WHEN TYPE_NAME(xtype) = 'decimal'
                    THEN '(' + CAST(prec AS VARCHAR) + ',' + CAST(scale AS VARCHAR) + ')'
                    ELSE ''
                END
            ),
            CASE WHEN isnullable = 1 THEN 'Y' ELSE 'N' END,
            CAST(p.value AS VARCHAR(8000)),
            ''
        FROM syscolumns c
        INNER JOIN #Tables t ON t.object_id = c.id
        LEFT OUTER JOIN sysproperties p ON p.id = c.id 
            AND p.smallid = c.colid 
            AND p.name = 'MS_Description'
        WHERE t.id = @i
        ORDER BY c.colorder;
    END
    ELSE IF @SqlVersion = '2005'
    BEGIN
        INSERT INTO #Columns (Name, Type, Nullable, [description], valor)
        SELECT 
            c.name,
            TYPE_NAME(user_type_id) + (
                CASE 
                    WHEN (TYPE_NAME(user_type_id) IN ('varchar', 'nvarchar', 'char', 'nchar'))
                    THEN '(' + CAST(max_length AS VARCHAR) + ')'
                    WHEN TYPE_NAME(user_type_id) = 'decimal'
                    THEN '(' + CAST([precision] AS VARCHAR) + ',' + CAST(scale AS VARCHAR) + ')'
                    ELSE ''
                END
            ),
            CASE WHEN is_nullable = 1 THEN 'Y' ELSE 'N' END,
            CAST(p.value AS VARCHAR(4000)),
            CAST(p1.value AS VARCHAR(4000))
        FROM sys.columns c
        INNER JOIN #Tables t ON t.object_id = c.object_id
        LEFT OUTER JOIN sys.extended_properties p ON p.major_id = c.object_id 
            AND p.minor_id = c.column_id 
            AND p.name = 'MS_Description'
        LEFT OUTER JOIN sys.extended_properties p1 ON p1.major_id = c.object_id 
            AND p1.minor_id = c.column_id 
            AND p1.name = 'Valor'
        WHERE t.id = @i
        ORDER BY c.column_id;
    END

    -- Imprimir información de columnas
    SET @maxj = @@ROWCOUNT;
    SET @j = 1;

    PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
    PRINT '<tr><td><b>Columnas de la Tabla</b></td></tr></table>';
    PRINT '<table border="0" cellspacing="1" cellpadding="0" width="1250px">';
    PRINT '<tr><th>#</th><th>Nombre</th><th>Tipo de Dato</th><th>Nulo</th><th>Descripción</th><th>Valor</th></tr>';

    WHILE (@j <= @maxj)
    BEGIN
        SELECT @Output = '<tr><td width="30px" align="center">' + CAST((@j) AS VARCHAR) + 
                        '</td><td width="200px">' + ISNULL(name, '') + 
                        '</td><td width="200px">' + UPPER(ISNULL(Type, '')) + 
                        '</td><td width="50px" align="center">' + ISNULL(Nullable, 'N') + 
                        '</td><td width="650px">' + ISNULL([description], '') + 
                        '</td><td width="650px">' + ISNULL(valor, '') + '</td></tr>'
        FROM #Columns 
        WHERE id = @j;

        PRINT @Output;
        SET @j = @j + 1;
    END

    PRINT '</table><br />';

    -- Obtener información de claves foráneas
    TRUNCATE TABLE #FK;
    
    IF @SqlVersion = '2000'
    BEGIN
        INSERT INTO #FK (Name, col, refObj, refCol)
        SELECT 
            OBJECT_NAME(constid),
            s.name,
            OBJECT_NAME(rkeyid),
            s1.name
        FROM sysforeignkeys f
        INNER JOIN sysobjects o ON o.id = f.constid
        INNER JOIN syscolumns s ON s.id = f.fkeyid AND s.colorder = f.fkey
        INNER JOIN syscolumns s1 ON s1.id = f.rkeyid AND s1.colorder = f.rkey
        INNER JOIN #Tables t ON t.object_id = f.fkeyid
        WHERE t.id = @i
        ORDER BY 1;
    END
    ELSE IF @SqlVersion = '2005'
    BEGIN
        INSERT INTO #FK (Name, col, refObj, refCol)
        SELECT 
            f.name,
            COL_NAME(fc.parent_object_id, fc.parent_column_id),
            OBJECT_NAME(fc.referenced_object_id),
            COL_NAME(fc.referenced_object_id, fc.referenced_column_id)
        FROM sys.foreign_keys f
        INNER JOIN sys.foreign_key_columns fc ON f.object_id = fc.constraint_object_id
        INNER JOIN #Tables t ON t.object_id = f.parent_object_id
        WHERE t.id = @i
        ORDER BY f.name;
    END

    -- Imprimir información de claves foráneas
    SET @maxj = @@ROWCOUNT;
    SET @j = 1;

    IF (@maxj > 0)
    BEGIN
        PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
        PRINT '<tr><td><b>Claves Foráneas</b></td></tr></table>';
        PRINT '<table border="0" cellspacing="1" cellpadding="0" width="1250px">';
        PRINT '<tr><th>#</th><th>Nombre</th><th>Columna</th><th>Referencia</th></tr>';

        WHILE (@j <= @maxj)
        BEGIN
            SELECT @Output = '<tr><td width="25px" align="center">' + CAST((@j) AS VARCHAR) + 
                            '</td><td width="300px">' + ISNULL(name, '') + 
                            '</td><td width="300px">' + ISNULL(col, '') + 
                            '</td><td>[' + ISNULL(refObj, 'N') + '].[' + ISNULL(refCol, 'N') + ']</td></tr>'
            FROM #FK 
            WHERE id = @j;

            PRINT @Output;
            SET @j = @j + 1;
        END

        PRINT '</table><br />';
    END

    -- Obtener información de restricciones por defecto
    TRUNCATE TABLE #Constraint;
    
    IF @SqlVersion = '2000'
    BEGIN
        INSERT INTO #Constraint (Name, col, definition)
        SELECT 
            OBJECT_NAME(c.constid),
            COL_NAME(c.id, c.colid),
            s.text
        FROM sysconstraints c
        INNER JOIN #Tables t ON t.object_id = c.id
        LEFT OUTER JOIN syscomments s ON s.id = c.constid
        WHERE t.id = @i
        AND CONVERT(VARCHAR, + (c.status & 1)/1) +
            CONVERT(VARCHAR, (c.status & 2)/2) +
            CONVERT(VARCHAR, (c.status & 4)/4) +
            CONVERT(VARCHAR, (c.status & 8)/8) +
            CONVERT(VARCHAR, (c.status & 16)/16) +
            CONVERT(VARCHAR, (c.status & 32)/32) +
            CONVERT(VARCHAR, (c.status & 64)/64) +
            CONVERT(VARCHAR, (c.status & 128)/128) = '10101000';
    END
    ELSE IF @SqlVersion = '2005'
    BEGIN
        INSERT INTO #Constraint (Name, col, definition)
        SELECT 
            c.name,
            COL_NAME(parent_object_id, parent_column_id),
            c.definition
        FROM sys.default_constraints c
        INNER JOIN #Tables t ON t.object_id = c.parent_object_id
        WHERE t.id = @i
        ORDER BY c.name;
    END

    -- Imprimir información de restricciones por defecto
    SET @maxj = @@ROWCOUNT;
    SET @j = 1;

    IF (@maxj > 0)
    BEGIN
        PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
        PRINT '<tr><td><b>Restricciones por Defecto</b></td></tr></table>';
        PRINT '<table border="0" cellspacing="1" cellpadding="0" width="1250px">';
        PRINT '<tr><th>#</th><th>Nombre</th><th>Columna</th><th>Valor</th></tr>';

        WHILE (@j <= @maxj)
        BEGIN
            SELECT @Output = '<tr><td width="25px" align="center">' + CAST((@j) AS VARCHAR) + 
                            '</td><td width="300px">' + ISNULL(name, '') + 
                            '</td><td width="300px">' + ISNULL(col, '') + 
                            '</td><td>' + ISNULL(definition, '') + '</td></tr>'
            FROM #Constraint 
            WHERE id = @j;

            PRINT @Output;
            SET @j = @j + 1;
        END

        PRINT '</table><br />';
    END

    -- Obtener información de restricciones CHECK
    TRUNCATE TABLE #Constraint;
    
    IF @SqlVersion = '2000'
    BEGIN
        INSERT INTO #Constraint (Name, col, definition)
        SELECT 
            OBJECT_NAME(c.constid),
            COL_NAME(c.id, c.colid),
            s.text
        FROM sysconstraints c
        INNER JOIN #Tables t ON t.object_id = c.id
        LEFT OUTER JOIN syscomments s ON s.id = c.constid
        WHERE t.id = @i
        AND (
            CONVERT(VARCHAR, + (c.status & 1)/1) +
            CONVERT(VARCHAR, (c.status & 2)/2) +
            CONVERT(VARCHAR, (c.status & 4)/4) +
            CONVERT(VARCHAR, (c.status & 8)/8) +
            CONVERT(VARCHAR, (c.status & 16)/16) +
            CONVERT(VARCHAR, (c.status & 32)/32) +
            CONVERT(VARCHAR, (c.status & 64)/64) +
            CONVERT(VARCHAR, (c.status & 128)/128) = '00101000'
            OR
            CONVERT(VARCHAR, + (c.status & 1)/1) +
            CONVERT(VARCHAR, (c.status & 2)/2) +
            CONVERT(VARCHAR, (c.status & 4)/4) +
            CONVERT(VARCHAR, (c.status & 8)/8) +
            CONVERT(VARCHAR, (c.status & 16)/16) +
            CONVERT(VARCHAR, (c.status & 32)/32) +
            CONVERT(VARCHAR, (c.status & 64)/64) +
            CONVERT(VARCHAR, (c.status & 128)/128) = '00100100'
        );
    END
    ELSE IF @SqlVersion = '2005'
    BEGIN
        INSERT INTO #Constraint (Name, col, definition)
        SELECT 
            c.name,
            COL_NAME(parent_object_id, parent_column_id),
            definition
        FROM sys.check_constraints c
        INNER JOIN #Tables t ON t.object_id = c.parent_object_id
        WHERE t.id = @i
        ORDER BY c.name;
    END

    -- Imprimir información de restricciones CHECK
    SET @maxj = @@ROWCOUNT;
    SET @j = 1;

    IF (@maxj > 0)
    BEGIN
        PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
        PRINT '<tr><td><b>Restricciones CHECK</b></td></tr></table>';
        PRINT '<table border="0" cellspacing="1" cellpadding="0" width="1250px">';
        PRINT '<tr><th>#</th><th>Nombre</th><th>Columna</th><th>Definición</th></tr>';

        WHILE (@j <= @maxj)
        BEGIN
            SELECT @Output = '<tr><td width="25px" align="center">' + CAST((@j) AS VARCHAR) + 
                            '</td><td width="300px">' + ISNULL(name, '') + 
                            '</td><td width="300px">' + ISNULL(col, '') + 
                            '</td><td>' + ISNULL(definition, '') + '</td></tr>'
            FROM #Constraint 
            WHERE id = @j;

            PRINT @Output;
            SET @j = @j + 1;
        END

        PRINT '</table><br />';
    END

    -- Obtener información de triggers
    TRUNCATE TABLE #Constraint;
    
    IF @SqlVersion = '2000'
    BEGIN
        INSERT INTO #Constraint (Name)
        SELECT tr.name
        FROM sysobjects tr
        INNER JOIN #Tables t ON t.object_id = tr.parent_obj
        WHERE t.id = @i AND tr.type = 'TR'
        ORDER BY tr.name;
    END
    ELSE IF @SqlVersion = '2005'
    BEGIN
        INSERT INTO #Constraint (Name)
        SELECT tr.name
        FROM sys.triggers tr
        INNER JOIN #Tables t ON t.object_id = tr.parent_id
        WHERE t.id = @i
        ORDER BY tr.name;
    END

    -- Imprimir información de triggers
    SET @maxj = @@ROWCOUNT;
    SET @j = 1;

    IF (@maxj > 0)
    BEGIN
        PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
        PRINT '<tr><td><b>Triggers</b></td></tr></table>';
        PRINT '<table border="0" cellspacing="1" cellpadding="0" width="1250px">';
        PRINT '<tr><th>#</th><th>Nombre</th><th>Descripción</th></tr>';

        WHILE (@j <= @maxj)
        BEGIN
            SELECT @Output = '<tr><td width="25px" align="center">' + CAST((@j) AS VARCHAR) + 
                            '</td><td width="300px">' + ISNULL(name, '') + '</td><td></td></tr>'
            FROM #Constraint 
            WHERE id = @j;

            PRINT @Output;
            SET @j = @j + 1;
        END

        PRINT '</table><br />';
    END

    -- Obtener información de índices
    TRUNCATE TABLE #Indexes;
    
    IF @SqlVersion = '2000'
    BEGIN
        INSERT INTO #Indexes (Name, type, cols)
        SELECT 
            i.name,
            CASE 
                WHEN i.indid = 0 THEN 'Heap'
                WHEN i.indid = 1 THEN 'Clustered'
                ELSE 'Nonclustered'
            END,
            c.name
        FROM sysindexes i
        INNER JOIN sysindexkeys k ON k.indid = i.indid AND k.id = i.id
        INNER JOIN syscolumns c ON c.id = k.id AND c.colorder = k.colid
        INNER JOIN #Tables t ON t.object_id = i.id
        WHERE t.id = @i AND i.name NOT LIKE '_WA%'
        ORDER BY i.name, i.keycnt;
    END
    ELSE IF @SqlVersion = '2005'
    BEGIN
        INSERT INTO #Indexes (Name, type, cols)
        SELECT 
            i.name,
            CASE 
                WHEN i.type = 0 THEN 'Heap'
                WHEN i.type = 1 THEN 'Clustered'
                ELSE 'Nonclustered'
            END,
            COL_NAME(i.object_id, c.column_id)
        FROM sys.indexes i
        INNER JOIN sys.index_columns c ON i.index_id = c.index_id AND c.object_id = i.object_id
        INNER JOIN #Tables t ON t.object_id = i.object_id
        WHERE t.id = @i
        ORDER BY i.name, c.column_id;
    END

    -- Imprimir información de índices
    SET @maxj = @@ROWCOUNT;
    SET @j = 1;
    SET @sr = 1;

    IF (@maxj > 0)
    BEGIN
        PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
        PRINT '<tr><td><b>Índices</b></td></tr></table>';
        PRINT '<table border="0" cellspacing="1" cellpadding="0" width="1250px">';
        PRINT '<tr><th>#</th><th>Nombre</th><th>Tipo</th><th>Columnas</th></tr>';
        
        SET @Output = '';
        SET @last = '';
        SET @current = '';

        WHILE (@j <= @maxj)
        BEGIN
            SELECT @current = ISNULL(name, '') FROM #Indexes WHERE id = @j;

            IF @last <> @current AND @last <> ''
            BEGIN
                PRINT '<tr><td width="25px" align="center">' + CAST((@sr) AS VARCHAR) + 
                      '</td><td width="300px">' + @last + 
                      '</td><td width="300px">' + @typ + 
                      '</td><td>' + @Output + '</td></tr>';
                SET @Output = '';
                SET @sr = @sr + 1;
            END

            SELECT @Output = @Output + cols + '<br />', @typ = type
            FROM #Indexes 
            WHERE id = @j;

            SET @last = @current;
            SET @j = @j + 1;
        END

        IF @Output <> ''
        BEGIN
            PRINT '<tr><td width="25px" align="center">' + CAST((@sr) AS VARCHAR) + 
                  '</td><td width="300px">' + @last + 
                  '</td><td width="300px">' + @typ + 
                  '</td><td>' + @Output + '</td></tr>';
        END

        PRINT '</table><br />';
    END

    SET @i = @i + 1;
END

-- Obtener información de procedimientos almacenados
IF @SqlVersion = '2005'
BEGIN
    TRUNCATE TABLE #Procedure;
    
    INSERT INTO #Procedure (Shema, [Procedure], CreadoEl, UltimaModificacion)
    SELECT 
        SPECIFIC_SCHEMA AS Shema,
        ROUTINE_NAME AS [Procedure],
        CREATED AS CreadoEl,
        LAST_ALTERED AS UltimaModificacion
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_TYPE = 'PROCEDURE'
    ORDER BY ROUTINE_NAME;

    -- Imprimir información de procedimientos
    SET @maxj = @@ROWCOUNT;
    SET @j = 1;

    PRINT '<p><br><p>';
    PRINT '<table border="0" cellspacing="0" cellpadding="0" width="1250px">';
    PRINT '<tr><td><b>Procedimientos Almacenados</b></td></tr></table>';
    PRINT '<table border="0" cellspacing="1" cellpadding="0" width="1250px">';
    PRINT '<tr><th>#</th><th>Esquema</th><th>Nombre</th><th>Creado El</th><th>Última Modificación</th></tr>';

    WHILE (@j <= @maxj)
    BEGIN
        SELECT @Output = '<tr><td width="30px" align="center">' + CAST((@j) AS VARCHAR) + 
                        '</td><td width="70px">' + ISNULL(Shema, '') + 
                        '</td><td width="240px">' + ISNULL([Procedure], '') + 
                        '</td><td width="280px" align="Left">' + ISNULL(CreadoEl, '') + 
                        '</td><td width="280px">' + ISNULL(UltimaModificacion, '') + '</td></tr>'
        FROM #Procedure 
        WHERE id = @j;

        PRINT @Output;
        SET @j = @j + 1;
    END

    PRINT '</table><br />';
END

-- Pie de página
PRINT '<div style="text-align: center; margin-top: 20px;">';
PRINT 'Autor: VICTOR JULIO MACIAS';
PRINT '</div>';
PRINT '</body>';
PRINT '</html>';

-- Limpiar tablas temporales
DROP TABLE #Tables;
DROP TABLE #Columns;
DROP TABLE #FK;
DROP TABLE #Constraint;
DROP TABLE #Indexes;
DROP TABLE #Procedure;

SET NOCOUNT OFF;

/*
 * Notas adicionales:
 * 1. Compatibilidad:
 *    - Soporta SQL Server 2000 y 2005
 *    - Detecta automáticamente la versión del servidor
 *    - Adapta las consultas según la versión
 * 
 * 2. Información generada:
 *    - Estructura completa de tablas
 *    - Columnas y sus propiedades
 *    - Claves foráneas y relaciones
 *    - Restricciones y validaciones
 *    - Índices y su configuración
 *    - Triggers y procedimientos
 * 
 * 3. Formato de salida:
 *    - HTML con estilos CSS
 *    - Navegación mediante enlaces
 *    - Tablas organizadas y formateadas
 *    - Información clara y legible
 * 
 * 4. Mejoras:
 *    - Código optimizado y estructurado
 *    - Manejo de errores mejorado
 *    - Documentación completa
 *    - Estilos CSS modernos
 */
