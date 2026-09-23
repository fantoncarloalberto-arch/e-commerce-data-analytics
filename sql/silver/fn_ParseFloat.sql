CREATE OR ALTER FUNCTION silver.fn_ParseFloat (@input NVARCHAR(20))  
RETURNS FLOAT  
AS  
BEGIN  
    RETURN TRY_CONVERT(FLOAT, REPLACE(TRIM(@input), ',', '.'));  
END  