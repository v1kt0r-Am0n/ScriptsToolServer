SELECT 
		[Permisos] = state_desc 
			+ ' ' + permission_name 
			+ ' on [' + c.name
			+ '].[' + b.name 
			+ '] to [' + ar.name 
			+ ']' COLLATE latin1_general_ci_as
FROM 
	sys.database_permissions AS a
	INNER JOIN sys.objects AS b 
		ON a.major_id = b.object_id
	INNER JOIN sys.schemas AS c 
		ON b.schema_id = c.schema_id
	INNER JOIN sys.database_principals AS ar 
		ON a.grantee_principal_id = ar.principal_id
UNION
SELECT 
		[Permisos] = state_desc 
			+ ' ' + permission_name 
			+ ' on Schema::['+ c.name 
			+ '] to [' + ar.name 
			+ ']' COLLATE latin1_general_ci_as
FROM 
	sys.database_permissions AS a
	INNER JOIN sys.schemas AS c 
		ON a.major_id = c.schema_id AND a.class_desc = 'Schema'
	INNER JOIN sys.database_principals AS ar 
		ON a.grantee_principal_id = ar.principal_id