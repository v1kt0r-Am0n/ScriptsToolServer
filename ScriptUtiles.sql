
USE Autorizador;
GO

--- Devolver todos los objetos modificados en los últimos N días
SELECT name AS object_name 
  ,SCHEMA_NAME(schema_id) AS schema_name
  ,type_desc
  ,create_date
  ,modify_date
 -- ,*
FROM sys.objects
WHERE modify_date > GETDATE() - 30
ORDER BY name,modify_date;

---Devolver todas las funciones definidas por el usuario de una base de datos
USE <database_name>;
GO
SELECT name AS function_name 
  ,SCHEMA_NAME(schema_id) AS schema_name
  ,type_desc
  ,create_date
  ,modify_date
FROM sys.objects
WHERE type_desc LIKE '%FUNCTION%';
---Devolver el propietario de cada objeto de un esquema.

USE <database_name>;
GO
SELECT 'OBJECT' AS entity_type
    ,USER_NAME(OBJECTPROPERTY(object_id, 'OwnerId')) AS owner_name
    ,name 
FROM sys.objects WHERE SCHEMA_NAME(schema_id) = '<schema_name>'
UNION 
SELECT 'TYPE' AS entity_type
    ,USER_NAME(TYPEPROPERTY(SCHEMA_NAME(schema_id) + '.' + name, 'OwnerId')) AS owner_name
    ,name 
FROM sys.types WHERE SCHEMA_NAME(schema_id) = '<schema_name>' 
UNION
SELECT 'XML SCHEMA COLLECTION' AS entity_type 
    ,COALESCE(USER_NAME(xsc.principal_id),USER_NAME(s.principal_id)) AS owner_name
    ,xsc.name 
FROM sys.xml_schema_collections AS xsc JOIN sys.schemas AS s
    ON s.schema_id = xsc.schema_id
WHERE s.name = '<schema_name>';
GO