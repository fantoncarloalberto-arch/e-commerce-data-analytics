# 📉 Classificazione Churn — Previsione Abbandono Clienti

Modello di classificazione per prevedere quali clienti sono a rischio di
abbandono, a partire dalla vista `gold.vw_churn_training`.
**Risultato: esito negativo, ottenuto con metodologia corretta** — nessuno
dei due modelli testati ha trovato un segnale utile nei dati disponibili.
Un risultato negativo prodotto con un metodo rigoroso è un'informazione
valida, non un errore da correggere: conferma che, con questa definizione
di target e questo volume di dati, il compito non è risolvibile allo stato
attuale.

---

## 🎯 Obiettivo

Prevedere quali clienti smetteranno di acquistare, per permettere azioni
di retention mirate prima che l'abbandono avvenga, non dopo.

---

## 📥 Dati e variabili utilizzate

Vista di origine: `vw_churn_training.sql` — una riga per cliente, snapshot
al 31 ottobre 2025, 558 clienti. Le feature sono calcolate solo con dati
fino alla data di snapshot; il target guarda solo ai 65 giorni successivi
(un intervallo già noto nei dati storici, non una previsione nel vuoto).

| Variabile | Categoria | Significato |
|---|---|---|
| eta, paese, sesso | Anagrafico | Contesto demografico del cliente |
| tenure_giorni | Comportamentale | Da quanto tempo è cliente |
| recency_giorni | Comportamentale | Giorni dall'ultimo acquisto, misurati alla data di snapshot |
| numero_ordini | Comportamentale | Solidità della relazione |
| spesa_totale, aov | Comportamentale | Valore economico e impegno per acquisto |
| diversita_categorie | Comportamentale | Legame con il brand nel complesso |
| quota_ordini_scontati | Comportamentale | Fedeltà vera vs. condizionata al prezzo |
| numero_ordini_annullati | Comportamentale | Segnale predittivo di frizione |
| regolarita_acquisti | Comportamentale | Interruzione sospetta vs. normale per un cliente già irregolare |
| metodo_pagamento_prevalente | Comportamentale | Segnale indiretto di profilo |
| regolarita_non_calcolabile, mai_acquistato | Qualità del dato | Segnalano un valore stimato o un cliente senza storico |
| target_churned | Target | Ha ricomprato entro 65 giorni dopo lo snapshot? |

La soglia di 65 giorni è il 95° percentile della distribuzione reale dei
gap tra un acquisto e il successivo, calcolata su tutti i clienti con
almeno 2 ordini validi — il punto oltre il quale il comportamento diventa
statisticamente raro rispetto agli acquirenti attivi normali.

---

## 🔍 Cosa mostra l'analisi esplorativa

- **Il target è estremamente sbilanciato**: 544 clienti su 558 (97,5%) non
  abbandonano, contro 14 (2,5%) che lo fanno — uno sbilanciamento più
  estremo di quanto tipicamente si incontri in problemi simili.

- **Le variabili numeriche non separano i due gruppi.** Confrontando
  tenure, recency, numero ordini, spesa totale, regolarità d'acquisto e
  ordini annullati tra clienti churn e non-churn, le distribuzioni si
  sovrappongono quasi ovunque — nessuna feature mostra una separazione
  netta tra chi abbandonerà e chi resterà attivo.

- **La recency è, controintuitivamente, leggermente più bassa nei futuri
  churner.** Non è un'anomalia: la recency è misurata al momento dello
  snapshot, prima di sapere se il cliente tornerà nei 65 giorni successivi
  — riflette quindi il comportamento passato, non un segnale del
  comportamento futuro.

- **Le variabili categoriche non mostrano relazione con il target.**
  Zona geografica, sesso e metodo di pagamento prevalente mostrano una
  quota di churn pressoché identica in ogni sottogruppo — nessun segnale
  visibile prima ancora di addestrare un modello.

Questi segnali, presi insieme, anticipano già in fase esplorativa quello
che il modello confermerà: i clienti che abbandonano non si comportano, nei
dati disponibili, in modo riconoscibilmente diverso dagli altri.

---

## 🧭 Decisioni metodologiche chiave

- **Una sola data di taglio (31 ottobre 2025), non multiple.** Una data
  singola allinea il dataset al formato standard "una riga per cliente"
  usato comunemente nei problemi di churn, accettando il costo di un
  training set più piccolo (558 clienti) rispetto a un approccio con più
  date di taglio trimestrali, che avrebbe moltiplicato gli esempi
  disponibili ma reso il dataset meno standard da interpretare.

- **Nessuna standardizzazione né trasformazione logaritmica delle
  feature.** A differenza del clustering, qui si usano solo algoritmi ad
  albero (Random Forest, XGBoost), che decidono gli split con soglie e
  sono invarianti sia alla scala sia a trasformazioni monotone come il
  logaritmo — applicarle comunque non avrebbe cambiato il risultato.

