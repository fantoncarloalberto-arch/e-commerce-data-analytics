CREATE OR ALTER VIEW gold.vw_mba_transazioni AS  
WITH Base AS (  
    SELECT  
        f.order_id,  
        dp.nome_prodotto,  
        dp.categoria,  
        dp.sottocategoria  
    FROM gold.fact_vendite f  
    JOIN gold.dim_prodotti dp ON f.product_key = dp.product_key  
    WHERE f.stato_ordine = 'Consegnato'  
),  
ConteggioDistinti AS (  
    SELECT order_id, COUNT(DISTINCT nome_prodotto) AS numero_prodotti_distinti  
    FROM Base  
    GROUP BY order_id  
)  
SELECT DISTINCT  
    b.order_id,  
    b.nome_prodotto,  
    b.categoria,  
    b.sottocategoria  
FROM Base b  
JOIN ConteggioDistinti cd ON b.order_id = cd.order_id  
WHERE cd.numero_prodotti_distinti >= 2;  