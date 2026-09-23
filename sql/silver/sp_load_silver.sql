/*        
===============================================================================        
Stored Procedure: Load Silver Layer (Bronze -> Silver)        
===============================================================================        
Usage Example:        
    EXEC silver.load_silver;        
===============================================================================        
*/        
        
CREATE OR ALTER PROCEDURE silver.load_silver AS        
BEGIN        
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;        
    BEGIN TRY        
        SET @batch_start_time = GETDATE();        
        PRINT '================================================';        
        PRINT 'Loading Silver Layer';        
        PRINT '================================================';        
        
        PRINT '------------------------------------------------';        
        PRINT 'Loading Mapping Tables (dipendenza per tutto il resto)';        
        PRINT '------------------------------------------------';        
        
        -- ============================================================        
        -- silver.product_code_map        
        -- ============================================================        
        SET @start_time = GETDATE();        
        PRINT '>> Truncating Table: silver.product_code_map';        
        TRUNCATE TABLE silver.product_code_map;        
        PRINT '>> Inserting Data Into: silver.product_code_map';        
        INSERT INTO silver.product_code_map (product_code_originale, product_code_canonico)        
        SELECT g.product_code, canonico.product_code        
        FROM (        
            SELECT        
                product_code,        
                silver.fn_TitleCase(nome_prodotto) AS nome_pulito,        
                ROW_NUMBER() OVER (        
                    PARTITION BY silver.fn_TitleCase(nome_prodotto)        
                    ORDER BY product_code DESC        
                ) AS rn        
            FROM bronze.prodotti        
        ) g        
        JOIN (        
            SELECT        
                product_code,        
                silver.fn_TitleCase(nome_prodotto) AS nome_pulito,        
                ROW_NUMBER() OVER (        
                    PARTITION BY silver.fn_TitleCase(nome_prodotto)        
                    ORDER BY product_code DESC        
                ) AS rn        
            FROM bronze.prodotti        
        ) canonico        
            ON g.nome_pulito = canonico.nome_pulito AND canonico.rn = 1;        
        SET @end_time = GETDATE();        
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';        
        PRINT '>> -------------';        
        
        -- ============================================================        
        -- silver.customer_code_map        
        -- ============================================================        
        SET @start_time = GETDATE();        
        PRINT '>> Truncating Table: silver.customer_code_map';        
        TRUNCATE TABLE silver.customer_code_map;        
        PRINT '>> Inserting Data Into: silver.customer_code_map';        
        INSERT INTO silver.customer_code_map (customer_code_originale, customer_code_canonico)        
        SELECT g.customer_code, canonico.customer_code        
        FROM (        
            SELECT        
                customer_code,        
                silver.fn_TitleCase(nome) AS nome_pulito,        
                silver.fn_TitleCase(cognome) AS cognome_pulito,        
                silver.fn_ParseDate(data_nascita) AS data_nascita_pulita,        
                ROW_NUMBER() OVER (        
                    PARTITION BY        
                        silver.fn_TitleCase(nome), silver.fn_TitleCase(cognome), silver.fn_ParseDate(data_nascita)        
                    ORDER BY silver.fn_ParseDate(data_registrazione) DESC        
                ) AS rn        
            FROM bronze.clienti        
        ) g        
        JOIN (        
            SELECT        
              customer_code,        
                silver.fn_TitleCase(nome) AS nome_pulito,        
                silver.fn_TitleCase(cognome) AS cognome_pulito,        
                silver.fn_ParseDate(data_nascita) AS data_nascita_pulita,        
                ROW_NUMBER() OVER (        
                    PARTITION BY        
    silver.fn_TitleCase(nome), silver.fn_TitleCase(cognome), silver.fn_ParseDate(data_nascita)        
                    ORDER BY silver.fn_ParseDate(data_registrazione) DESC        
                ) AS rn        
            FROM bronze.clienti        
        ) canonico        
            ON g.nome_pulito = canonico.nome_pulito        
           AND g.cognome_pulito = canonico.cognome_pulito        
           AND g.data_nascita_pulita = canonico.data_nascita_pulita        
           AND canonico.rn = 1;        
        SET @end_time = GETDATE();        
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';        
        PRINT '>> -------------';        
        
        
        PRINT '------------------------------------------------';        
        PRINT 'Loading Anagrafiche (Prodotti, Clienti, Corriere)';        
        PRINT '------------------------------------------------';        
        
        -- ============================================================        
        -- silver.prodotti        
        -- ============================================================        
        SET @start_time = GETDATE();        
        PRINT '>> Truncating Table: silver.prodotti';        
        TRUNCATE TABLE silver.prodotti;        
        PRINT '>> Inserting Data Into: silver.prodotti';        
        INSERT INTO silver.prodotti (product_code, nome_prodotto, categoria, sottocategoria, prezzo_listino, costo)        
        SELECT        
            p.product_code,        
            silver.fn_TitleCase(p.nome_prodotto),        
            silver.fn_TitleCase(p.categoria),        
            silver.fn_TitleCase(p.sottocategoria),        
            silver.fn_ParseFloat(p.prezzo_listino),        
            silver.fn_ParseFloat(p.costo)        
        FROM bronze.prodotti p        
        JOIN silver.product_code_map m ON p.product_code = m.product_code_originale        
        WHERE m.product_code_originale = m.product_code_canonico;        
        SET @end_time = GETDATE();        
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';        
        PRINT '>> -------------';        
        
        -- ============================================================        
        -- silver.clienti        
        -- ============================================================        
        SET @start_time = GETDATE();        
        PRINT '>> Truncating Table: silver.clienti';        
        TRUNCATE TABLE silver.clienti;        
        PRINT '>> Inserting Data Into: silver.clienti';        
        INSERT INTO silver.clienti (customer_code, nome, cognome, email, data_nascita, sesso, nazionalita, citta, paese, data_registrazione)        
        SELECT        
            UPPER(TRIM(c.customer_code)),        
            silver.fn_TitleCase(c.nome),        
            silver.fn_TitleCase(c.cognome),        
            LOWER(TRIM(c.email)),        
            silver.fn_ParseDate(c.data_nascita),        
            CASE        
                WHEN UPPER(TRIM(c.sesso)) IN ('M', 'MASCHIO') THEN 'Maschio'        
                WHEN UPPER(TRIM(c.sesso)) IN ('F', 'FEMMINA') THEN 'Femmina'        
                ELSE 'N/A'        
            END,        
            COALESCE(silver.fn_TitleCase(c.nazionalita), silver.fn_TitleCase(c.paese)),        
            COALESCE(silver.fn_TitleCase(c.citta), 'N/A'),        
            silver.fn_TitleCase(c.paese),        
            silver.fn_ParseDate(c.data_registrazione)        
        FROM bronze.clienti c        
        JOIN silver.customer_code_map m ON c.customer_code = m.customer_code_originale        
        WHERE m.customer_code_originale = m.customer_code_canonico;        
        SET @end_time = GETDATE();        
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';        
        PRINT '>> -------------';        
        
        -- ============================================================        
        -- silver.corriere        
        -- ============================================================        
        SET @start_time = GETDATE();        
        PRINT '>> Truncating Table: silver.corriere';        
        TRUNCATE TABLE silver.corriere;        
        PRINT '>> Inserting Data Into: silver.corriere';        
        INSERT INTO silver.corriere (corriere)        
        SELECT DISTINCT TRIM(corriere)        
        FROM bronze.vendite        
        WHERE corriere IS NOT NULL;        
        SET @end_time = GETDATE();        
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';        
        PRINT '>> -------------';        
        
        
        PRINT '------------------------------------------------';        
        PRINT 'Loading Vendite';        
        PRINT '------------------------------------------------';        
        
        -- ============================================================        
        -- silver.vendite        
        -- ============================================================          
        SET @start_time = GETDATE();      
        PRINT '>> Truncating Table: silver.vendite';      
        TRUNCATE TABLE silver.vendite;      
        PRINT '>> Inserting Data Into: silver.vendite';      
      
        ;WITH VenditeTrasformate AS (      
            SELECT      
                TRIM(UPPER(v.order_id))                AS order_id,      
                v.order_line                            AS order_line,      
                silver.fn_ParseDate(v.order_date)       AS order_date,      
                cmap.customer_code_canonico             AS customer_code,      
                pmap.product_code_canonico              AS product_code,      
                CASE      
                    WHEN v.quantity > 0 THEN v.quantity      
                    WHEN v.quantity < 0 THEN ABS(v.quantity)      
                    ELSE ROUND(silver.fn_ParseFloat(v.totale_riga) / NULLIF(silver.fn_ParseFloat(v.unit_price), 0), 0)      
                END                                      AS quantity,      
                silver.fn_ParseFloat(v.unit_price)       AS unit_price,      
                CAST(COALESCE(v.discount_pct, 0) AS INT) AS discount_pct,      
                CASE  
                    WHEN UPPER(TRIM(v.payment_method)) = 'PAYPAL' THEN 'PayPal'  
                    WHEN UPPER(TRIM(v.payment_method)) = 'CARTA DI CREDITO' THEN 'Carta di credito'  
                    WHEN UPPER(TRIM(v.payment_method)) = 'BONIFICO BANCARIO' THEN 'Bonifico bancario'  
                    WHEN UPPER(TRIM(v.payment_method)) = 'CONTRASSEGNO' THEN 'Contrassegno'  
                    ELSE 'N/A'  
                    END                                  AS payment_method,      
                CASE      
                    WHEN UPPER(TRIM(v.order_status)) = 'CONSEGNATO' THEN 'Consegnato'      
                    WHEN UPPER(TRIM(v.order_status)) = 'SPEDITO' THEN 'Spedito'      
                    WHEN UPPER(TRIM(v.order_status)) = 'ANNULLATO' THEN 'Annullato'      
                    WHEN UPPER(TRIM(v.order_status)) = 'IN LAVORAZIONE' THEN 'In lavorazione'      
                    ELSE 'N/A'      
                END                                      AS order_status,      
                silver.fn_ParseDate(v.data_spedizione)   AS data_spedizione,      
                silver.fn_ParseDate(v.data_consegna)     AS data_consegna,      
                TRIM(v.corriere)                         AS corriere,      
                silver.fn_ParseFloat(v.costo_spedizione) AS costo_spedizione      
            FROM bronze.vendite v      
            JOIN silver.customer_code_map cmap ON v.customer_code = cmap.customer_code_originale      
            JOIN silver.product_code_map pmap ON TRIM(v.product_code) = pmap.product_code_originale      
        ),      
        VenditeConTotale AS (           
            SELECT *,      
                ROUND(quantity * unit_price * (1 - discount_pct / 100.0), 2) AS totale_riga      
            FROM VenditeTrasformate      
        ),      
        VenditeDeduplicate AS (      
            SELECT *,      
                ROW_NUMBER() OVER (      
                    PARTITION BY      
                        order_id, order_line, order_date, customer_code, product_code,      
                        quantity, unit_price, discount_pct, payment_method, order_status,      
                        data_spedizione, data_consegna, corriere, costo_spedizione, totale_riga      
                    ORDER BY (SELECT NULL)      
                ) AS rn      
            FROM VenditeConTotale      
        )      
        INSERT INTO silver.vendite (      
            order_id, order_line, order_date, customer_code, product_code,      
            quantity, unit_price, discount_pct, payment_method, order_status,      
            data_spedizione, data_consegna, corriere, costo_spedizione, totale_riga      
        )      
        SELECT      
            order_id, order_line, order_date, customer_code, product_code,      
            quantity, unit_price, discount_pct, payment_method, order_status,      
            data_spedizione, data_consegna, corriere, costo_spedizione, totale_riga      
        FROM VenditeDeduplicate      
        WHERE rn = 1;      
      
        SET @end_time = GETDATE();      
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';      
        PRINT '>> -------------';      
        
        
        PRINT '------------------------------------------------';        
        PRINT 'Loading Giacenze';        
        PRINT '------------------------------------------------';        
        
        -- ============================================================        
        -- silver.giacenze        
        -- ============================================================        
        SET @start_time = GETDATE();        
        PRINT '>> Truncating Table: silver.giacenze';        
        TRUNCATE TABLE silver.giacenze;        
        PRINT '>> Inserting Data Into: silver.giacenze';        
        INSERT INTO silver.giacenze (product_code, data_rilevazione, quantita_disponibile)        
        SELECT        
            pmap.product_code_canonico,        
            g.data_rilevazione,        
            SUM(g.quantita_disponibile)        
        FROM bronze.giacenze g        
        JOIN silver.product_code_map pmap ON g.product_code = pmap.product_code_originale        
        GROUP BY pmap.product_code_canonico, g.data_rilevazione;        
        SET @end_time = GETDATE();        
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';        
        PRINT '>> -------------';        
        
        
        PRINT '------------------------------------------------';        
        PRINT 'Loading Campagne';        
        PRINT '------------------------------------------------';        
        
        -- ============================================================        
        -- silver.campagne        
        -- ============================================================        
        SET @start_time = GETDATE();        
        PRINT '>> Truncating Table: silver.campagne';        
        TRUNCATE TABLE silver.campagne;        
        PRINT '>> Inserting Data Into: silver.campagne';        
        INSERT INTO silver.campagne (nome_campagna, data_inizio, data_fine, budget)        
        SELECT        
            TRIM(nome_campagna),        
            silver.fn_ParseDate(data_inizio),        
            silver.fn_ParseDate(data_fine),        
            budget        
        FROM bronze.campagne;        
        SET @end_time = GETDATE();        
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';        
        PRINT '>> -------------';        
        
        -- ============================================================        
        -- silver.campagne_prodotti        
        -- ============================================================        
        SET @start_time = GETDATE();        
        PRINT '>> Truncating Table: silver.campagne_prodotti';        
        TRUNCATE TABLE silver.campagne_prodotti;        
        PRINT '>> Inserting Data Into: silver.campagne_prodotti';        
        
        ;WITH Esploso AS (        
            SELECT        
                c.nome_campagna,        
                TRIM(s.value) AS nome_prodotto_grezzo        
            FROM bronze.campagne c        
            CROSS APPLY STRING_SPLIT(c.prodotti_coinvolti, ',') s        
            WHERE TRIM(s.value) <> ''        
        ),        
        MatchEsatto AS (        
            SELECT        
                e.nome_campagna,        
                e.nome_prodotto_grezzo,        
                p.product_code        
            FROM Esploso e        
            JOIN bronze.prodotti p        
                ON silver.fn_TitleCase(e.nome_prodotto_grezzo) = silver.fn_TitleCase(p.nome_prodotto)        
        ),        
        MatchFuzzy AS (        
            SELECT        
                e.nome_campagna,        
                e.nome_prodotto_grezzo,        
                best.product_code        
            FROM Esploso e        
            CROSS APPLY (        
                SELECT TOP 1 p.product_code        
                FROM bronze.prodotti p        
                WHERE DIFFERENCE(silver.fn_TitleCase(e.nome_prodotto_grezzo), silver.fn_TitleCase(p.nome_prodotto)) = 4        
                ORDER BY p.product_code        
            ) best        
            WHERE NOT EXISTS (        
                SELECT 1 FROM MatchEsatto me        
                WHERE me.nome_campagna = e.nome_campagna AND me.nome_prodotto_grezzo = e.nome_prodotto_grezzo        
            )        
        )        
        INSERT INTO silver.campagne_prodotti (nome_campagna, product_code)        
        SELECT DISTINCT        
            TRIM(risultato.nome_campagna),        
            pmap.product_code_canonico        
        FROM (        
            SELECT nome_campagna, product_code FROM MatchEsatto        
            UNION ALL        
            SELECT nome_campagna, product_code FROM MatchFuzzy        
        ) risultato        
        JOIN silver.product_code_map pmap ON risultato.product_code = pmap.product_code_originale;        
        
        SET @end_time = GETDATE();        
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';        
        PRINT '>> -------------';        
        
        
        SET @batch_end_time = GETDATE();        
        PRINT '=========================================='        
        PRINT 'Loading Silver Layer is Completed';        
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';        
        PRINT '=========================================='        
        
    END TRY        
    BEGIN CATCH        
        PRINT '=========================================='        
        PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'        
        PRINT 'Error Message ' + ERROR_MESSAGE();        
        PRINT 'Error Number ' + CAST(ERROR_NUMBER() AS NVARCHAR);        
        PRINT 'Error State ' + CAST(ERROR_STATE() AS NVARCHAR);        
        PRINT '=========================================='        
    END CATCH        
END