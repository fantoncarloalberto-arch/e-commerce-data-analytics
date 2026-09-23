# 🛒 E-commerce Data Analytics — Progetto End-to-End

Progetto didattico end-to-end di data analytics per un e-commerce: dai
dati grezzi fino a dashboard e modelli di Machine Learning, passando per
un'architettura dati completa su SQL Server.

**Dati sintetici** — nessun dato reale di clienti, prodotti o transazioni.

---

## 🗺️ Panoramica del progetto

Il progetto copre l'intera catena **ETL → Machine Learning → Business
Intelligence**:

1. **ETL** — architettura a medaglione (Bronze/Silver/Gold) su SQL Server,
   dal profiling dei dati grezzi fino a uno schema a stella pronto per BI
   e ML
2. **Machine Learning** — 4 filoni indipendenti in Python: segmentazione
   clienti, classificazione abbandono, forecasting della domanda, market
   basket analysis
3. **Business Intelligence** — dashboard Power BI a 6 pagine, con insight
   di business verificati numero per numero

---

## 🏗️ Architettura Bronze — Silver — Gold

```text
Dati grezzi (CSV)
      │
      ▼
┌─────────────┐   Specchio fedele della fonte
│   BRONZE    │   nessuna pulizia, nessuna perdita di dati
└─────────────┘
      │
      ▼
┌─────────────┐   Pulizia, tipizzazione, deduplica,
│   SILVER    │   unificazione delle identità (MDM)
└─────────────┘
      │
      ▼
┌─────────────┐   Schema a stella: dimensioni, fatti,
│    GOLD     │   chiavi surrogate, vincoli di integrità
└─────────────┘
      │
      ├──────────────► Viste per Machine Learning (Python)
      │
      └──────────────► Modello Power BI (dashboard)
```

Ogni livello ha un compito preciso e non si sovrappone al successivo:
Bronze non pulisce, Silver non costruisce il modello dimensionale, Gold
non reintroduce logica di pulizia. Dettagli completi, incluse tutte le
decisioni metodologiche, in [`sql/README.md`](sql/README.md).

---

## 🤖 Machine Learning — 4 filoni indipendenti

| Filone | Algoritmo | Risultato |
|---|---|---|
| [Clustering Clienti](ml/clustering/) | K-Means | ✅ Pienamente utilizzabile — 4 segmenti comportamentali distinti |
| [Classificazione Churn](ml/churn/) | Random Forest, XGBoost | ⚠️ Esito negativo, metodologia corretta — nessun segnale nei dati disponibili |
| [Forecasting Domanda](ml/forecasting/) | XGBoost | 🟡 Esito misto — 4 categorie su 6 affidabili, 2 con correzione manuale |
| [Market Basket Analysis](ml/market_basket/) | Apriori | ✅ Pienamente utilizzabile — 26 regole di associazione |

Il risultato negativo della classificazione churn non è un errore da
correggere: con soli 14 casi di abbandono su 558 clienti, nessun
algoritmo può inventare un segnale che non esiste nei dati. Una
metodologia rigorosa che conclude "questo compito non è risolvibile con
questi dati" è un'informazione valida quanto un modello che funziona —
dettagli in [`ml/churn/README.md`](ml/churn/README.md).

---

## 📊 Dashboard Power BI

6 pagine (Overview, Clienti, Prodotti, Campagne, Logistica, Magazzino),
costruite sul livello Gold e arricchite con gli output dei 4 modelli ML.
39 insight di business, ciascuno verificato con una query concreta, non
stimato a occhio — incluse le correzioni di un bug di modellazione
scoperto e risolto durante lo sviluppo. Dettagli completi in
[`dashboard/README.md`](dashboard/README.md).

---

## 📁 Struttura del repository

```text
├── datasets/          CSV grezzi di origine (dati sintetici)
├── sql/               Script SQL Server: Bronze, Silver, Gold
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── ml/                4 filoni di Machine Learning in Python
│   ├── clustering/
│   ├── churn/
│   ├── forecasting/
│   └── market_basket/
└── dashboard/         Dashboard Power BI + insight di business
```

Ogni cartella ha un proprio `README.md` che spiega obiettivo, dati,
decisioni metodologiche, risultati e limiti — pensato per essere letto in
autonomia, senza dover consultare le altre parti del progetto.

---

## 🛠️ Stack tecnico

- **Database**: SQL Server (T-SQL)
- **Machine Learning**: Python — pandas, numpy, matplotlib, seaborn, scikit-learn, XGBoost,
  mlxtend
- **Business Intelligence**: Power BI — Power Query, DAX

---

## 📄 Licenza

Distribuito con licenza MIT — vedi [`LICENSE`](LICENSE).
