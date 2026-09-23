-- =================================================================  
-- Caricamento gold.customer_churn_status  
-- =================================================================  
  
CREATE OR ALTER PROCEDURE gold.load_customer_churn_status  
AS  
BEGIN  
    BEGIN TRY  
  
        PRINT 'Caricamento gold.customer_churn_status';  
  
        TRUNCATE TABLE gold.customer_churn_status;  
  
        INSERT INTO gold.customer_churn_status (customer_key, target_churned)  
        SELECT customer_key, target_churned  
        FROM gold.vw_churn_training;  
  
    END TRY  
  
    BEGIN CATCH  
        PRINT 'ERRORE durante il caricamento: ' + ERROR_MESSAGE();  
    END CATCH  
END  