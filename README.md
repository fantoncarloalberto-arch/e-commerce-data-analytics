# 🏗️ ETL Bronze — Silver — Gold

Pipeline di trasformazione dati per l'e-commerce, organizzata in
architettura a medaglione su SQL Server: dai file grezzi di origine fino
al modello a stella pronto per BI e Machine Learning.

---

## 🎯 Obiettivo

Trasformare dati grezzi ed eterogenei in dati affidabili, tipizzati e
pronti per l'analisi, attraverso tre livelli progressivi — ciascuno con
un compito preciso e non sovrapponibile con gli altri: Bronze non pulisce,
Silver non costruisce il modello dimensionale, Gold non reintroduce logica
di pulizia.

---

## 🔍 Data Profiling — il passo prima di ogni DDL

Prima di scrivere qualunque struttura, i dati grezzi sono stati ispezionati
per scoprire cosa contenevano davvero, invece di assumere i tipi in base
al nome delle colonne: valori nulli per colonna, lunghezza massima reale
delle colonne testuali, formati data multipli convissuti nella stessa
colonna, separatori decimali misti (virgola/punto), zeri iniziali e spazi
nei codici, righe duplicate esatte.

**La regola pratica**: si tipizza in base a quello che il profiling
conferma, non per convenzione. NVARCHAR resta il default prudente solo
quando la verifica non è possibile o mostra ambiguità reale — un codice
sempre pulito e a lunghezza costante viene tipizzato correttamente già in
Bronze.

---

## 🥉 Bronze — Specchio Fedele della Fonte

Bronze ingerisce i dati sorgente senza alcuna trasformazione: nessuna
pulizia, nessuna perdita di dati. Il suo unico compito è essere una copia
grezza affidabile.

### Decisioni chiave

- **Ogni colonna il cui formato non è garantito al 100% resta NVARCHAR**,
  anche se sembra un numero o una data. Tipizzare in modo forte già qui
  significherebbe lasciare che il motore SQL "pulisca" (o corrompa) il
  dato in modo silenzioso durante il caricamento, fuori da ogni controllo
  — un codice prodotto con spazi extra, se tipizzato INT già in Bronze,
  perderebbe silenziosamente quegli spazi prima ancora di poterli
  ispezionare.

- **Pattern di caricamento standard**: per ogni tabella, TRUNCATE seguito
  da BULK INSERT, con gestione esplicita di terminatore di riga, codifica
  caratteri e virgolette nei campi CSV — dettagli che, se non specificati
  esplicitamente, causano errori di importazione o caratteri accentati
  corrotti.

---

## 🥈 Silver — Dati Puliti, Tipizzati, Deduplicati

Silver è dove avviene la vera pulizia: tipizzazione corretta,
normalizzazione del testo, gestione dei valori mancanti, eliminazione dei
duplicati, unificazione delle identità.

### Funzioni di pulizia riutilizzabili

| Funzione | Scopo |
|---|---|
| fn_TitleCase | Trim, collassa spazi doppi, prima lettera maiuscola per parola |
| fn_ParseDate | Converte testo con formati misti in un vero tipo DATE |
| fn_ParseFloat | Trim, sostituzione virgola/punto, conversione in FLOAT |

Costruire queste funzioni una sola volta, invece di ripetere la stessa
logica in decine di query, concentra eventuali correzioni future in un
unico punto. Un'eccezione dichiarata: su colonne con maiuscole interne
intenzionali (es. nomi di brand), fn_TitleCase forzerebbe minuscolo la
parte interna — per queste colonne si usa una funzione di solo trim, senza
toccare la capitalizzazione.

### Gestione dei valori NULL — tre strategie distinte

- **Recupero da un'altra colonna**, quando esiste un'informazione
  equivalente altrove nella stessa riga
- **Placeholder esplicito** ("N/A"), quando non esiste modo di recuperare
  il valore vero — preferibile a un NULL silenzioso, specialmente per
  strumenti di reporting che a volte lo nascondono senza avviso
- **NULL lasciato intenzionalmente**, quando il valore mancante è
  semanticamente corretto (es. data di consegna assente per un ordine non
  ancora consegnato) — non è un errore da correggere, è un fatto vero

### Deduplica — l'ordine delle operazioni conta

