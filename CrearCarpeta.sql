
declare @MD varchar(100), @wk_no varchar(100)

set @wk_no = 'D:\FilesRDL\' + Convert(VarChar(4),DatePart(Year,GetDate()))+Right('0'+Convert(VarChar(2),DatePart(Month,GetDate())),2)+Right('0'+Convert(VarChar(2),DatePart(Day,GetDate( ))),2)

SET @MD = ' mkdir ' + @wk_no

EXEC xp_cmdshell @MD, no_output
