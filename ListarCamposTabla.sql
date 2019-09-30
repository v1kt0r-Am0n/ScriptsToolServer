SELECT
so.name AS Tabla,
sc.name AS [Name],
st.name AS [varType],
sc.max_length AS [Length]
FROM
sys.objects so INNER JOIN
sys.columns sc ON
so.object_id = sc.object_id INNER JOIN
sys.types st ON
st.system_type_id = sc.system_type_id AND
st.name != 'sysname'
WHERE
so.type = 'U' 
--and so.name='Incentivos'
ORDER BY
so.name,
sc.name