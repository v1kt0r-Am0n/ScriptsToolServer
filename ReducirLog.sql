USE AutorizadorSCI;  
GO 

ALTER DATABASE AutorizadorSCI  
SET RECOVERY SIMPLE;  
GO  
-- Shrink the truncated log file to 1 MB.  
DBCC SHRINKFILE (AutorizadorSCI_log,1);  
GO  
-- Reset the database recovery model.  
ALTER DATABASE AutorizadorSCI  
SET RECOVERY FULL;  
GO  