- **Esclusione delle variabili categoriche (zona, sesso, metodo di
  pagamento) dalla matrice**, nonostante gli alberi le gestiscano
  normalmente bene anche se irrilevanti. Con soli 14 casi di churn, ogni
  colonna in più aumenta il rischio che pochi churner condividano per puro
  caso un valore categorico e il modello lo scambi per un pattern reale.

- **Nessuna rimozione delle feature numeriche correlate tra loro**
  (tenure, numero ordini, spesa totale, ordini annullati mostrano
  correlazioni 0,76-0,93). A differenza del clustering, la
  multicollinearità non danneggia la capacità predittiva di un modello ad
  alberi — al più diluisce l'importanza tra le colonne correlate.

- **Metrica di valutazione: F1 sulla classe di churn, non accuracy.** Con
  uno sbilanciamento del 97,5%/2,5%, un modello che rispondesse sempre "No
  abbandono" otterrebbe comunque un'accuracy alta senza aver imparato
  nulla — l'F1 sulla classe minoritaria è la metrica che riflette
  davvero se il modello riconosce i clienti a rischio.

- **Cross-validation a 3 fold, non 5.** Con solo 11 casi di churn nel
  training set, 5 fold lascerebbero 2-3 casi positivi per fold — troppo
  instabile. 3 fold è il compromesso minimo per avere almeno qualche caso
  positivo per fold, mantenendo la stratificazione.

- **Pesi di classe bilanciati** per entrambi gli algoritmi (circa 40 volte
  più peso alla classe di abbandono), per contrastare lo sbilanciamento
  estremo senza alterare il dataset stesso.

---

## ⚙️ Processo

1. Analisi esplorativa: distribuzione del target, confronto delle feature
   numeriche tra clienti churn e non-churn, quota di churn per categoria
2. Nessuna trasformazione di scala (non necessaria per modelli ad albero)
3. Esclusione delle variabili categoriche dalla matrice di training
4. Split train/test 80/20 stratificato, con verifica dei numeri assoluti
   oltre che delle proporzioni
5. Calcolo dei pesi di classe per Random Forest e XGBoost
6. Ricerca degli iperparametri con validazione incrociata a 3 fold,
   ottimizzando per F1 sulla classe di churn
7. Valutazione finale sul test set, con lettura mirata alla classe di
   abbandono, non all'accuracy complessiva
8. Confronto della feature importance tra i due algoritmi

---

## 📊 Risultato finale

| Modello | Accuracy | Recall (churn) | Precision (churn) | F1 (churn) |
|---|---|---|---|---|
| Random Forest | 96% | 0% | 0% | 0,00 |
| XGBoost | 95% | 0% | 0% | 0,00 |

Nessuno dei 3 clienti a rischio effettivamente presenti nel test set è
stato identificato correttamente da nessuno dei due modelli, nonostante il
peso elevato assegnato alla classe di abbandono in fase di addestramento.

I due algoritmi non concordano nemmeno su quale sia la variabile più
rilevante (rispettivamente tenure_giorni e numero_ordini_annullati) —
quando un pattern è reale e forte, algoritmi diversi tendono a convergere
sulle stesse variabili chiave; il disaccordo osservato è coerente con
l'assenza di un segnale solido nei dati.

**Causa identificata**: la combinazione tra una soglia di churn molto
selettiva (95° percentile) e un dataset di partenza di dimensioni contenute
(558 clienti) produce inevitabilmente un numero assoluto di esempi troppo
piccolo (14) per qualunque algoritmo di apprendimento, indipendentemente
dalla qualità della metodologia applicata.

---

## ⚠️ Limiti dichiarati

- Con soli 3 casi di churn nel test set, ogni singolo errore o successo del
  modello sposta le metriche di circa 33 punti percentuali — un limite
  strutturale del dataset, non dello split scelto.
- La soglia del 95° percentile non è una scelta sbagliata in sé — è
  corretta per l'obiettivo di identificare un abbandono statisticamente
  anomalo con alta confidenza, ma qui entra in conflitto con l'obiettivo
  di avere abbastanza esempi per addestrare un classificatore. Su un
  dataset di dimensioni aziendali reali (centinaia di migliaia di clienti)
  questo conflitto non si presenterebbe.
- Una soglia meno estrema (es. 90° o 75° percentile) aumenterebbe il
  numero di casi positivi disponibili, al costo di una definizione meno
  estrema di "abbandono" — un compromesso da valutare in un'iterazione
  futura con più dati storici disponibili.

---

## 📁 File in questa cartella

| File | Contenuto |
|---|---|
| [`churn.ipynb`](churn.ipynb) | Notebook completo: EDA, preparazione, addestramento, valutazione |
| [`vw_churn_training.sql`](vw_churn_training.sql) | Vista Gold di origine |
| [`input/`](input/) | CSV esportato dalla vista, letto dal notebook |
| [`ddl_customer_churn_status.sql`](ddl_customer_churn_status.sql) | Definizione tabella `gold.customer_churn_status` |
| [`load_customer_churn_status.sql`](load_customer_churn_status.sql) | Stored procedure di caricamento |