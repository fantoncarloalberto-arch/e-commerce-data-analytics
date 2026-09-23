-- =================================================================    
-- Caricamento gold.customer_segments    
-- =================================================================    
    
CREATE OR ALTER PROCEDURE gold.load_customer_segments    
AS    
BEGIN    
    BEGIN TRY    
    
        PRINT 'Caricamento gold.customer_segments';    
    
        TRUNCATE TABLE gold.customer_segments;    
    
        BULK INSERT gold.customer_segments    
        FROM 'C:\Users\Carlo Alberto\Downloads\E-Commerce\Viste_ML\Clustering\clustering_SQL\customer_segments_export.csv'    
        WITH (    
            FIRSTROW = 2,    
            FIELDTERMINATOR = ',',    
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