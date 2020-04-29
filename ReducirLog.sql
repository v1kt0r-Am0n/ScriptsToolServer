USE nombre_base;  
GO 

ALTER DATABASE nombre_base  
SET RECOVERY SIMPLE;  
GO  
-- Shrink the truncated log file to 1 MB.  
DBCC SHRINKFILE (nombre_base_log,1);  
GO  
-- Reset the database recovery model.  
ALTER DATABASE nombre_base  
SET RECOVERY FULL;  
GO  
