/*  
===============================================================================  
Stored Procedure: Load Gold Layer (Silver -> Gold)  
===============================================================================  
Usage Example:  
    EXEC gold.load_gold;  
===============================================================================  
*/  
  
CREATE OR ALTER PROCEDURE gold.load_gold AS  
BEGIN  
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;  
    BEGIN TRY  
        SET @batch_start_time = GETDATE();  
        PRINT '================================================';  
        PRINT 'Loading Gold Layer';  
        PRINT '================================================';  
  
        PRINT '------------------------------------------------';  
        PRINT 'Rimozione temporanea vincoli FK, per poter usare TRUNCATE';  
        PRINT '------------------------------------------------';  
        ALTER TABLE gold.fact_vendite DROP CONSTRAINT FK_fact_vendite_cliente;  
        ALTER TABLE gold.fact_vendite DROP CONSTRAINT FK_fact_vendite_prodotto;  
        ALTER TABLE gold.fact_vendite DROP CONSTRAINT FK_fact_vendite_corriere;  
        ALTER TABLE gold.fact_giacenze DROP CONSTRAINT FK_fact_giacenze_prodotto;  
        ALTER TABLE gold.fact_campagne_prodotti DROP CONSTRAINT FK_campagne_prodotti_campagna;  
        ALTER TABLE gold.fact_campagne_prodotti DROP CONSTRAINT FK_campagne_prodotti_prodotto;  
        PRINT '>> Vincoli rimossi';  
        PRINT '>> -------------';  
  
        PRINT '------------------------------------------------';  
        PRINT 'Truncating tutte le tabelle';  
        PRINT '------------------------------------------------';  
        TRUNCATE TABLE gold.fact_giacenze;  
        TRUNCATE TABLE gold.fact_vendite;  
        TRUNCATE TABLE gold.fact_campagne_prodotti;  
        TRUNCATE TABLE gold.dim_clienti;  
        TRUNCATE TABLE gold.dim_prodotti;  
        TRUNCATE TABLE gold.dim_corriere;  
        TRUNCATE TABLE gold.dim_campagne;  
        PRINT '>> Tutte le tabelle troncate';  
        PRINT '>> -------------';  
  
        PRINT '------------------------------------------------';  
        PRINT 'Loading Dimensioni';  
        PRINT '------------------------------------------------';  
  
        -- ============================================================  
        -- gold.dim_clienti  
        -- ============================================================  
        SET @start_time = GETDATE();  
        PRINT '>> Inserting Data Into: gold.dim_clienti';  
        INSERT INTO gold.dim_clienti (  
            customer_code, nome, cognome, email, data_nascita,  
            sesso, nazionalita, paese, citta, data_registrazione  
        )  
        SELECT  
            customer_code, nome, cognome, email, data_nascita,  
            sesso, nazionalita, paese, citta, data_registrazione  
        FROM silver.clienti;  
        SET @end_time = GETDATE();  
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
        PRINT '>> -------------';  
  
        -- ============================================================  
        -- gold.dim_prodotti  
        -- ============================================================  
        SET @start_time = GETDATE();  
        PRINT '>> Inserting Data Into: gold.dim_prodotti';  
        INSERT INTO gold.dim_prodotti (  
            product_code, nome_prodotto, categoria, sottocategoria, prezzo_listino, costo  
        )  
        SELECT  
            product_code, nome_prodotto, categoria, sottocategoria, prezzo_listino, costo  
        FROM silver.prodotti;  
        SET @end_time = GETDATE();  
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
        PRINT '>> -------------';  
  
        -- ============================================================  
        -- gold.dim_corriere  
        -- (nessuna riga 'N/A': carrier_key ora e' nullabile in  
        -- fact_vendite, gestiamo il caso "non spedito" con LEFT JOIN)  
        -- ============================================================  
        SET @start_time = GETDATE();  
        PRINT '>> Inserting Data Into: gold.dim_corriere';  
        INSERT INTO gold.dim_corriere (corriere)  
        SELECT corriere  
        FROM silver.corriere;  
        SET @end_time = GETDATE();  
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
        PRINT '>> -------------';  
  
        -- ============================================================  
        -- gold.dim_campagne  
        -- ============================================================  
        SET @start_time = GETDATE();  
        PRINT '>> Inserting Data Into: gold.dim_campagne';  
        INSERT INTO gold.dim_campagne (nome_campagna, data_inizio, data_fine, budget)  
        SELECT nome_campagna, data_inizio, data_fine, budget  
        FROM silver.campagne;  
        SET @end_time = GETDATE();  
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
        PRINT '>> -------------';  
  
  
        PRINT '------------------------------------------------';  
        PRINT 'Loading Tabella Ponte';  
        PRINT '------------------------------------------------';  
  
        -- ============================================================  
        -- gold.fact_campagne_prodotti  
        -- ============================================================  
        SET @start_time = GETDATE();  
        PRINT '>> Inserting Data Into: gold.fact_campagne_prodotti';  
        INSERT INTO gold.fact_campagne_prodotti (campaign_key, product_key)  
        SELECT DISTINCT  
            dc.campaign_key,  
            dp.product_key  
        FROM silver.campagne_prodotti cp  
        JOIN gold.dim_campagne dc ON cp.nome_campagna = dc.nome_campagna  
        JOIN gold.dim_prodotti dp ON cp.product_code = dp.product_code;  
        SET @end_time = GETDATE();  
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
        PRINT '>> -------------';  
  
  
        PRINT '------------------------------------------------';  
        PRINT 'Loading Fatti';  
        PRINT '------------------------------------------------';  
  
        -- ============================================================  
        -- gold.fact_vendite  
        -- LEFT JOIN su dim_corriere: quando v.corriere e' NULL (ordine  
        -- mai spedito), carrier_key risulta NULL - ammesso, dato che la  
        -- colonna e' stata resa nullabile  
        -- ============================================================  
        SET @start_time = GETDATE();  
        PRINT '>> Inserting Data Into: gold.fact_vendite';  
        INSERT INTO gold.fact_vendite (  
            order_id, order_line, customer_key, product_key, carrier_key,  
            data_ordine, data_spedizione, data_consegna,  
            quantita, prezzo_unitario, sconto, totale_riga, costo_spedizione,  
            metodo_pagamento, stato_ordine  
        )  
        SELECT  
            v.order_id,  
            v.order_line,  
            dc.customer_key,  
            dp.product_key,  
            dcorr.carrier_key,  
            v.order_date,  
            v.data_spedizione,  
            v.data_consegna,  
            v.quantity,  
            v.unit_price,  
            v.discount_pct,  
            v.totale_riga,  -- gia' netto sconto, calcolato in Silver: nessun ricalcolo qui  
            v.costo_spedizione,  
            v.payment_method,  
            v.order_status  
        FROM silver.vendite v  
        JOIN gold.dim_clienti dc          ON v.customer_code = dc.customer_code  
        JOIN gold.dim_prodotti dp         ON v.product_code = dp.product_code  
        LEFT JOIN gold.dim_corriere dcorr ON v.corriere = dcorr.corriere;  
        SET @end_time = GETDATE();  
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
        PRINT '>> -------------';  
  
        -- ============================================================  
        -- gold.fact_giacenze  
        -- ============================================================  
        SET @start_time = GETDATE();  
        PRINT '>> Inserting Data Into: gold.fact_giacenze';  
        INSERT INTO gold.fact_giacenze (product_key, data_rilevazione, quantita_disponibile)  
        SELECT  
            dp.product_key,  
            g.data_rilevazione,  
            g.quantita_disponibile  
        FROM silver.giacenze g  
        JOIN gold.dim_prodotti dp ON g.product_code = dp.product_code;  
        SET @end_time = GETDATE();  
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';  
        PRINT '>> -------------';  
  
  
        PRINT '------------------------------------------------';  
        PRINT 'Ripristino dei vincoli FK';  
        PRINT '------------------------------------------------';  
        ALTER TABLE gold.fact_vendite ADD CONSTRAINT FK_fact_vendite_cliente  
            FOREIGN KEY (customer_key) REFERENCES gold.dim_clienti(customer_key);  
        ALTER TABLE gold.fact_vendite ADD CONSTRAINT FK_fact_vendite_prodotto  
            FOREIGN KEY (product_key) REFERENCES gold.dim_prodotti(product_key);  
        ALTER TABLE gold.fact_vendite ADD CONSTRAINT FK_fact_vendite_corriere  
            FOREIGN KEY (carrier_key) REFERENCES gold.dim_corriere(carrier_key);  
        ALTER TABLE gold.fact_giacenze ADD CONSTRAINT FK_fact_giacenze_prodotto  
            FOREIGN KEY (product_key) REFERENCES gold.dim_prodotti(product_key);  
        ALTER TABLE gold.fact_campagne_prodotti ADD CONSTRAINT FK_campagne_prodotti_campagna  
            FOREIGN KEY (campaign_key) REFERENCES gold.dim_campagne(campaign_key);  
        ALTER TABLE gold.fact_campagne_prodotti ADD CONSTRAINT FK_campagne_prodotti_prodotto  
            FOREIGN KEY (product_key) REFERENCES gold.dim_prodotti(product_key);  
        PRINT '>> Vincoli ripristinati';  
        PRINT '>> -------------';  
  
  
        SET @batch_end_time = GETDATE();  
        PRINT '=========================================='  
        PRINT 'Loading Gold Layer is Completed';  
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';  
        PRINT '=========================================='  
  
    END TRY  
    BEGIN CATCH  
        PRINT '=========================================='  
        PRINT 'ERROR OCCURED DURING LOADING GOLD LAYER'  
        PRINT 'Error Message ' + ERROR_MESSAGE();  
        PRINT 'Error Number ' + CAST(ERROR_NUMBER() AS NVARCHAR);  
        PRINT 'Error State ' + CAST(ERROR_STATE() AS NVARCHAR);  
        PRINT '=========================================='  
    END CATCH  
END