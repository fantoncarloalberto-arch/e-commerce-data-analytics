# 👥 Clustering Clienti — Segmentazione Comportamentale

Segmentazione di 587 clienti attivi in 4 gruppi comportamentali tramite
K-Means, a partire dalla vista `gold.vw_clustering_clienti`.
**Risultato: pienamente utilizzabile** — 4 segmenti distinti, comportamentali
non anagrafici, con implicazioni di business chiare per ciascuno.

---

## 🎯 Obiettivo

Individuare segmenti di clientela basati sul comportamento d'acquisto reale
(RFM, regolarità, sconti), non su categorie anagrafiche predefinite, per
orientare azioni di marketing e retention differenziate per gruppo.

---

## 📥 Dati e variabili utilizzate

Vista di origine: `vw_clustering_clienti.sql` — 587 clienti con almeno un
ordine valido, data di riferimento 2025-12-31.

| Variabile | Categoria | Significato |
|---|---|---|
| eta, paese, sesso | Anagrafico | Contesto demografico del cliente |
| tenure_giorni | Comportamentale base | Da quanto tempo è cliente |
| recency_giorni | RFM | Quanto tempo è passato dall'ultimo acquisto |
| frequency | RFM | Numero di ordini effettuati |
| monetary | RFM | Valore economico complessivo speso |
| frequency_normalizzata | RFM avanzato | Ritmo d'acquisto indipendente dall'anzianità |
| regolarita_acquisti | RFM avanzato | Quanto è costante il ritmo d'acquisto nel tempo |
| aov | RFM avanzato | Scontrino medio (pochi ordini grandi vs. molti piccoli) |
| diversita_categorie | Comportamento fine | Numero di categorie di prodotto diverse acquistate |
| quota_ordini_scontati | Comportamento fine | Sensibilità alle promozioni |
| numero_ordini_annullati | Comportamento fine | Frizione nel processo d'acquisto |
| metodo_pagamento_prevalente | Comportamento fine | Metodo di pagamento più usato |

Queste 12 variabili comportamentali (più le 3 anagrafiche) coprono sia il
"quanto" e "quando" acquista un cliente (RFM classico) sia il "come"
acquista (regolarità, diversità, sensibilità al prezzo) — la combinazione
permette di distinguere clienti che spendono cifre simili ma con
comportamenti d'acquisto molto diversi tra loro.

---

## 🔍 Cosa mostra l'analisi esplorativa

- **Un gruppo di 4 feature fortemente ridondanti tra loro** (tenure_giorni,
  frequency, monetary, numero_ordini_annullati, correlazioni fino a 0,92)
  — misurano tutte, in sostanza, da quanto tempo e quanto attivamente il
  cliente interagisce con il brand.

- **Distribuzioni fortemente asimmetriche** su frequency, monetary,
  recency e ordini annullati — pochi clienti con valori molto alti
  rispetto alla massa, motivo della trasformazione logaritmica applicata
  più avanti nella pipeline.

- **Concentrazione quasi totale su un valore** nella quota di ordini
  scontati — la stragrande maggioranza dei clienti non ha mai usato uno
  sconto.

- **La diversità di categorie acquistate è correlata con la tenure** —
  chi è cliente da più tempo ha avuto semplicemente più occasioni di
  comprare da tutte le categorie disponibili, un possibile effetto di
  "proxy" più che un vero tratto comportamentale distintivo.

Queste osservazioni hanno guidato direttamente le scelte di preparazione
successive: la trasformazione degli ordini annullati in un rapporto (non
un conteggio grezzo), il log-transform sulle variabili più asimmetriche, e
l'attenzione a non lasciare che una feature ridondante pesasse due volte
nel calcolo delle distanze.

---

## 🧭 Decisioni metodologiche chiave

- **Media della popolazione, non zero, per la regolarità d'acquisto quando
  non calcolabile.** Servono almeno 3 ordini per calcolare questo valore.
  Assegnare 0 significherebbe dichiarare "cliente perfettamente regolare"
  — un'affermazione specifica e probabilmente falsa. La media minimizza
  l'errore atteso ed è accompagnata da un flag esplicito che segnala il
  dato stimato, così il modello (e chi legge i risultati) sa distinguere
  un valore osservato da uno imputato.

- **Ordini annullati trattati come segnale a parte, non come correzione.**
  Il numero di annullamenti è una colonna autonoma, calcolata separatamente
  — non riduce Frequency o Monetary, che restano il valore reale generato
  dal cliente, ma aggiunge un segnale comportamentale distinto (un cliente
  che annulla spesso ha un profilo diverso da uno che non annulla mai).

