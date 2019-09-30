declare @Metodo varchar(50)
set @Metodo='RegistarOpcion'
declare @Procedure varchar(50)
set @Procedure='admTblOpcion_Insert'
declare @Response varchar(50)
set @Response='List<Campania>'
---------------------------------------------------------------------
declare @WebInvoke  varchar(200)
declare @OutPutParameter  varchar(max)
declare @OutPutParameterNet  varchar(max)

set @OutPutParameter=''
set @OutPutParameterNet=''
DECLARE @parameter_id int,@ParameterName varchar(50), @ParameterDataType varchar(50);  
  
DECLARE contact_cursor CURSOR FOR  
-----------------------------
SELECT 
P.parameter_id ,
P.name AS [ParameterName],
TYPE_NAME(P.user_type_id) AS [ParameterDataType]
FROM sys.objects AS SO
INNER JOIN sys.parameters AS P 
ON SO.OBJECT_ID = P.OBJECT_ID
WHERE SO.OBJECT_ID IN ( SELECT OBJECT_ID 
FROM sys.objects
WHERE TYPE IN ('P','FN'))
and SO.name =@Procedure 
ORDER BY   P.parameter_id

  
OPEN contact_cursor;  
  
-- Perform the first fetch and store the values in variables.  
-- Note: The variables are in the same order as the columns  
-- in the SELECT statement.   
  
FETCH NEXT FROM contact_cursor  
INTO  @parameter_id ,@ParameterName , @ParameterDataType
  
-- Check @@FETCH_STATUS to see if there are any more rows to fetch.  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  
   -- Concatenate and display the current values in the variables.  
   --PRINT 'Contact Name: ' + @ParameterName + ' ' +  @ParameterDataType  
   set @OutPutParameter=@OutPutParameter +'/{' + SUBSTRING ( @ParameterName ,2, len(@ParameterName) )   + '}'
  set @OutPutParameterNet=@OutPutParameterNet + @ParameterDataType  + SUBSTRING ( @ParameterName ,2, len(@ParameterName) )   + ','
   --PRINT @OutPutParameter
   -- This is executed as long as the previous fetch succeeds.  
   FETCH NEXT FROM contact_cursor  
   INTO  @parameter_id ,@ParameterName, @ParameterDataType;  
END  
  
CLOSE contact_cursor;  
DEALLOCATE contact_cursor;  
 
-- set @WebInvoke='[WebInvoke(Method = "GET", UriTemplate = "/'+@Metodo+@OutPutParameter+'",'
--SELECT @Metodo ,@OutPutParameter
--select @OutPutParameterNet
print '[WebInvoke(Method = "GET", UriTemplate = "/'+@Metodo+@OutPutParameter+'",'
print 'ResponseFormat = WebMessageFormat.Json,'
print 'BodyStyle = WebMessageBodyStyle.Wrapped)]'
print  @Response +' '+@Metodo+'('+@OutPutParameterNet+');'


--select SUBSTRING ( '@idopcion' ,2, len('@idopcion') ) 


