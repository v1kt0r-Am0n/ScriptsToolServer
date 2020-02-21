---Reducir el mdf

---generar script
use master
SELECT  'use [' +d.name +'] DBCC SHRINKDATABASE (['+ m.name +'], 10);'
FROM sys.master_files m
INNER JOIN sys.databases d ON m.database_id = d.database_id