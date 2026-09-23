CREATE OR ALTER VIEW gold.vw_domanda_categoria_mensile AS  
  
SELECT  
    dp.categoria,  
    YEAR(f.data_ordine)                                   AS anno,  
    MONTH(f.data_ordine)                                  AS mese,  
    DATEFROMPARTS(YEAR(f.data_ordine), MONTH(f.data_ordine), 1) AS data_mese,  
    SUM(f.quantita)                                       AS quantita_totale_venduta  
FROM gold.fact_vendite f  
JOIN gold.dim_prodotti dp ON f.product_key = dp.product_key  
WHERE f.stato_ordine <> 'Annullato'  
GROUP BY  
    dp.categoria,  
    YEAR(f.data_ordine),  
    MONTH(f.data_ordine),  
    DATEFROMPARTS(YEAR(f.data_ordine), MONTH(f.data_ordine), 1)  