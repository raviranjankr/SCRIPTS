-- Function to get SHA256 of any value

CREATE function [dbo].[get_SHA256]
(
@Value varchar(100)
)
returns varchar(100)
as
begin
Declare @varBina_Val as varbinary(100)
if(@Value<>'')
begin
 set @varBina_Val=  HASHBYTES('SHA2_256', @Value) ;
end
else 
begin
  set @varBina_Val=  null;
end
 return lower(convert(nvarchar(100),@varBina_Val,2))
end
GO
--SHA256 value of 'ABC' is 'b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78' 
select dbo.get_SHA256('ABC')

-- Reference : https://docs.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql?view=sql-server-ver15
