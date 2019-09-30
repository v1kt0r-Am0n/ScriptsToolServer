exec sp_executesql N'INSERT INTO cenGruposIdentificacion(fecha,identificacion,tipo,tipoIdentificacion) VALUES(@P1,@P2,@P3,@P4) Select max(id) as Consulta from cengruposIdentificacion',N'@P1 datetime,@P2 nvarchar(7),@P3 nvarchar(1),@P4 int','2015-01-29 00:00:00',N'8718691',N'0',1
go
exec sp_reset_connection
go
exec sp_executesql N'INSERT INTO cenClientesConsultados(IdGrupoIdentificacion,tipoIdentificacion,numeroIdentificacion,primerApellido,codigo,control,fechaSalida,fechaEntrada) VALUES(@P1,@P2,@P3,@P4,@P5,@P6,@P7,@P8) Select max(id) as Consulta from cenClientesConsultados',N'@P1 int,@P2 int,@P3 nvarchar(7),@P4 nvarchar(4),@P5 int,@P6 int,@P7 datetime,@P8 datetime',379,1,N'8718691',N'DAZA',1,0,'2015-01-29 10:58:25.230','2015-01-29 10:58:25.230'
go
exec sp_executesql N'Update cenGruposIdentificacion set fecha = @fecha, tipo= @tipo where id = 379',N'@fecha datetime,@tipo nvarchar(2)',@fecha='2015-01-29 10:55:35.033',@tipo=N'13'
go
exec sp_executesql N'INSERT INTO cenNaturalesNacional(id,nombres,primerApellido,segundoApellido,nombreCompleto,genero,validada,estadoidentificacion,fechaExpedicionidentificacion,ciudadidentificacion,departamentoidentificacion,numeroidentificacion,minedad,maxedad) VALUES(@id,@nombres,@primerApellido,@segundoApellido,@nombreCompleto,@genero,@validada,@estadoidentificacion,@fechaExpedicionidentificacion,@ciudadidentificacion,@departamentoidentificacion,@numeroidentificacion,@minedad,@maxedad)',N'@id nvarchar(3),@nombres nvarchar(8),@primerApellido nvarchar(4),@segundoApellido nvarchar(6),@nombreCompleto nvarchar(20),@genero nvarchar(1),@validada nvarchar(1),@estadoidentificacion nvarchar(2),@fechaExpedicionidentificacion datetime,@ciudadidentificacion nvarchar(12),@departamentoidentificacion nvarchar(9),@numeroidentificacion nvarchar(11),@minedad nvarchar(2),@maxedad nvarchar(2)',@id=N'379',@nombres=N'GILBERTO',@primerApellido=N'DAZA',@segundoApellido=N'ARAGON',@nombreCompleto=N'DAZA ARAGON GILBERTO',@genero=N'4',@validada=N'1',@estadoidentificacion=N'00',@fechaExpedicionidentificacion='1980-07-07 00:00:00',@ciudadidentificacion=N'BARRANQUILLA',@departamentoidentificacion=N'ATLANTICO',@numeroidentificacion=N'00008718691',@minedad=N'46',@maxedad=N'55'
go
exec sp_executesql N'INSERT INTO cenScore(id,tipo,puntaje) VALUES(@id,@tipo,@puntaje)',N'@id nvarchar(3),@tipo nvarchar(2),@puntaje nvarchar(5)',@id=N'379',@tipo=N'47',@puntaje=N'444.0'
go
Select max(idScore) from cenScore where id = 379
go
INSERT INTO cenRazones(id,idScore,codigo) values(379,310,'00099')
go
INSERT INTO cenRazones(id,idScore,codigo) values(379,310,'00000')
go
exec sp_executesql N'INSERT INTO cenCuentasAhorro(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(22),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'B. FALABELLA   AHORROS',@ultimaActualizacion='2014-05-01 00:00:00',@numeroCuenta=N'060009179',@fechaApertura='2011-10-01 00:00:00',@oficina=N'OFICINA CALL',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasAhorro) from cenCuentasAhorro where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasAhorro(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(22),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'B. FALABELLA   AHORROS',@ultimaActualizacion='2014-05-01 00:00:00',@numeroCuenta=N'060001611',@fechaApertura='2011-10-01 00:00:00',@oficina=N'OFICINA CALL',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasAhorro) from cenCuentasAhorro where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasAhorro(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(13),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'BCO SANTANDER',@ultimaActualizacion='2013-03-01 00:00:00',@numeroCuenta=N'074132081',@fechaApertura='1997-08-01 00:00:00',@oficina=N'BARRANQUILLA',@ciudad=N'BAR',@bloqueada=N'0'
go
Select max(idCuentasAhorro) from cenCuentasAhorro where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasAhorro(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(13),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'BCO SANTANDER',@ultimaActualizacion='2013-03-01 00:00:00',@numeroCuenta=N'222126754',@fechaApertura='2010-03-01 00:00:00',@oficina=N'AVENIDA PEPE',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasAhorro) from cenCuentasAhorro where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasAhorro(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(23),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'CITIBANK       COLOMBIA',@ultimaActualizacion='2013-10-01 00:00:00',@numeroCuenta=N'001960071',@fechaApertura='2011-03-01 00:00:00',@oficina=N'PRQ. CENTRAL',@ciudad=N'CIU',@bloqueada=N'0'
go
Select max(idCuentasAhorro) from cenCuentasAhorro where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasAhorro(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(13),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(6),@bloqueada nvarchar(1)',@id=N'379',@estado=N'05',@entidad=N'BCO DE BOGOTA',@ultimaActualizacion='2010-04-01 00:00:00',@numeroCuenta=N'009304734',@fechaApertura='2007-02-01 00:00:00',@oficina=N'000009',@bloqueada=N'0'
go
Select max(idCuentasAhorro) from cenCuentasAhorro where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasAhorro(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(11),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(9),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'05',@entidad=N'BANCOLOMBIA',@ultimaActualizacion='2013-07-01 00:00:00',@numeroCuenta=N'415693133',@fechaApertura='2003-11-01 00:00:00',@oficina=N'CALLE 101',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasAhorro) from cenCuentasAhorro where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasAhorro(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(11),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(8),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'09',@entidad=N'BANCOLOMBIA',@ultimaActualizacion='2009-08-01 00:00:00',@numeroCuenta=N'145907201',@fechaApertura='2005-04-01 00:00:00',@oficina=N'LA SALLE',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasAhorro) from cenCuentasAhorro where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasCorriente(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(22),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'B. FALABELLA   CTA CTE',@ultimaActualizacion='2014-05-01 00:00:00',@numeroCuenta=N'060007323',@fechaApertura='2011-11-01 00:00:00',@oficina=N'OFICINA CALL',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasCorriente) from cenCuentasCorriente where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasCorriente(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(13),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'BCO SANTANDER',@ultimaActualizacion='2013-03-01 00:00:00',@numeroCuenta=N'222062317',@fechaApertura='2010-03-01 00:00:00',@oficina=N'AVENIDA PEPE',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasCorriente) from cenCuentasCorriente where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasCorriente(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(13),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'BCO SANTANDER',@ultimaActualizacion='2013-03-01 00:00:00',@numeroCuenta=N'222063919',@fechaApertura='2011-10-01 00:00:00',@oficina=N'AVENIDA PEPE',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasCorriente) from cenCuentasCorriente where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasCorriente(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(13),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'06',@entidad=N'HELM BANK S.A',@ultimaActualizacion='2013-07-01 00:00:00',@numeroCuenta=N'012405064',@fechaApertura='2010-07-01 00:00:00',@oficina=N'OFICINA WORL',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasCorriente) from cenCuentasCorriente where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasCorriente(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(14),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'01',@entidad=N'BCO DAVIVIENDA',@ultimaActualizacion='2014-07-01 00:00:00',@numeroCuenta=N'360045089',@fechaApertura='2009-10-01 00:00:00',@oficina=N'BTA UNICENTR',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasCorriente) from cenCuentasCorriente where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasCorriente(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(23),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(12),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'09',@entidad=N'CITIBANK       COLOMBIA',@ultimaActualizacion='2013-07-01 00:00:00',@numeroCuenta=N'001960063',@fechaApertura='2011-03-01 00:00:00',@oficina=N'PRQ. CENTRAL',@ciudad=N'CIU',@bloqueada=N'0'
go
Select max(idCuentasCorriente) from cenCuentasCorriente where id = 379
go
exec sp_executesql N'INSERT INTO cenCuentasCorriente(id,estado,entidad,ultimaActualizacion,numeroCuenta,fechaApertura,oficina,ciudad,bloqueada) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numeroCuenta,@fechaApertura,@oficina,@ciudad,@bloqueada)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(11),@ultimaActualizacion datetime,@numeroCuenta nvarchar(9),@fechaApertura datetime,@oficina nvarchar(9),@ciudad nvarchar(3),@bloqueada nvarchar(1)',@id=N'379',@estado=N'05',@entidad=N'BANCOLOMBIA',@ultimaActualizacion='2013-04-01 00:00:00',@numeroCuenta=N'253810631',@fechaApertura='2009-10-01 00:00:00',@oficina=N'CALLE 101',@ciudad=N'BOG',@bloqueada=N'0'
go
Select max(idCuentasCorriente) from cenCuentasCorriente where id = 379
go
exec sp_executesql N'INSERT INTO cenTarjetasCredito(id,estado,entidad,ultimaActualizacion,numero,fechaApertura,fechaVencimiento,bloqueada,positivoNegativo,comportamiento,amparada,formaPago,situacionTitular,oficina,estadoOrigen) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numero,@fechaApertura,@fechaVencimiento,@bloqueada,@positivoNegativo,@comportamiento,@amparada,@formaPago,@situacionTitular,@oficina,@estadoOrigen)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(13),@ultimaActualizacion datetime,@numero nvarchar(9),@fechaApertura datetime,@fechaVencimiento datetime,@bloqueada nvarchar(1),@positivoNegativo nvarchar(1),@comportamiento nvarchar(47),@amparada nvarchar(1),@formaPago nvarchar(1),@situacionTitular nvarchar(1),@oficina nvarchar(10),@estadoOrigen nvarchar(1)',@id=N'379',@estado=N'45',@entidad=N'CMR FALABELLA',@ultimaActualizacion='2014-07-01 00:00:00',@numero=N'116812307',@fechaApertura='2011-10-01 00:00:00',@fechaVencimiento='2021-10-01 00:00:00',@bloqueada=N'0',@positivoNegativo=N'N',@comportamiento=N'CCCCCCCCCCCCCCC654321NNNNNNNNNNN---------------',@amparada=N'0',@formaPago=N'0',@situacionTitular=N'0',@oficina=N'NO INFORMO',@estadoOrigen=N'0'
go
Select max(idTarjetasCredito) from cenTarjetasCredito where id = 379
go
INSERT INTO cenValores(id,idTarjetasCredito,cupo,saldoActual,saldoMora,cuota) values(379,973,13790000,22707000,23299000,11037000)
go
exec sp_executesql N'INSERT INTO cenTarjetasCredito(id,estado,entidad,ultimaActualizacion,numero,fechaApertura,fechaVencimiento,bloqueada,positivoNegativo,comportamiento,amparada,formaPago,situacionTitular,oficina,estadoOrigen) VALUES(@id,@estado,@entidad,@ultimaActualizacion,@numero,@fechaApertura,@fechaVencimiento,@bloqueada,@positivoNegativo,@comportamiento,@amparada,@formaPago,@situacionTitular,@oficina,@estadoOrigen)',N'@id nvarchar(3),@estado nvarchar(2),@entidad nvarchar(13),@ultimaActualizacion datetime,@numero nvarchar(9),@fechaApertura datetime,@fechaVencimiento datetime,@bloqueada nvarchar(1),@positivoNegativo nvarchar(1),@comportamiento nvarchar(47),@amparada nvarchar(1),@formaPago nvarchar(1),@situacionTitular nvarchar(1),@oficina nvarchar(10),@estadoOrigen nvarchar(1)',@id=N'379',@estado=N'45',@entidad=N'HELM BANK S.A',@ultimaActualizacion='2014-06-01 00:00:00',@numero=N'301783002',@fechaApertura='2010-07-01 00:00:00',@fechaVencimiento='2016-02-01 00:00:00',@bloqueada=N'0',@positivoNegativo=N'N',@comportamiento=N'CCCCCC6666666666654-321NNNNNNNNNNNNNNNN--------',@amparada=N'0',@formaPago=N'0',@situacionTitular=N'0',@oficina=N'NO INFORMO',@estadoOrigen=N'0'
go



select  *  from  cenTarjetasCredito where  estado='45'
select  *  from  cenCuentasCorriente where  estado='45'
select  *  from  cenCuentasCartera where  estado='45'

select distinct entidad from  cenCuentasCartera where  estado='45' order  by 1



SELECT *
FROM sys.dm_exec_query_stats as stats
        CROSS APPLY (
           SELECT text as source_code
           FROM sys.dm_exec_sql_text(sql_handle)
        ) AS query_text
ORDER BY last_execution_time desc