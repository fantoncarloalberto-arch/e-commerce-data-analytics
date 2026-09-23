# 🛒 Market Basket Analysis — Regole di Associazione tra Prodotti

Analisi delle combinazioni di prodotti acquistate insieme nello stesso
ordine, a partire dalla vista `gold.vw_mba_transazioni`, con l'algoritmo
Apriori.
**Risultato: pienamente utilizzabile** — 26 regole di associazione finali,
con un chiaro significato di business per ciascuna.

---

## 🎯 Obiettivo

Scoprire quali prodotti vengono acquistati insieme nello stesso ordine,
per individuare opportunità di bundle promozionali, cross-selling e
posizionamento prodotto.

---

## 📥 Dati e variabili utilizzate

Vista di origine: `vw_mba_transazioni.sql` — 7.716 ordini "Consegnato" con
almeno 2 prodotti distinti (il filtro sul numero minimo di prodotti è già
applicato dalla vista).

| Variabile | Significato |
|---|---|
| order_id | Identifica il carrello — chiave di raggruppamento per costruire le transazioni |
| nome_prodotto | Livello di dettaglio più fine disponibile |
| categoria | Livello di aggregazione più grossolano (6 valori) |
| sottocategoria | Livello di aggregazione intermedio (18 valori) — quello scelto per l'analisi finale |

---

## 🔍 Cosa mostra l'analisi esplorativa

- **Carrelli piccoli**: il 61% degli ordini contiene esattamente 2
  prodotti distinti, il 29% ne contiene 3, solo il 10% ne contiene 4 (il
  massimo osservato) — le combinazioni trovate sono quindi soprattutto
  coppie di prodotti, non gruppi più ampi.

- **Sei prodotti "star", il resto abbastanza omogeneo.** Su 128 prodotti,
  6-7 risultano molto più venduti degli altri (fino al 15,75% degli
  ordini), mentre i restanti ~120 si attestano su un livello di vendita
  più uniforme (1,0-1,6% ciascuno). Nessun prodotto è risultato troppo
  raro per essere analizzato con fiducia — il supporto individuale più
  basso osservato è circa l'1%.

Questa densità di dati (nessun problema di scarsità, a differenza del
churn) ha permesso di concentrare la vera decisione metodologica non
sull'algoritmo (Apriori è l'unica scelta naturale per questo compito), ma
sul livello di granularità a cui applicarlo.

---

## 🧭 Decisioni metodologiche chiave

- **Confronto quantitativo di 3 livelli di granularità, non una scelta a
  priori.** La vista fornisce 3 possibili livelli di aggregazione per
  ogni riga del carrello (prodotto, sottocategoria, categoria). Tutti e 3
  sono stati testati con lo stesso valore minimo di supporto, misurando
  quante combinazioni sopravvivono rispetto al totale teoricamente
  possibile:

  | Livello | Combinazioni trovate / possibili | Problema riscontrato |
  |---|---|---|
  | Prodotto (128 valori) | 11 coppie, 0 terzetti | Tutte le coppie coinvolgono solo i 6 prodotti più venduti |
  | Categoria (6 valori) | 15 coppie su 15 possibili (100%) | Troppo generico: quasi ogni combinazione supera la soglia, nessuna selettività reale |
  | Sottocategoria (18 valori) | 55 coppie su 153 possibili (36%) | Nessuno — selettivo e granulare al tempo stesso |

  Il livello prodotto rischia di restituire solo relazioni guidate dalla
  popolarità generale, non da un vero comportamento d'acquisto specifico.
  Il livello categoria è troppo grossolano: con solo 6 categorie e
  carrelli di 2-4 articoli, quasi ogni coppia risulta "frequente" per
  pura combinatoria. Il livello sottocategoria è risultato il compromesso
  corretto tra selettività e granularità.

- **Deduplica esplicita nella costruzione dei carrelli.** Se un ordine
  contiene 2 prodotti diversi della stessa sottocategoria, viene contata
  una sola volta — altrimenti l'ordine "conterrebbe" una sottocategoria
  ripetuta, senza senso per l'analisi di co-occorrenza tra sottocategorie
  distinte.

- **Soglia di supporto minimo all'1%, basata sui dati osservati, non un
  valore standard.** Il valore scelto corrisponde al supporto individuale
  più basso osservato tra i prodotti in fase esplorativa — una soglia che
  non esclude a priori nessun prodotto individualmente valido, restando
  comunque abbastanza selettiva da scartare le combinazioni più rare. In
  pratica: solo le coppie che compaiono in almeno l'1% di tutti gli
  ordini vengono prese in considerazione come "abbastanza frequenti" per
  l'analisi.

- **Filtro finale su lift e confidence, in quest'ordine.** Tra le coppie
  che superano la soglia di supporto, il lift esclude le relazioni
  casuali o negative (lift > 1); la confidence esclude le relazioni
  troppo deboli per essere azionabili in pratica (confidence > 20%).
  Filtrare prima sul lift è importante perché è una misura simmetrica
  della relazione, mentre la confidence dipende dalla direzione scelta.

---

## ⚙️ Processo

1. Analisi esplorativa: densità dei carrelli, distribuzione della
   popolarità dei prodotti
2. Test quantitativo dei 3 livelli di granularità con lo stesso supporto
   minimo, confronto delle combinazioni sopravvissute
