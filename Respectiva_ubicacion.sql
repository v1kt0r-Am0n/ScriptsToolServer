---Listar todas las bases de datos con su respectiva ubicación y tamaños 


select d.database_id,d.name, a.name as filename,a.physical_name as ubication,
 a.type_desc,(a.size/128)as sizeMB, recovery_model_desc,d.state_desc,compatibility_level
from sys.master_files a inner join sys.databases d on (a.database_id = d.database_id)
order by a.type,a.size



---Listar todas las bases de datos fuera de lines


select d.database_id,d.name, a.name as filename,a.physical_name as ubication,
 a.type_desc,(a.size/128)as sizeMB, recovery_model_desc,d.state_desc,compatibility_level
from sys.master_files a inner join sys.databases d on (a.database_id = d.database_id)
where d.state_desc='OFFLINE'
order by a.physical_name

----Script para mover H:\DATA.DBDESASQLCLU1\  mdf
select 'MOVE "' + a.physical_name  +'"  "H:\DATA.DBDESASQLCLU1\'+d.name+'.mdf"'

from sys.master_files a inner join sys.databases d on (a.database_id = d.database_id)
where d.state_desc='OFFLINE' and type_desc ='ROWS'
order by a.physical_name



select d.database_id,d.name, a.name as filename,a.physical_name as ubication,
 a.type_desc,(a.size/128)as sizeMB, recovery_model_desc,d.state_desc,compatibility_level
from sys.master_files a inner join sys.databases d on (a.database_id = d.database_id)
where d.state_desc='OFFLINE' and type_desc ='LOG'
order by a.physical_name


----Script para mover F:\LOG.DBDESASQLCLU1\
select 'MOVE "' + a.physical_name  +'"  "F:\LOG.DBDESASQLCLU1\'+a.name+'.ldf"'

from sys.master_files a inner join sys.databases d on (a.database_id = d.database_id)
where d.state_desc='OFFLINE' and type_desc ='LOG'
order by a.physical_name



select d.name, a.name , a.type_desc
from sys.master_files a inner join sys.databases d on (a.database_id = d.database_id)
where d.state_desc='OFFLINE'

USE [master]
GO
CREATE DATABASE [000GestorDocumental_V2] ON 
( FILENAME = N'H:\DATA.DBDESASQLCLU1\GestorDocumental_V2.mdf' ),
( FILENAME = N'F:\LOG.DBDESASQLCLU1\GestorDocumental_log_V2.ldf' )
 FOR ATTACH
GO
