-- =================================================================  
-- Caricamento gold.association_rules  
-- =================================================================  
  
CREATE OR ALTER PROCEDURE gold.load_association_rules  
AS  
BEGIN  
    BEGIN TRY  
  
        PRINT 'Caricamento gold.association_rules';  
  
        TRUNCATE TABLE gold.association_rules;  
  
        BULK INSERT gold.association_rules  
        FROM 'C:\Users\Carlo Alberto\Downloads\E-Commerce\Viste_ML\MBA\MBA_sql\mba_regole_sottocategoria.csv'  
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