3. Costruzione dei carrelli al livello scelto (sottocategoria), con
   deduplica esplicita per ordine
4. Applicazione dell'algoritmo Apriori con soglia di supporto minimo all'1%
5. Calcolo di confidence e lift sulle combinazioni trovate
6. Filtro finale su lift > 1 e confidence > 20%
7. Raggruppamento delle regole finali in cluster tematici per
   l'interpretazione di business

---

## 📊 Risultato finale

**26 regole di associazione finali** (su 55 coppie di sottocategorie
trovate, 36 con lift > 1, 26 anche con confidence > 20%), raggruppate in
cluster tematici coerenti con un comportamento d'acquisto plausibile:

| Cluster | Coppie principali | Lift |
|---|---|---|
| Sport specifico | Ciclismo ↔ Outdoor | 3,11 |
| Famiglia | Bambino↔Uomo, Donna↔Uomo, Donna↔Bambino | 2,72 - 3,00 |
| Casa/Arredamento | Cucina↔Arredo, Decorazione↔Arredo, Cucina↔Decorazione | 2,35 - 2,87 |
| Tecnologia | Smartphone & Accessori ↔ Informatica | 2,80 |
| Cura personale | Cura Persona ↔ Make-up | 2,69 |
| Tempo libero (più comune) | Libri ↔ Giochi & Hobby | 1,79 (support più alto: 6,6%) |

Nessuno dei pattern trovati risulta guidato dalla sola popolarità dei
prodotti (a differenza di quanto sarebbe successo scegliendo il livello
prodotto o categoria) — ogni coppia ha un senso di business plausibile.

### Come leggere le tre metriche, in parole semplici

- **Support**: su 100 ordini, quanti contengono entrambi i prodotti? Es.
  Libri e Giochi&Hobby hanno support 6,6% — su 100 ordini qualsiasi, 6-7
  contengono entrambe le sottocategorie.
- **Confidence**: tra chi ha comprato il primo prodotto, quanti hanno
  comprato anche il secondo? Es. il 25,6% di chi compra Ciclismo compra
  anche Outdoor nello stesso ordine. È una percentuale "a senso unico" —
  la stessa coppia letta al contrario (di chi compra Outdoor, quanti
  comprano anche Ciclismo) dà un numero diverso.
- **Lift**: quanto più spesso questa coppia si presenta rispetto a quello
  che ci si aspetterebbe per puro caso? Lift = 1 vuol dire nessuna
  relazione reale (pura coincidenza). Lift = 3,11 (il valore più alto
  trovato, Ciclismo-Outdoor) vuol dire che quella coppia compare 3 volte
  più spesso di quanto ci si aspetterebbe se i due acquisti fossero del
  tutto indipendenti tra loro.

### Cosa si può fare con queste regole, in pratica

- **Bundle promozionali** sulle coppie a lift più alto (Ciclismo+Outdoor,
  Cura Persona+Make-up): la relazione d'acquisto è già forte in modo
  naturale, un piccolo incentivo (sconto sul secondo prodotto, kit
  combinato) può spingere ulteriormente il valore medio dell'ordine.
- **Suggerimento automatico nel sito/e-commerce**: quando un cliente
  aggiunge al carrello un prodotto della sottocategoria A, mostrare un
  suggerimento per la sottocategoria B della stessa regola — utilizzabile
  per tutte e 26 le regole finali, non solo le più forti.
- **Kit famiglia o sconti quantità**: le coppie Uomo/Donna/Bambino
  suggeriscono che una parte dei clienti acquista per più membri della
  famiglia nello stesso ordine — un'offerta dedicata a questo tipo di
  carrello può aumentare lo scontrino medio.
- **Attenzione al volume, non solo alla forza della relazione**: la
  coppia Libri↔Giochi&Hobby ha un lift più moderato (1,79) ma è la più
  comune in assoluto (6,6% di tutti gli ordini) — un bundle su questa
  coppia raggiungerebbe più clienti, anche se la relazione tra i due
  prodotti è meno marcata delle altre.

---

## ⚠️ Limiti dichiarati

- La confidence non va interpretata come una probabilità predittiva per
  il singolo cliente futuro — è una statistica osservata sul passato.
- Il lift, per costruzione della formula, è sempre identico in entrambe le
  direzioni anche quando la confidence non lo è — un'asimmetria nella
  confidence non è un errore di calcolo.
- Le regole descrivono co-occorrenze osservate nello storico, non
  garantiscono che lo stesso pattern si mantenga se cambiano
  significativamente il catalogo prodotti o la composizione della
  clientela.

---

## 📁 File in questa cartella

| File | Contenuto |
|---|---|
| [`mba.ipynb`](mba.ipynb) | Notebook completo: EDA, confronto granularità, Apriori, regole finali |
| [`vw_mba_transazioni.sql`](vw_mba_transazioni.sql) | Vista Gold di origine |
| [`input/`](input/) | CSV esportato dalla vista, letto dal notebook |
| [`ddl_association_rules.sql`](ddl_association_rules.sql) | Definizione tabella `gold.association_rules` |
| [`load_association_rules.sql`](load_association_rules.sql) | Stored procedure di caricamento |
| [`output/`](output/) | CSV delle 26 regole finali, ricaricato in Gold |