SELECT
distinct 'exec sp_rename '+ so.name +','  + upper(so.name) AS Tabla
FROM
sys.objects so INNER JOIN
sys.columns sc ON
so.object_id = sc.object_id INNER JOIN
sys.types st ON
st.system_type_id = sc.system_type_id AND
st.name != 'sysname'
WHERE
so.type = 'U' 
--ORDER BY so.name