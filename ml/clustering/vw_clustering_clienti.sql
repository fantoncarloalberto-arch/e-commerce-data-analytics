-- VISTA: gold.vw_clustering_clienti  
-- Un cliente per riga, solo clienti con ALMENO 1 ordine.  
-- Data di riferimento fissa: 2025-12-31  
-- ============================================================  
CREATE OR ALTER VIEW gold.vw_clustering_clienti AS  
  
WITH AggregatiBase AS (  
    -- un cliente per riga, con tutti gli aggregati calcolabili  
    -- direttamente da fact_vendite (JOIN, non LEFT JOIN: i clienti  
    -- senza ordini vengono esclusi automaticamente qui)  
    SELECT  
        c.customer_key,  
        c.nome,  
        c.cognome,  
        c.data_nascita,  
        c.paese,  
        c.sesso,  
        c.data_registrazione,  
        DATEDIFF(DAY, MAX(f.data_ordine), '2025-12-31')           AS recency_giorni,  
        COUNT(DISTINCT f.order_id)                                AS frequency,  
        SUM(f.totale_riga)                                        AS monetary,  
        COUNT(DISTINCT dp.categoria)                              AS diversita_categorie,  
        AVG(CASE WHEN f.sconto > 0 THEN 1.0 ELSE 0.0 END)         AS quota_ordini_scontati  
    FROM gold.dim_clienti c  
    JOIN gold.fact_vendite f  ON c.customer_key = f.customer_key  
    JOIN gold.dim_prodotti dp ON f.product_key = dp.product_key  
    WHERE f.stato_ordine <> 'Annullato'  
    GROUP BY  
        c.customer_key, c.nome, c.cognome, c.data_nascita,  
        c.paese, c.sesso, c.data_registrazione  
),  
  
OrdiniAnnullati AS (  
    -- calcolato A PARTE: non influisce sugli aggregati sopra,  
    -- e' una feature AGGIUNTIVA, non una correzione di quelle  
    -- esistenti (Frequency/Monetary/AOV restano "puliti")  
    SELECT customer_key, COUNT(DISTINCT order_id) AS numero_ordini_annullati  
    FROM gold.fact_vendite  
    WHERE stato_ordine = 'Annullato'  
    GROUP BY customer_key  
),  
  
GapOrdini AS (  
    -- differenza in giorni tra un ordine e il precedente, per cliente  
    SELECT  
        customer_key,  
        DATEDIFF(  
            DAY,  
            LAG(data_ordine) OVER (PARTITION BY customer_key ORDER BY data_ordine),  
            data_ordine  
        ) AS gap_giorni  
    FROM (  
        SELECT DISTINCT customer_key, order_id, data_ordine  
        FROM gold.fact_vendite  
        WHERE stato_ordine <> 'Annullato'  
    ) t  
),  
  
Regolarita AS (  
    -- deviazione standard dei gap: richiede almeno 2 intervalli  
    -- (quindi almeno 3 ordini) - i clienti con meno ordini non  
    -- avranno una riga qui  
    SELECT customer_key, STDEV(gap_giorni) AS regolarita_acquisti  
    FROM GapOrdini  
    WHERE gap_giorni IS NOT NULL  
    GROUP BY customer_key  
),  
  
MediaRegolarita AS (  
    -- media globale, usata per imputare i clienti senza un valore  
    -- calcolabile - MOLTO piu' corretto di riempire con 0, che  
    -- avrebbe un significato preciso ("perfettamente regolare") e  
    -- rischierebbe di insegnare al modello una correlazione falsa  
    SELECT AVG(regolarita_acquisti) AS media_globale FROM Regolarita  
),  
  
MetodoPagamentoPrevalente AS (  
    -- la "moda": il metodo di pagamento piu' usato da ciascun cliente  
    SELECT customer_key, metodo_pagamento  
    FROM (  
        SELECT  
            customer_key,  
            metodo_pagamento,  
            ROW_NUMBER() OVER (  
                PARTITION BY customer_key  
                ORDER BY COUNT(*) DESC  
            ) AS rn  
        FROM gold.fact_vendite  
        WHERE stato_ordine <> 'Annullato'  
        GROUP BY customer_key, metodo_pagamento  
    ) t  
    WHERE rn = 1  
)  
  
SELECT  
    ab.customer_key,  
    CONCAT(ab.nome, ' ', ab.cognome)                          AS nome_completo,  
    DATEDIFF(YEAR, ab.data_nascita, '2025-12-31')  
        - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, ab.data_nascita, '2025-12-31'), ab.data_nascita) > '2025-12-31'  
               THEN 1 ELSE 0 END                              AS eta,  
    ab.paese,  
    ab.sesso,  
    DATEDIFF(DAY, ab.data_registrazione, '2025-12-31')        AS tenure_giorni,  
    ab.recency_giorni,  
    ab.frequency,  
    ROUND(ab.monetary, 2)                                     AS monetary,  
    ROUND(  
        ab.frequency / GREATEST(  
            DATEDIFF(DAY, ab.data_registrazione, '2025-12-31') / 30.0, 1.0  
        ), 2  
    )                                                          AS frequency_normalizzata,  
    ROUND(COALESCE(r.regolarita_acquisti, mr.media_globale), 2) AS regolarita_acquisti,  
    CASE WHEN r.regolarita_acquisti IS NULL THEN 1 ELSE 0 END  AS regolarita_non_calcolabile,  
    ROUND(ab.monetary / ab.frequency, 2)                      AS aov,  
    ab.diversita_categorie,  
    ROUND(ab.quota_ordini_scontati, 2)                        AS quota_ordini_scontati,  
    COALESCE(oa.numero_ordini_annullati, 0)                   AS numero_ordini_annullati,  
    mp.metodo_pagamento                                       AS metodo_pagamento_prevalente  
FROM AggregatiBase ab  
JOIN MetodoPagamentoPrevalente mp ON ab.customer_key = mp.customer_key  
LEFT JOIN Regolarita r             ON ab.customer_key = r.customer_key  
LEFT JOIN OrdiniAnnullati oa       ON ab.customer_key = oa.customer_key  
CROSS JOIN MediaRegolarita mr;  