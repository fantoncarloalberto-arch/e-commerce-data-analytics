-- ============================================================  
-- VISTA: gold.vw_churn_training  
-- Dataset di addestramento per il modello di churn - UNA SOLA  
-- data di taglio (2025-10-31): abbastanza indietro nel tempo da  
-- avere gia' noti i 65 giorni successivi (fino al 2025-12-31,  
-- fine dei dati storici). Una riga per cliente.  
--  
-- Feature: calcolate SOLO con dati fino al 2025-10-31 (il "passato").  
-- Target: calcolato guardando SOLO i 65 giorni dopo (il "futuro",  
-- ma gia' noto, perche' fa parte dei dati storici che possediamo).  
-- Soglia di churn: 65 giorni (95° percentile).  
-- ============================================================  
CREATE OR ALTER VIEW gold.vw_churn_training AS  
  
  
WITH Popolazione AS (  
    -- solo clienti gia' registrati prima della data di taglio  
    SELECT c.customer_key, c.nome, c.cognome, c.data_registrazione, c.data_nascita, c.paese, c.sesso  
    FROM gold.dim_clienti c  
    WHERE c.data_registrazione <= '20251031'  
),  
  
-- ordini validi (esclusi annullati) per il calcolo delle feature comportamentali  
OrdiniValidi AS (  
    SELECT customer_key, order_id, data_ordine, sconto, totale_riga, product_key  
    FROM gold.fact_vendite  
    WHERE stato_ordine <> 'Annullato'  
),  
  
Feature AS (  
    SELECT  
        p.customer_key,  
  
        DATEDIFF(YEAR, p.data_nascita, '20251031')  
            - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, p.data_nascita, '20251031'), p.data_nascita) > '20251031'  
                   THEN 1 ELSE 0 END AS eta,  
        p.paese,  
        p.sesso,  
  
        DATEDIFF(DAY, p.data_registrazione, '20251031') AS tenure_giorni,  
  
        DATEDIFF(DAY,  
            (SELECT MAX(ov.data_ordine) FROM OrdiniValidi ov  
             WHERE ov.customer_key = p.customer_key AND ov.data_ordine <= '20251031'),  
            '20251031'  
        ) AS recency_giorni,  
  
        (SELECT COUNT(DISTINCT ov.order_id) FROM OrdiniValidi ov  
         WHERE ov.customer_key = p.customer_key AND ov.data_ordine <= '20251031'  
        ) AS numero_ordini,  
  
        (SELECT SUM(ov.totale_riga) FROM OrdiniValidi ov  
         WHERE ov.customer_key = p.customer_key AND ov.data_ordine <= '20251031'  
        ) AS spesa_totale,  
  
        (SELECT COUNT(DISTINCT dp.categoria) FROM OrdiniValidi ov  
         JOIN gold.dim_prodotti dp ON dp.product_key = ov.product_key  
         WHERE ov.customer_key = p.customer_key AND ov.data_ordine <= '20251031'  
        ) AS diversita_categorie,  
  
        (SELECT AVG(CASE WHEN ov.sconto > 0 THEN 1.0 ELSE 0.0 END) FROM OrdiniValidi ov  
         WHERE ov.customer_key = p.customer_key AND ov.data_ordine <= '20251031'  
        ) AS quota_ordini_scontati,  
  
        (SELECT COUNT(DISTINCT v.order_id) FROM gold.fact_vendite v  
         WHERE v.customer_key = p.customer_key AND v.data_ordine <= '20251031'  
           AND v.stato_ordine = 'Annullato'  
        ) AS numero_ordini_annullati  
  
    FROM Popolazione p  
),  
  
