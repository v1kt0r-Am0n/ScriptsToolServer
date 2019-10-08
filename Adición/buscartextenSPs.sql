SELECT
distinct so.name
--,sc.text
FROM
sysobjects so
INNER JOIN syscomments sc ON so.id = sc.id
WHERE
--so.type = 'P' AND
sc.text LIKE '%SELECT *%'


SELECT distinct
so.name
--,sc.text
FROM
sysobjects so
INNER JOIN syscomments sc ON so.id = sc.id
WHERE
--so.type = 'P' AND
sc.text LIKE '%SELECT *%'

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE CVSP_Sw_InserLogCrearAsnet
	@Descripcion VARCHAR(MAX)
	, @Etapa VARCHAR(50)
	, @Documento VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [dbo].[TBL_Sw_CV_LogCrearAsnet]
           ([Log], [Etapa], [Descripcion], [Documento])
    VALUES
           (GETDATE(), @Etapa, @Descripcion, @Documento)
END