/****** Object:  UserDefinedFunction [dbo].[DEV_NETTYPE]    Script Date: 05/10/2016 06:08:20 p.m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--SELECT [idType]
--      ,[SqlType]
--      ,[NetType],
--	   'IF @SQLTYPE=''' +[SqlType] +''' BEGIN  	set @SQLTYPE=''' + [NetType] +''' END'
--  FROM [dbo].[TBL_DevTypes]
--GO

--select [DBO].[DEV_NETTYPE]('bigint','bigint','bigint','bigint')
CREATE FUNCTION [dbo].[DEV_NETTYPE]( @SQLTYPE VARCHAR(MAX), @LENGTH VARCHAR(MAX), @COLUMN VARCHAR(MAX),@UI VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS 
 BEGIN
 IF @SQLTYPE='bigint' BEGIN  	set @SQLTYPE='Int64' END
IF @SQLTYPE='binaria' BEGIN  	set @SQLTYPE='Byte[]' END
IF @SQLTYPE='bits' BEGIN  	set @SQLTYPE='Boolean' END
IF @SQLTYPE='char' BEGIN  	set @SQLTYPE='String' END
IF @SQLTYPE='date' BEGIN  	set @SQLTYPE='DateTime' END
IF @SQLTYPE='datetime' BEGIN  	set @SQLTYPE='DateTime' END
IF @SQLTYPE='decimal' BEGIN  	set @SQLTYPE='Decimal' END
IF @SQLTYPE='float' BEGIN  	set @SQLTYPE='Double' END
IF @SQLTYPE='imagen' BEGIN  	set @SQLTYPE='Byte[]' END
IF @SQLTYPE='int' BEGIN  	set @SQLTYPE='Int32' END
IF @SQLTYPE='money' BEGIN  	set @SQLTYPE='Decimal' END
IF @SQLTYPE='nchar' BEGIN  	set @SQLTYPE='String' END
IF @SQLTYPE='ntext' BEGIN  	set @SQLTYPE='String' END
IF @SQLTYPE='numéricas' BEGIN  	set @SQLTYPE='Decimal' END
IF @SQLTYPE='nvarchar' BEGIN  	set @SQLTYPE='String' END
IF @SQLTYPE='reales' BEGIN  	set @SQLTYPE='Single' END
IF @SQLTYPE='rowversion' BEGIN  	set @SQLTYPE='Byte[]' END
IF @SQLTYPE='smalldatetime' BEGIN  	set @SQLTYPE='DateTime' END
IF @SQLTYPE='smallint' BEGIN  	set @SQLTYPE='Int16' END
IF @SQLTYPE='smallmoney' BEGIN  	set @SQLTYPE='Decimal' END
IF @SQLTYPE='texto' BEGIN  	set @SQLTYPE='String' END
IF @SQLTYPE='tinyint' BEGIN  	set @SQLTYPE='Byte' END
IF @SQLTYPE='uniqueidentifier' BEGIN  	set @SQLTYPE='Guid' END
IF @SQLTYPE='varbinary' BEGIN  	set @SQLTYPE='Byte[]' END
IF @SQLTYPE='varchar' BEGIN  	set @SQLTYPE='String' END
IF @SQLTYPE='xml' BEGIN  	set @SQLTYPE='Xml' END
     RETURN  @SQLTYPE
END

GO


------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
declare @Objeto varchar(50)
set @Objeto='RegistarOpcion'
declare @Procedure varchar(50)
set @Procedure='USR_DETALLE_COMERCIO'
declare @Response varchar(50)
set @Response='List<Campania>'
declare @OutPutParameter  varchar(max)
  declare @icont Int 
  set @icont=0;
DECLARE @parameter_id int,@ParameterName varchar(50), @ParameterDataType varchar(50); 

DECLARE contact_cursor CURSOR FOR  
-----------------------------
SELECT 
P.parameter_id ,
P.name AS [ParameterName],
TYPE_NAME(P.user_type_id) AS [ParameterDataType]
FROM sys.objects AS SO
INNER JOIN sys.parameters AS P 
ON SO.OBJECT_ID = P.OBJECT_ID
WHERE SO.OBJECT_ID IN ( SELECT OBJECT_ID 
FROM sys.objects
WHERE TYPE IN ('P','FN'))
and SO.name =@Procedure 
ORDER BY   P.parameter_id
print '                List< '+ @Objeto +' > response = new List< '+ @Objeto +' >();'
print '                '+ @Objeto +' o'+ @Objeto +' = new  '+ @Objeto +' ();'
print '                DataTable ds = new DataTable();'
print '                SqlConnection conexion = default(SqlConnection);'
print '                try'
print '                {'
print '                conexion = new SqlConnection(connectionString);'
print '                SqlCommand comandoSP = new SqlCommand("'+ @Procedure +'", conexion);'
              
print '                comandoSP.CommandTimeout = 9000;'
print '                comandoSP.CommandType = CommandType.StoredProcedure;'

--------------------------------------------------------------------------------------------------
---**********************************************************************************************-
DECLARE contact_cursorParam CURSOR FOR  
-----------------------------
SELECT 
P.parameter_id ,
P.name AS [ParameterName],
TYPE_NAME(P.user_type_id) AS [ParameterDataType]
FROM sys.objects AS SO
INNER JOIN sys.parameters AS P 
ON SO.OBJECT_ID = P.OBJECT_ID
WHERE SO.OBJECT_ID IN ( SELECT OBJECT_ID 
FROM sys.objects
WHERE TYPE IN ('P','FN'))
and SO.name =@Procedure 
ORDER BY   P.parameter_id

  
OPEN contact_cursorParam;  
  
-- Perform the first fetch and store the values in variables.  
-- Note: The variables are in the same order as the columns  
-- in the SELECT statement.   
  
FETCH NEXT FROM contact_cursorParam  
INTO  @parameter_id ,@ParameterName , @ParameterDataType
  
-- Check @@FETCH_STATUS to see if there are any more rows to fetch.  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  
   -- Concatenate and display the current values in the variables.  
   --PRINT 'Contact Name: ' + @ParameterName + ' ' +  @ParameterDataType  
  -- set @OutPutParameter=@OutPutParameter +'/{' + SUBSTRING ( @ParameterName ,2, len(@ParameterName) )   + '}'
  --set @OutPutParameterNet=@OutPutParameterNet + @ParameterDataType  + SUBSTRING ( @ParameterName ,2, len(@ParameterName) )   + ','
  -- PRINT ParameterName
    PRINT '                                comandoSP.Parameters.Add(new SqlParameter("'+ @ParameterName + '", SqlDbType.' +  @ParameterDataType +')).Value = ' +  @ParameterDataType +'.Parse(' + SUBSTRING ( @ParameterName ,2, len(@ParameterName) )   +');'
   -- This is executed as long as the previous fetch succeeds.  
   FETCH NEXT FROM contact_cursorParam  
   INTO  @parameter_id ,@ParameterName, @ParameterDataType;  
END  
  
CLOSE contact_cursorParam;  
DEALLOCATE contact_cursorParam;  
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
print '                SqlDataAdapter da = new SqlDataAdapter();'
print '                da.SelectCommand = comandoSP;'
print '                conexion.Open();'
print '                da.Fill(ds);'
print '                  if (ds.Rows.Count > 0)'
print '                    {'
print '                      foreach (DataRow row in ds.Rows)'
print '                         {'
  
OPEN contact_cursor;  
  
-- Perform the first fetch and store the values in variables.  
-- Note: The variables are in the same order as the columns  
-- in the SELECT statement.   
  
FETCH NEXT FROM contact_cursor  
INTO  @parameter_id ,@ParameterName , @ParameterDataType

-- Check @@FETCH_STATUS to see if there are any more rows to fetch.  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  
   -- Concatenate and display the current values in the variables.  
   --PRINT 'Contact Name: ' + @ParameterName + ' ' +  @ParameterDataType  
    PRINT '                               o'+ @Objeto+'.'+ SUBSTRING ( @ParameterName ,2, len(@ParameterName) )  +'=' + 'int.Parse(row['+convert(varchar(20),@icont)+'].ToString());'
	set @icont=@icont+1
   -- This is executed as long as the previous fetch succeeds.  
   FETCH NEXT FROM contact_cursor  
   INTO  @parameter_id ,@ParameterName, @ParameterDataType;  
END  
  
CLOSE contact_cursor;  
DEALLOCATE contact_cursor;  
print '                                  response.Add(oBuzonMensaje);'
print '                     }  '        
print '                   }'
print '                }'
print '                           catch (Exception ex)'
print '                           {'
print '                               DALLog("", "", ex.Message.ToString());'
print '                            }'
print '                           finally'
print '                           {'
print '                               conexion.Close();'
print '                               conexion.Dispose();'
print '                           }'
print '                           return response;'

------------------------------------------------------------------------

--print 'if (ds.Rows.Count > 0)'
--print '    {'
--print '     foreach (DataRow row in ds.Rows)'
--print '          {'
--print '                 oBuzonMensaje.Fecha  = DateTime.Parse(row[1].ToString());'
--print '                 oBuzonMensaje.idCormercio= int.Parse(row[1].ToString());'
--print '                 oBuzonMensaje.IdPersona = int.Parse(row[1].ToString());'
--print '                 oBuzonMensaje.imagen = row[1].ToString();'
--print '                 oBuzonMensaje.Mensaje = row[1].ToString();'
--print '                 response.Add(oBuzonMensaje);'
--print '            }  '        
--print '     }'


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
declare @Objeto varchar(50)
set @Objeto='DetalleComercio'
declare @Procedure varchar(50)
set @Procedure='USR_DETALLE_COMERCIO'
declare @Response varchar(50)
set @Response='List<Comercio>'
declare @OutPutParameter  varchar(max)
  declare @icont Int 
  set @icont=0;
DECLARE @parameter_id int,@ParameterName varchar(50), @ParameterDataType varchar(50); 
--------------------------------------------------------------------------------------------------
---**********************************************************************************************-
DECLARE contact_cursorParam CURSOR FOR  
-----------------------------
SELECT 
P.parameter_id ,
P.name AS [ParameterName],
TYPE_NAME(P.user_type_id) AS [ParameterDataType]
FROM sys.objects AS SO
INNER JOIN sys.parameters AS P 
ON SO.OBJECT_ID = P.OBJECT_ID
WHERE SO.OBJECT_ID IN ( SELECT OBJECT_ID 
FROM sys.objects
WHERE TYPE IN ('P','FN'))
and SO.name =@Procedure 
ORDER BY   P.parameter_id

  
OPEN contact_cursorParam;  
  
-- Perform the first fetch and store the values in variables.  
-- Note: The variables are in the same order as the columns  
-- in the SELECT statement.   
  
FETCH NEXT FROM contact_cursorParam  
INTO  @parameter_id ,@ParameterName , @ParameterDataType
  
-- Check @@FETCH_STATUS to see if there are any more rows to fetch.  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  
   -- Concatenate and display the current values in the variables.  
   --PRINT 'Contact Name: ' + @ParameterName + ' ' +  @ParameterDataType  
  -- set @OutPutParameter=@OutPutParameter +'/{' + SUBSTRING ( @ParameterName ,2, len(@ParameterName) )   + '}'
  --set @OutPutParameterNet=@OutPutParameterNet + @ParameterDataType  + SUBSTRING ( @ParameterName ,2, len(@ParameterName) )   + ','
  -- PRINT ParameterName
   PRINT 'comandoSP.Parameters.Add(new SqlParameter("'+ @ParameterName + '", SqlDbType.' +  @ParameterDataType +')).Value = ' +  @ParameterDataType +'.Parse(' + SUBSTRING ( @ParameterName ,2, len(@ParameterName) )   +');'
   -- This is executed as long as the previous fetch succeeds.  
   FETCH NEXT FROM contact_cursorParam  
   INTO  @parameter_id ,@ParameterName, @ParameterDataType;  
END  
  
CLOSE contact_cursorParam;  
DEALLOCATE contact_cursorParam;  
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------