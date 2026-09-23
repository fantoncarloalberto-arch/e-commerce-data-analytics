CREATE OR ALTER  FUNCTION silver.fn_TitleCase (@input NVARCHAR(200))  
RETURNS NVARCHAR(200)  
AS  
BEGIN  
    RETURN (  
        SELECT STRING_AGG(  
                   UPPER(LEFT(value, 1)) + LOWER(SUBSTRING(value, 2, LEN(value))),  
                   ' '  
               ) WITHIN GROUP (ORDER BY ordinal)  
        FROM STRING_SPLIT(LTRIM(RTRIM(@input)), ' ', 1)   
        WHERE value <> ''  
    );  
END  