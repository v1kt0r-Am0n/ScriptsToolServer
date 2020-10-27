SELECT B.database_id Id, 
B.name BaseDeDatos,
SUM((T.size * 8) / 1024.00) Tamaño_MB,
SUM((T2.size * 8) / 1024.00) TamañoLog_MB,
max(last_user_seek) as Ultimo_Indice_seek,
max(last_user_scan) as Ultimo_Indice_scan,
max(last_user_lookup) as Ultimo_Indice_lookup,
max(last_user_update) as Ultimo_update
FROM sys.databases B
	INNER JOIN sys.master_files T ON (B.database_id = T.database_id AND T.type_desc = 'ROWS')
	INNER JOIN sys.master_files T2 ON (B.database_id = T2.database_id AND T2.type_desc = 'LOG')
	LEFT JOIN sys.dm_db_index_usage_stats I ON (B.database_id = I.database_id)

GROUP BY B.database_id, B.name

HAVING max(last_user_seek) is null and max(last_user_scan)  is null and  max(last_user_update) is null
and 
B.name
not in (
'master','ReportServer','ReportServerTempDB',
'tempdb',
'model',
'msdb')