

/*
CREACION DE FOLDER
*/
DECLARE @pathRepor varchar (500)
DECLARE @FECHAINICIAL VARCHAR (8)

DECLARE @ANO VARCHAR (4)
DECLARE @MES VARCHAR (2)
DECLARE @DIA VARCHAR (2)

SET @ANO = (select YEAR(GETDATE()))
SET @MES = (SELECT RIGHT( REPLICATE('0',2) +(select CONVERT(VARCHAR,MONTH(GETDATE()))), 2 ))
SET @DIA =  (SELECT RIGHT( REPLICATE('0',2) +(select CONVERT(VARCHAR,DAY(GETDATE()-3))), 2 )) 


SET @FECHAINICIAL = (SELECT @ANO+@MES+@DIA)

DECLARE CreacionCarpetas CURSOR FOR 

       select  
             REPLACE(path ,'/','\')
       from [ReportServer].[dbo].[Catalog]
       WHERE path NOT IN ('')

OPEN CreacionCarpetas

FETCH NEXT FROM CreacionCarpetas 
INTO @pathRepor

WHILE @@FETCH_STATUS = 0
BEGIN
       
       PRINT @pathRepor
       declare @MD varchar(100), 
                 @wk_no varchar(100)
       
       set @wk_no = 'G:\Backups\Reportes' + replace(@pathRepor,' ','_')
       print @wk_no
       SET @MD = ' mkdir ' + @wk_no
       EXEC xp_cmdshell @MD, no_output   
       
       FETCH NEXT FROM CreacionCarpetas 
       INTO @pathRepor

END
CLOSE CreacionCarpetas;
DEALLOCATE CreacionCarpetas;



/*
CREACION DE reportes en las rutas
*/


DECLARE @FECHAINICIAL VARCHAR (8)

DECLARE @ANO VARCHAR (4)
DECLARE @MES VARCHAR (2)
DECLARE @DIA VARCHAR (2)

SET @ANO = (select YEAR(GETDATE()))
SET @MES = (SELECT RIGHT( REPLICATE('0',2) +(select CONVERT(VARCHAR,MONTH(GETDATE()))), 2 ))
SET @DIA =  (SELECT RIGHT( REPLICATE('0',2) +(select CONVERT(VARCHAR,DAY(GETDATE()-3))), 2 )) 

SET @FECHAINICIAL = (SELECT @ANO+@MES+@DIA)

/*
EXEC sp_configure 'show advanced options', 1
GO
-- Update the currently configured value for advanced options.
RECONFIGURE
GO
-- Enable xp_cmdshell
EXEC sp_configure 'xp_cmdshell', 1
GO
-- Update the currently configured value for xp_cmdshell
RECONFIGURE
GO
-- Disallow further advanced options to be changed.
EXEC sp_configure 'show advanced options', 0
GO
-- Update the currently configured value for advanced options.
RECONFIGURE
GO
*/


--Replace NULL with keywords of the ReportManager's Report Path, 
--if reports from any specific path are to be downloaded
DECLARE @FilterReportPath AS VARCHAR(500) = NULL 
--Replace NULL with the keyword matching the Report File Name,
--if any specific reports are to be downloaded
DECLARE @FilterReportName AS VARCHAR(500) = NULL
--Replace this path with the Server Location where you want the
--reports to be downloaded..
DECLARE @OutputPath AS VARCHAR(500) = 'G:\Backups\Reportes'
--Used to prepare the dynamic query
DECLARE @TSQL AS NVARCHAR(MAX)
--Reset the OutputPath separator.
SET @OutputPath = REPLACE(@OutputPath,'\','/')
--Simple validation of OutputPath; this can be changed as per ones need.
IF LTRIM(RTRIM(ISNULL(@OutputPath,''))) = ''
BEGIN
  SELECT 'Invalid Output Path'
END
ELSE
BEGIN
   --Prepare the query for download.
   /*
   Please note the following points -
   1. The BCP command could be modified as per ones need. E.g. Providing UserName/Password, etc.
   2. Please update the SSRS Report Database name. Currently, it is set to default - [ReportServer]
   3. The BCP does not create missing Directories. So, additional logic could be implemented to handle that.
   4. SSRS stores the XML items (Report RDL and Data Source definitions) using the UTF-8 encoding. 
      It just so happens that UTF-8 Unicode strings do not NEED to have a BOM and in fact ideally would not have one. 
      However, you will see some report items in your SSRS that begin with a specific sequence of bytes (0xEFBBBF). 
      That sequence is the UTF-8 Byte Order Mark. It�s character representation is the following three characters, ��. 
      While it is supported, it can cause problems with the conversion to XML, so it is removed.
   */
  SET @TSQL = STUFF((SELECT
                      ';EXEC master..xp_cmdshell ''bcp " ' +
                      ' SELECT ' +
                      ' CONVERT(VARCHAR(MAX), ' +
                      '       CASE ' +
                      '         WHEN LEFT(C.Content,3) = 0xEFBBBF THEN STUFF(C.Content,1,3,'''''''') '+
                      '         ELSE C.Content '+
                      '       END) ' +
                      ' FROM ' +
                      ' [ReportServer].[dbo].[Catalog] CL ' +
                      ' CROSS APPLY (SELECT CONVERT(VARBINARY(MAX),CL.Content) Content) C ' +
                      ' WHERE ' +
                      ' CL.ItemID = ''''' + CONVERT(VARCHAR(MAX), CL.ItemID) + ''''' " queryout "' + @OutputPath +  replace(CL.[Path],' ','_') + '/' +CL.Name + '.rdl" ' + '-T -c -x'''
                    FROM
                      [ReportServer].[dbo].[Catalog] CL
                    WHERE
                      CL.[Type] = 2 --Report
                     AND '/' + CL.[Path] + '/' LIKE COALESCE('%/%' + @FilterReportPath + '%/%', '/' + CL.[Path] + '/')
                      AND CL.Name LIKE COALESCE('%' + @FilterReportName + '%', CL.Name)
                    FOR XML PATH('')), 1,1,'')

  --SELECT @TSQL
  --Execute the Dynamic Query
  EXEC SP_EXECUTESQL @TSQL

END
