SELECT d.name AS databaseName, m.name AS fileName, m.physical_name AS filePath, m.state_desc, m.size * 8 / 1024 as MB, m.growth
FROM sys.master_files m
INNER JOIN sys.databases d ON m.database_id = d.database_id
where 
m.name like '%log%'
and  (m.size * 8 / 1024 )>10
ORDER BY databasename, filename