-- =================================================================  
-- Caricamento gold.stock_forecast  
-- =================================================================  
  
CREATE OR ALTER PROCEDURE gold.load_stock_forecast  
AS  
BEGIN  
    BEGIN TRY  
  
        PRINT 'Caricamento gold.stock_forecast';  
  
        TRUNCATE TABLE gold.stock_forecast;  
        BULK INSERT gold.stock_forecast  
        FROM 'C:\Users\Carlo Alberto\Downloads\E-Commerce\Viste_ML\Serie_Temporali\forecasting_SQL\Forecasting.csv'  
        WITH (  
            FIRSTROW = 2,  
            FIELDTERMINATOR = ';',  
            ROWTERMINATOR = '0x0a',  
            CODEPAGE = '65001',  
            FORMAT = 'CSV',  
            FIELDQUOTE = '"',  
            TABLOCK  
        );  
  
    END TRY  
    BEGIN CATCH  
        PRINT 'ERRORE durante il caricamento: ' + ERROR_MESSAGE();  
    END CATCH  
END  