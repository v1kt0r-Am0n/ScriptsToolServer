SELECT Schema_name(schema_id) as esquema, 
       name as tabla
FROM   sys.tables 
WHERE  Objectproperty(object_id, 'TableHasPrimaryKey') = 0 
