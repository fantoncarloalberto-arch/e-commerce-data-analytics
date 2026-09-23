/*  
===============================================================================  
Stored Procedure: Load Bronze Layer (Source -> Bronze)  
===============================================================================  
Script Purpose:  
    This stored procedure loads data into the 'bronze' schema from external CSV files.   
    It performs the following actions:  
    - Truncates the bronze tables before loading data.  
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.  
  
Parameters:  
    None.   
   This stored procedure does not accept any parameters or return any values.  
  
Usage Example:  
    EXEC bronze.load_bronze;  
===============================================================================  
*/  
CREATE OR ALTER PROCEDURE bronze.load_bronze AS  
BEGIN  
 DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;   
 BEGIN TRY  
  SET @batch_start_time = GETDATE();  
  PRINT '================================================';  
  PRINT 'Loading Bronze Layer';  
  PRINT '================================================';  
  
  PRINT '------------------------------------------------';  
  PRINT 'Loading CSV File';  
  PRINT '------------------------------------------------';  
  
  SET @start_time = GETDATE();  
  PRINT '>> Truncating Table: bronze.prodotti';  
  TRUNCATE TABLE bronze.prodotti;  
  PRINT '>> Inserting Data Into: bronze.prodotti';  
  BULK INSERT bronze.prodotti  
  FROM 'C:\Users\Carlo Alberto\Downloads\E-Commerce\prodotti.csv'  
  WITH (  
   FIRSTROW = 2,  
   FIELDTERMINATOR = ',',  
   ROWTERMINATOR = '0x0a',  
   CODEPAGE = '65001',  
   FORMAT = 'CSV',  
   FIELDQUOTE = '"',  
   TABLOCK  
  );  
  SET @end_time = GETDATE();  
  PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
  PRINT '>> -------------';  
  
        SET @start_time = GETDATE();  
  PRINT '>> Truncating Table: bronze.clienti';  
  TRUNCATE TABLE bronze.clienti;  
  
  PRINT '>> Inserting Data Into: bronze.clienti';  
  BULK INSERT bronze.clienti  
  FROM 'C:\Users\Carlo Alberto\Downloads\E-Commerce\clienti.csv'  
  WITH (  
   FIRSTROW = 2,  
   FIELDTERMINATOR = ',',  
   ROWTERMINATOR = '0x0a',  
   CODEPAGE = '65001',  
   FORMAT = 'CSV',  
   FIELDQUOTE = '"',  
   TABLOCK  
  );  
  SET @end_time = GETDATE();  
  PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
  PRINT '>> -------------';  
  
  SET @start_time = GETDATE();  
  PRINT '>> Truncating Table: bronze.vendite';  
  TRUNCATE TABLE bronze.vendite;  
  PRINT '>> Inserting Data Into: bronze.vendite';  
  BULK INSERT bronze.vendite  
  FROM 'C:\Users\Carlo Alberto\Downloads\E-Commerce\vendite.csv'  
  WITH (  
   FIRSTROW = 2,  
   FIELDTERMINATOR = ',',  
   ROWTERMINATOR = '0x0a',  
   CODEPAGE = '65001',  
   FORMAT = 'CSV',  
   FIELDQUOTE = '"',  
   TABLOCK  
  );  
  SET @end_time = GETDATE();  
  PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
  PRINT '>> -------------';  
  
  SET @start_time = GETDATE();  
  PRINT '>> Truncating Table: bronze.giacenze';  
  TRUNCATE TABLE bronze.giacenze;  
  PRINT '>> Inserting Data Into: bronze.giacenze';  
  BULK INSERT bronze.giacenze  
  FROM 'C:\Users\Carlo Alberto\Downloads\E-Commerce\giacenze.csv'  
  WITH (  
   FIRSTROW = 2,  
   FIELDTERMINATOR = ',',  
   ROWTERMINATOR = '0x0a',  
   CODEPAGE = '65001',  
   FORMAT = 'CSV',  
   FIELDQUOTE = '"',  
   TABLOCK  
  );  
  SET @end_time = GETDATE();  
  PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
  PRINT '>> -------------';  
  
  SET @start_time = GETDATE();  
  PRINT '>> Truncating Table: bronze.campagne';  
  TRUNCATE TABLE bronze.campagne;  
  PRINT '>> Inserting Data Into: bronze.campagne';  
  BULK INSERT bronze.campagne  
  FROM 'C:\Users\Carlo Alberto\Downloads\E-Commerce\campagne.csv'  
  WITH (  
   FIRSTROW = 2,  
   FIELDTERMINATOR = ',',  
   ROWTERMINATOR = '0x0a',  
   CODEPAGE = '65001',  
   FORMAT = 'CSV',  
   FIELDQUOTE = '"',  
   TABLOCK  
  );  
  SET @end_time = GETDATE();  
  PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
  PRINT '>> -------------';  
  
  SET @batch_end_time = GETDATE();  
  PRINT '=========================================='  
  PRINT 'Loading Bronze Layer is Completed';  
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';  
  PRINT '=========================================='  
 END TRY  
 BEGIN CATCH  
  PRINT '=========================================='  
  PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'  
  PRINT 'Error Message' + ERROR_MESSAGE();  
  PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);  
  PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);  
  PRINT '=========================================='  
 END CATCH  
END