CREATE OR ALTER FUNCTION silver.fn_ParseDate (@input NVARCHAR(20))  
RETURNS DATE  
AS  
BEGIN  
    DECLARE @result DATE;  
  
    SET @result = TRY_CONVERT(DATE, @input, 23);    -- ISO: yyyy-mm-dd  
    IF @result IS NOT NULL RETURN @result;  
  
    SET @result = TRY_CONVERT(DATE, @input, 103);   -- Britannico: dd/mm/yyyy  
    IF @result IS NOT NULL RETURN @result;  
  
    SET @result = TRY_CONVERT(DATE, @input, 105);   -- Italiano: dd-mm-yyyy  
    IF @result IS NOT NULL RETURN @result;  
  
    RETURN NULL;   -- formato non riconosciuto (o input gia' NULL)  
END  