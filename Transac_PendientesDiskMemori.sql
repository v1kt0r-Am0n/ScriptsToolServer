SELECT  SUM ( pending_disk_io_count ) AS [Número de E / S pendientes] FROM sys . dm_os_schedulers  
SELECT  *  from sys.dm_io_pending_io_requests


SELECT  SUM ( pending_disk_io_count ) AS [Número de E / S pendientes] FROM sys . dm_os_schedulers  
SELECT  *  from sys.dm_io_pending_io_requests
SELECT  DB_NAME ( database_id ) AS [Database] , [file_id] , [io_stall_read_ms] , [io_stall_write_ms] , [io_stall] 
FROM sys.dm_io_virtual_file_stats (NULL, NULL)  
