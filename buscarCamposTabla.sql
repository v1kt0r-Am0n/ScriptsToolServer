SELECT
so.name AS Tabla,
sc.name AS Columna,
st.name AS Tipo,
sc.max_length AS Tamanio
FROM
sys.objects so INNER JOIN
sys.columns sc ON
so.object_id = sc.object_id INNER JOIN
sys.types st ON
st.system_type_id = sc.system_type_id AND
st.name != 'sysname'
WHERE
--so.type = 'U' and
--and so.name='base_retenciones'
 sc.name like '%UsuarioServicioVentas%'
ORDER BY
so.name,
sc.name