Regolarita AS (  
    SELECT  
        p.customer_key,  
        STDEV(gaps.gap_giorni) AS regolarita_acquisti  
    FROM Popolazione p  
    CROSS APPLY (  
        SELECT DATEDIFF(  
            DAY,  
            LAG(ov.data_ordine) OVER (ORDER BY ov.data_ordine),  
            ov.data_ordine  
        ) AS gap_giorni  
        FROM OrdiniValidi ov  
        WHERE ov.customer_key = p.customer_key AND ov.data_ordine <= '20251031'  
    ) gaps  
    WHERE gaps.gap_giorni IS NOT NULL  
    GROUP BY p.customer_key  
),  
  
MediaRegolarita AS (  
    SELECT AVG(regolarita_acquisti) AS media_globale FROM Regolarita  
),  
  
MetodoPagamento AS (  
    SELECT customer_key, metodo_pagamento  
    FROM (  
        SELECT  
            ov.customer_key,  
            ov.order_id, -- solo per dare contesto, non usato  
            v.metodo_pagamento,  
            ROW_NUMBER() OVER (  
                PARTITION BY ov.customer_key  
                ORDER BY COUNT(*) DESC  
            ) AS rn  
        FROM OrdiniValidi ov  
        JOIN gold.fact_vendite v ON v.order_id = ov.order_id AND v.customer_key = ov.customer_key  
        WHERE ov.data_ordine <= '20251031'  
        GROUP BY ov.customer_key, ov.order_id, v.metodo_pagamento  
    ) t  
    WHERE rn = 1  
),  
  
-- il target: ha ricomprato entro 65gg DOPO la data di taglio?  
Target AS (  
    SELECT  
        p.customer_key,  
        MAX(CASE WHEN ov.data_ordine IS NOT NULL THEN 1 ELSE 0 END) AS ha_ricomprato  
    FROM Popolazione p  
    LEFT JOIN OrdiniValidi ov  
        ON ov.customer_key = p.customer_key  
       AND ov.data_ordine > '20251031'  
       AND ov.data_ordine <= DATEADD(DAY, 65, '20251031')  
    GROUP BY p.customer_key  
)  
  
SELECT  
    -- 1. Identificativi  
    f.customer_key,  
    CONCAT(p.nome, ' ', p.cognome)                               AS nome_completo,  
  
    -- 2. Anagrafici  
    f.eta,  
    f.paese,  
    f.sesso,  
  
    -- 3. Comportamentali  
    f.tenure_giorni,  
    COALESCE(f.recency_giorni, f.tenure_giorni)                  AS recency_giorni,  
    f.numero_ordini,  
    COALESCE(ROUND(f.spesa_totale, 2), 0)                        AS spesa_totale,  
    COALESCE(ROUND(f.spesa_totale / NULLIF(f.numero_ordini, 0), 2), 0) AS aov,  
    f.diversita_categorie,  
    COALESCE(ROUND(f.quota_ordini_scontati, 2), 0)               AS quota_ordini_scontati,  
    f.numero_ordini_annullati,  
    ROUND(COALESCE(r.regolarita_acquisti, mr.media_globale), 2)  AS regolarita_acquisti,  
    COALESCE(mp.metodo_pagamento, 'N/A')                         AS metodo_pagamento_prevalente,  
  
    -- 4. Qualita' del dato  
    CASE WHEN r.regolarita_acquisti IS NULL THEN 1 ELSE 0 END    AS regolarita_non_calcolabile,  
    CASE WHEN f.numero_ordini = 0 THEN 1 ELSE 0 END              AS mai_acquistato,  
  
    -- 5. Target  
    CASE WHEN t.ha_ricomprato = 1 THEN 'No' ELSE 'Si' END          AS target_churned  
  
FROM Feature f  
JOIN Popolazione p             ON f.customer_key = p.customer_key  
JOIN Target t                  ON f.customer_key = t.customer_key  
LEFT JOIN Regolarita r         ON f.customer_key = r.customer_key  
CROSS JOIN MediaRegolarita mr  
LEFT JOIN MetodoPagamento mp   ON f.customer_key = mp.customer_key;  