- **Paese e metodo di pagamento esclusi dal calcolo dei cluster** (pur
  restando disponibili per descrivere i segmenti dopo). Includerli
  produceva cluster dominati quasi interamente da un singolo valore
  anagrafico o geografico — il risultato rifletteva un dato già noto nel
  database, non un vero pattern di comportamento d'acquisto. L'esclusione
  ha permesso ai cluster di emergere da differenze comportamentali reali.

- **Trasformazione dei valori estremi** su frequency, monetary, recency e
  quota di ordini annullati, per evitare che pochi clienti con valori
  molto alti dominassero il calcolo delle distanze tra i profili.

---

## ⚙️ Processo

1. Preparazione dei dati e correzione dei formati numerici
2. Analisi esplorativa: correlazioni tra feature, distribuzioni,
   individuazione di variabili ridondanti o fortemente asimmetriche
3. Trasformazione degli ordini annullati in un rapporto sulla frequency,
   per misurare il comportamento indipendentemente dall'anzianità del
   cliente
4. Riduzione dell'influenza dei valori estremi sulle variabili chiave
5. Esclusione di paese e metodo di pagamento dalla matrice di calcolo
6. Standardizzazione delle variabili (necessaria perché hanno scale molto
   diverse tra loro)
7. Determinazione del numero ottimale di cluster (4)
8. Applicazione del clustering e proiezione visiva a 2 dimensioni
9. Interpretazione dei profili tramite il confronto delle medie per
   cluster e delle variabili escluse

---

## 📊 Risultato finale

Quattro cluster comportamentali distinti, nessuno concentrato su un singolo
attributo anagrafico o geografico:

### Cluster 0 — Nuovi Clienti in Attivazione (34 clienti, 5,8%)
Tenure, frequency, monetary e diversità di categorie tutte ai minimi
contemporaneamente — clienti registrati da poco (54 giorni in media) senza
ancora uno storico d'acquisto consolidato. Tasso di cancellazione doppio
rispetto a tutti gli altri cluster (34%).

**Azioni suggerite**: percorso di onboarding attivo (email di benvenuto,
guide all'uso, assistenza proattiva); indagare le cause del tasso di
cancellazione elevato.

### Cluster 1 — Clienti Stabili a Ritmo Irregolare (207 clienti, 35,3%)
Tenure medio-alta ma la peggiore regolarità d'acquisto di tutta la
segmentazione — presenza prolungata nel tempo, senza una vera abitudine
d'acquisto consolidata.

**Azioni suggerite**: programmi pensati per costruire regolarità
(abbonamenti, promemoria periodici, incentivi a un ritmo di acquisto più
costante) piuttosto che azioni di semplice acquisizione.

### Cluster 2 — Clienti Fedeli di Alto Valore (225 clienti, 38,3%)
Il migliore su ogni singola dimensione comportamentale positiva: massima
frequenza, massima spesa, massima diversità di categorie acquistate,
migliore regolarità, minor tasso di cancellazione.

**Azioni suggerite**: programmi di retention premium (accesso anticipato a
nuovi prodotti, customer care dedicato) — è il segmento di maggior valore
economico e va protetto con priorità.

### Cluster 3 — Clienti Emergenti ad Alta Regolarità (121 clienti, 20,6%)
Tenure ancora contenuta, ma già la miglior regolarità d'acquisto in
assoluto e il tasso di cancellazione più basso — segnale di
un'esperienza d'acquisto molto positiva fin dalle prime fasi.

**Azioni suggerite**: percorso di fidelizzazione accelerata, monitorando
nel tempo se la traiettoria di crescita si conferma verso il profilo del
Cluster 2.

---

## ⚠️ Limiti dichiarati

- Le interpretazioni sul Cluster 0 (34 clienti) vanno lette con cautela:
  con un campione piccolo, differenze che sembrano nette possono rientrare
  nella normale variabilità statistica.
- Il possibile percorso "Cluster 0 → 3 → 1/2" è un'ipotesi plausibile
  basata sul confronto tra segmenti in un unico momento nel tempo, non
  un'osservazione reale dello stesso cliente nel tempo.

---

## 📁 File in questa cartella

| File | Contenuto |
|---|---|
| [`clustering.ipynb`](clustering.ipynb) | Notebook completo: analisi esplorativa, preparazione dati, clustering, interpretazione |
| [`vw_clustering_clienti.sql`](vw_clustering_clienti.sql) | Vista Gold di origine |
| [`input/`](input/) | CSV esportato dalla vista, letto dal notebook |
| [`ddl_customer_segments.sql`](ddl_customer_segments.sql) | Definizione tabella `gold.customer_segments` |
| [`load_customer_segments.sql`](load_customer_segments.sql) | Stored procedure di caricamento risultati |
| [`output/`](output/) | CSV dei risultati del clustering, ricaricato in Gold |