SELECT r.session_id,
       r.command Comando,
       CONVERT(NUMERIC(10, 2), r.percent_complete) AS 'Porcentaje',
       CONVERT(NUMERIC(10,2), r.total_elapsed_time / 1000.0 / 60.0) AS 'Tiempo transcurrido',
       CONVERT(VARCHAR(20), Dateadd(ms, r.estimated_completion_time, Getdate()),20) AS 'Estimado finalización',
       CONVERT(NUMERIC(10, 2), r.estimated_completion_time/1000.0/60.0) AS 'Minutos pendientes',
       CONVERT(NUMERIC(10,2), r.estimated_completion_time/1000.0/60.0/60.0) AS 'Horas pendientes'
FROM  sys.dm_exec_requests r
WHERE r.command IN (
         'RESTORE VERIFYON', 'RESTORE DATABASE',
         'BACKUP DATABASE','RESTORE LOG','BACKUP LOG', 
         'RESTORE HEADERON', 'DbccFilesCompact'
)