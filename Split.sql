
--select top 1 valor  FROM          Split(Path,'/')
alter Function [dbo].[Split](
                           @String varchar(max)
                          ,@Delimiter char(1)
                         )
-- La función retornara una tabla con 2 campos.
returns @tablaTemporal TABLE ( Id int identity(1,1)
							  ,Valor varchar(400)
							  )
as
Begin
declare @idx    int
       ,@indice int
       ,@slice  varchar(8000)

select @indice = 1
      ,@idx    = 1

--Si el parametro @String esta vacio o es nulo ( return )
If len(@String)<1 or @String is null return
While @idx!= 0
  Begin
    Set @idx = CharIndex(@Delimiter,@String)

    If @idx! = 0      
      Set @slice = Left(@String,@idx - 1)
    Else
      set @slice = @String

    If(Len(@slice)>0)
      Insert Into @tablaTemporal(valor) values(@slice)
    Set @String = Right(@String,Len(@String) - @idx)
    Set @indice = @indice + 1
    If Len(@String) = 0 break -- Salir del Bucle
End
Return
End
/*
 DECLARE @FilterReportName AS VARCHAR(500) = NULL
  DECLARE @OutputPath AS VARCHAR(500) = 'D:\FilesRDL\'
DECLARE @FilterReportPath AS VARCHAR(500) = NULL 
  SELECT
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
                      ' CL.ItemID = ''''' + CONVERT(VARCHAR(MAX), CL.ItemID) + ''''' " queryout "' + @OutputPath + '' + CL.Name + '.rdl" ' + '-T -c -x'''
                    FROM
                      [ReportServer].[dbo].[Catalog] CL
                    WHERE
                      CL.[Type] = 2 --Report
                     AND '/' + CL.[Path] + '/' LIKE COALESCE('%/%' + @FilterReportPath + '%/%', '/' + CL.[Path] + '/')
                      AND CL.Name LIKE COALESCE('%' + @FilterReportName + '%', CL.Name)*/