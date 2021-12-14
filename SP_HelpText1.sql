CREATE PROCEDURE [dbo].[sp_helptext1] (@ProcName NVARCHAR(256))
AS
BEGIN
  DECLARE @PROC_TABLE TABLE (X1  NVARCHAR(MAX))

  DECLARE @Proc NVARCHAR(MAX)
  DECLARE @Procedure NVARCHAR(MAX)
  DECLARE @ProcLines TABLE (PLID INT IDENTITY(1,1), Line NVARCHAR(MAX))

  SELECT @Procedure = 'SELECT DEFINITION FROM '+db_name()+'.SYS.SQL_MODULES WHERE OBJECT_ID = OBJECT_ID('''+@ProcName+''')'

  insert into @PROC_TABLE (X1)
        exec  (@Procedure)

  SELECT @Proc=X1 from @PROC_TABLE

  WHILE CHARINDEX(CHAR(13)+CHAR(10),@Proc) > 0
  BEGIN
        INSERT @ProcLines
        SELECT LEFT(@Proc,CHARINDEX(CHAR(13)+CHAR(10),@Proc)-1)
        SELECT @Proc = SUBSTRING(@Proc,CHARINDEX(CHAR(13)+CHAR(10),@Proc)+2,LEN(@Proc))
  END

 insert @ProcLines 
 select @Proc ;

 SELECT Line FROM @ProcLines where Line<>'' ORDER BY PLID
END
