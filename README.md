# 📂 Dataset Grezzi

I file CSV in questa cartella sono i dati sorgente originali, così come
arrivano prima di qualunque trasformazione — corrispondono uno a uno alle
tabelle del layer Bronze.

> ⚠️ **Dati sintetici, generati a scopo didattico.** Nessun nome, indirizzo,
> email o transazione qui contenuti appartiene a persone o aziende reali.
> Il dataset è stato costruito per esercitarsi su un caso di studio
> e-commerce realistico, non per rappresentare un'azienda esistente.

---

## 📁 File in questa cartella

| File | Corrisponde a | Contenuto |
|---|---|---|
| `campagne.csv` | `bronze.campagne` | Campagne marketing: nome, prodotti coinvolti, periodo, budget |
| `clienti.csv` | `bronze.clienti` | Anagrafica clienti |
| `prodotti.csv` | `bronze.prodotti` | Catalogo prodotti: nome, categoria, prezzo, costo |
| `vendite.csv` | `bronze.vendite` | Righe ordine: prodotto, quantità, prezzo, stato, spedizione |
| `giacenze.csv` | `bronze.giacenze` | Rilevazioni periodiche di stock per prodotto |

Ogni file viene caricato senza alcuna pulizia nel layer Bronze — la logica
di trasformazione e validazione vive interamente in
[`sql/silver/`](../sql/silver/) e [`sql/gold/`](../sql/gold/).