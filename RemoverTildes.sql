CREATE FUNCTION RemoverTildes ( @Cadena VARCHAR(100) )
RETURNS VARCHAR(100)
AS BEGIN
 
 --Reemplazamos las vocales acentuadas
    RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Cadena, 'á', 'a'), 'é','e'), 'í', 'i'), 'ó', 'o'), 'ú','u')
 
   END
