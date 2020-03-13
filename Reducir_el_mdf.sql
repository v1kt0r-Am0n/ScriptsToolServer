---Reducir el mdf

---generar script
use master
SELECT  'use [' +d.name +'] DBCC SHRINKDATABASE (['+ m.name +'], 10);'
FROM sys.master_files m
INNER JOIN sys.databases d ON m.database_id = d.database_id


use master
SELECT  'use [' +d.name +'] DBCC SHRINKDATABASE (['+ m.name +'], TRUNCATEONLY);'
FROM sys.master_files m
INNER JOIN sys.databases d ON m.database_id = d.database_id
where type_desc='ROWS' and  data_space_id=1


SELECT  *-- 'use [' +d.name +'] DBCC SHRINKDATABASE (['+ m.name +'], TRUNCATEONLY);'
FROM sys.master_files m
INNER JOIN sys.databases d ON m.database_id = d.database_id