Il pattern standard usa una funzione di finestra con partizionamento sul
criterio di identità (es. nome+cognome+data di nascita per i clienti),
scegliendo un canonico con un ordine esplicito. **La deduplica avviene
sempre dopo aver pulito i dati**, non prima: due righe possono essere
duplicati logici ma apparire diverse nei dati grezzi (spazi extra su una
copia sì e sull'altra no) — cercare i duplicati sui dati grezzi non li
riconosce come identici.

### Master Data Management — tabelle di mappatura

Quando la stessa entità reale esiste due volte con codici diversi (un
prodotto duplicato nel catalogo, un cliente registrato due volte), si
costruisce una tabella "traduttore" con codice originale e codice
canonico — ogni codice, canonico compreso, ha una riga che punta a se
stesso, così ogni join successivo usa sempre la stessa logica. Per i dati
aggregati (es. giacenze), righe che confluiscono nello stesso canonico
vengono consolidate con una somma, non semplicemente rietichettate —
altrimenti si perderebbero informazioni reali.

### Esplosione delle campagne — da riga singola a relazione prodotto-campagna

I dati grezzi delle campagne arrivano con un solo campo che elenca tutti i
prodotti coinvolti in una campagna, separati da virgola, in un'unica
stringa di testo. Questo formato non è utilizzabile per un'analisi
relazionale: va scomposto in una riga per ogni combinazione
campagna-prodotto. La stringa viene quindi divisa nei suoi singoli
elementi, ciascuno abbinato al prodotto corrispondente tramite corrispondenza sul nome — con un secondo passaggio di corrispondenza
approssimata per i nomi che non trovano un abbinamento esatto (es. per
piccole differenze di scrittura tra il nome nella lista campagne e il nome
ufficiale del prodotto a catalogo).

---

## 🥇 Gold — Modello Pronto per BI e ML

Gold organizza i dati puliti in uno schema a stella: dimensioni (le
entità di analisi) e fatti (gli eventi e le misure), pronto per essere
consumato da strumenti di BI e pipeline di Machine Learning.

### Chiavi surrogate

Ogni dimensione ha una chiave tecnica generata internamente, distinta dal
codice naturale della fonte — resta stabile anche se il codice naturale
cambiasse in futuro, ed è sempre un intero, più efficiente nei join
rispetto a una stringa.

### Tabelle, non solo viste

Il Gold layer è materializzato in tabelle fisiche popolate da stored
procedure, non lasciato come semplici viste: le chiavi surrogate restano
stabili nel tempo invece di essere ricalcolate a ogni query, un requisito
importante per un layer che alimenta sia dashboard sia modelli di Machine
Learning che si aspettano riferimenti coerenti tra un'esecuzione e
l'altra.

### Vincoli di integrità referenziale

Le tabelle Gold hanno vincoli FOREIGN KEY reali tra fatti e dimensioni,
non solo una convenzione di nome — impediscono a livello di database
l'inserimento di una riga con una chiave surrogata inesistente. Questo
introduce una gestione più attenta nel ricaricamento: i vincoli vanno
rimossi temporaneamente prima di un TRUNCATE (che altrimenti fallirebbe
anche su una tabella vuota, per la sola presenza del vincolo), e
ricreati dopo aver ricaricato i dati.

---

## ✅ Validazione

Ogni livello viene controllato dopo il caricamento, con criteri via via
più stringenti man mano che si sale verso Gold:

| Controllo | Bronze | Silver | Gold |
|---|---|---|---|
| Conteggio righe coerente col livello precedente | — | Sì | Sì |
| Valori NULL solo dove attesi | No | Sì | Sì |
| Nessun duplicato residuo | No (atteso) | Sì | Sì |
| Integrità referenziale | N/A | Verifica manuale | Vincoli FK + verifica manuale |
| Round-trip delle chiavi | N/A | N/A | Sì |
| Coerenza di business | No | Sì | Sì (ripetuta per conferma) |

Il **controllo round-trip** (specifico di Gold) verifica che ogni chiave
surrogata punti esattamente al codice naturale corretto, non solo che
esista: si abbina la riga del fatto alla riga corrispondente in Silver
tramite una chiave naturale stabile, poi si confrontano i codici
recuperati tramite le chiavi surrogate con quelli originali — il risultato
atteso è sempre zero righe con codice sbagliato.

---

## ⚠️ Limiti e attenzioni note

- La deduplica e le tabelle di mappatura dipendono dalla qualità dei
  criteri di identità scelti (es. nome+cognome+data di nascita) — un
  criterio troppo permissivo unirebbe persone diverse, uno troppo rigido
  lascerebbe duplicati residui.
- I join tra Silver e Bronze durante il caricamento scartano
  silenziosamente le righe che non trovano corrispondenza in una tabella
  di mappatura — un comportamento voluto per garantire dati puliti in
  uscita, ma che richiede un controllo periodico dei conteggi per
  accorgersi se un volume anomalo di righe viene scartato.
- Il layer Gold, essendo materializzato in tabelle, richiede un passaggio
  esplicito di ricarica ogni volta che i dati sorgente cambiano — non si
  aggiorna automaticamente come farebbe una vista.

---

## 📁 File in questa cartella

| File | Contenuto |
|---|---|
| [`init_database.sql`](init_database.sql) | Crea il database e i tre schemi (bronze, silver, gold) |

### `bronze/`

| File | Contenuto |
|---|---|
| [`ddl_bronze_tables.sql`](bronze/ddl_bronze_tables.sql) | Definizione delle tabelle Bronze |
| [`sp_load_bronze.sql`](bronze/sp_load_bronze.sql) | Stored procedure di caricamento da file sorgente |

### `silver/`

| File | Contenuto |
|---|---|
| [`ddl_silver_tables.sql`](silver/ddl_silver_tables.sql) | Definizione delle tabelle Silver, incluse le tabelle di mappatura |
| [`fn_TitleCase.sql`](silver/fn_TitleCase.sql) | Funzione di normalizzazione testo |
| [`fn_ParseDate.sql`](silver/fn_ParseDate.sql) | Funzione di conversione data da formati misti |
| [`fn_ParseFloat.sql`](silver/fn_ParseFloat.sql) | Funzione di conversione numerica da formati misti |
| [`sp_load_silver.sql`](silver/sp_load_silver.sql) | Stored procedure di trasformazione Bronze → Silver |

### `gold/`

| File | Contenuto |
|---|---|
| [`ddl_gold_star_schema.sql`](gold/ddl_gold_star_schema.sql) | Definizione di dimensioni, fatti, tabelle ponte e vincoli FK |
| [`sp_load_gold.sql`](gold/sp_load_gold.sql) | Stored procedure di caricamento Silver → Gold |
