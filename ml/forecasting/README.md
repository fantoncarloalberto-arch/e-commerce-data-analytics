# 📈 Forecasting Domanda — Previsione Vendite per Categoria

Previsione della domanda mensile (quantità venduta) per le 6 categorie di
prodotto, a partire dalla vista `gold.vw_domanda_categoria_mensile`, con
XGBoost per il primo trimestre 2026.
**Risultato: misto** — 4 categorie su 6 con previsioni coerenti e
affidabili, 2 con un limite noto e una correzione manuale applicata.

---

## 🎯 Obiettivo

Prevedere la domanda mensile per categoria nei mesi successivi, come base
per decisioni di riassortimento e pianificazione del magazzino.

---

## 📥 Dati e variabili utilizzate

Vista di origine: `vw_domanda_categoria_mensile.sql` — serie storica
mensile di 36 mesi (gennaio 2023 - dicembre 2025), 6 categorie, nessun
buco nella serie.

| Variabile | Categoria | Significato |
|---|---|---|
| categoria | Identificativo | Livello di aggregazione scelto per la stabilità della serie |
| anno, mese, trimestre | Temporale | Componenti del periodo, usate come feature |
| data_mese | Temporale | Data del primo giorno del mese, per ordinamento e grafici |
| quantita_totale_venduta | Target | La misura da prevedere |
| lag_1 | Feature derivata | Domanda del mese precedente |
| lag_12 | Feature derivata | Domanda dello stesso mese, un anno prima — cattura la stagionalità |
| rolling_mean_3 | Feature derivata | Media mobile dei 3 mesi precedenti — cattura il trend recente |

Le feature derivate (lag e rolling) sono calcolate sempre raggruppando per
categoria, mai sull'intero set di dati misto — altrimenti il valore di
dicembre di una categoria verrebbe usato come "mese precedente" di gennaio
di un'altra.

---

## 🔍 Cosa mostra l'analisi esplorativa

- **Nessun buco nella serie mensile**, per nessuna delle 6 categorie —
  36 mesi continui da gennaio 2023 a dicembre 2025.

- **Trend di crescita chiaro in tutte le categorie**, con valori
  sistematicamente più alti a fine 2025 rispetto a inizio 2023.

- **Stagionalità annuale fortissima, con picco a novembre** (Black
  Friday/preparazione Natale), che cresce di anno in anno — circa 270 nel
  2023, 350 nel 2024, 525 nel 2025 per la categoria Sport & Tempo Libero,
  a titolo di esempio.

- **Due gruppi di categorie per scala, stesso pattern temporale.**
  Abbigliamento e Casa & Arredamento hanno un volume di vendite base circa
  la metà delle altre quattro categorie, ma condividono lo stesso trend e
  la stessa stagionalità — cambia solo l'ampiezza, non la forma della
  curva.

Queste osservazioni hanno guidato la scelta di un modello unico con la
categoria come feature (il pattern temporale è condiviso), e la scelta
dell'orizzonte di previsione a 3 mesi in bassa stagione (per evitare di
dover superare il picco di novembre, il punto più critico della serie).

---

## 🧭 Decisioni metodologiche chiave

- **Modello unico con la categoria come feature, non un modello per
  categoria.** Con solo 36 mesi di storico per categoria (24 dopo la
  perdita dei primi 12 mesi necessari per calcolare lag_12), un modello
  per categoria avrebbe troppo pochi esempi per essere stabile. Un modello
  unico sfrutta tutte le 144 righe disponibili per imparare il pattern
  temporale condiviso tra le categorie.

- **Solo 3 feature derivate, non 6.** Un primo tentativo con lag_1, lag_2,
  lag_3, lag_12, rolling_mean_3 e rolling_std_3 ha prodotto overfitting
  severo (R² sul training 0,999, sul test 0,293). La versione finale usa
  solo lag_1, lag_12 e rolling_mean_3 — lag_2/lag_3 erano ridondanti con
  lag_1, rolling_std_3 era calcolata su soli 3 punti ed era probabile
  fonte di rumore più che di segnale.

- **Split cronologico con ampiezza uguale all'orizzonte di previsione
  reale.** Soglia di split al 1° ottobre 2025: il test set (ottobre-
  dicembre 2025, 3 mesi) ha la stessa ampiezza della previsione finale
  (gennaio-marzo 2026), così la valutazione riflette la difficoltà reale
  del compito.

- **Orizzonte di previsione a 3 mesi, non 12.** Un orizzonte più lungo
  accumula più errore nel ciclo di previsione ricorsivo. In questo caso
  specifico, un orizzonte di 3 mesi ha anche il vantaggio di restare in
  bassa stagione (gennaio-marzo), evitando di dover prevedere un valore
  superiore al massimo storico osservato — cosa che un orizzonte di 12
  mesi non potrebbe evitare, dovendo coprire anche il picco di novembre.

- **Regolarizzazione esplicita del modello** (profondità degli alberi
  ridotta, penalità sui pesi), necessaria per contenere l'overfitting
  osservato nel primo tentativo, dato il training set relativamente
  piccolo (126 righe).

---

## ⚙️ Processo

1. Analisi esplorativa della serie storica: continuità, trend, stagionalità, gruppi di scala
2. Costruzione delle feature derivate (lag, rolling mean), raggruppate per categoria
3. Split cronologico train/test con ampiezza pari all'orizzonte di previsione
4. Addestramento con regolarizzazione esplicita per contenere l'overfitting
5. Valutazione su MAE/RMSE/R², complessiva e separatamente escludendo novembre
6. Riaddestramento del modello su tutto lo storico disponibile per la previsione finale
7. Confronto di ogni categoria prevista con lo stesso periodo dell'anno precedente, per individuare crescite implausibili
8. Correzione manuale delle categorie con crescita implausibile

---

## 📊 Risultato finale

### Il limite di estrapolazione degli alberi decisionali

Un albero di regressione prevede sempre restituendo una media di valori
già visti in allenamento — per costruzione, non può mai prevedere un
valore superiore al massimo storico osservato. Con una domanda in crescita
sostenuta, ogni nuovo picco di novembre supera il precedente: un modello
non può prevedere correttamente un valore che non ha mai visto.

Nella valutazione, questo limite si è manifestato chiaramente: il solo
mese di novembre ha spiegato il 69% dell'errore complessivo, con
sottostima sistematica nelle 4 categorie a volume più alto. Escludendo
novembre dalla valutazione, la qualità del modello sui mesi normali
migliora sensibilmente (R² da 0,373 a 0,589) — confermando che il problema
è isolato al superamento del massimo storico, non una debolezza generale
del modello.

### La previsione finale — primo trimestre 2026

**4 categorie con previsioni coerenti e affidabili** (Bellezza & Salute,
Elettronica, Libri & Media, Sport & Tempo Libero): crescita prevista
omogenea, tra l'8% e il 20% anno su anno, in linea con il trend storico
osservato.

**2 categorie con previsioni anomale** (Abbigliamento, Casa &
Arredamento): crescita prevista implausibile (+29-68% anno su anno, contro
+8-20% delle altre). Causa identificata: per queste due categorie, il
modello ha dato più peso al valore del trimestre di picco appena concluso
(ottobre-dicembre 2025) che al vero riferimento stagionale (lo stesso mese
un anno prima, tipicamente basso per gennaio-marzo) — un effetto distinto
dal limite di estrapolazione, perché qui il valore previsto resta dentro
il range storico, semplicemente sbagliato per la stagione.

**Correzione applicata per le 2 categorie anomale**: il valore del modello
non è stato usato direttamente. È stato sostituito con il valore dello
stesso mese dell'anno precedente, moltiplicato per un fattore di crescita
fisso di **1,12** — il punto medio della forbice 10-15% osservata come
crescita media nelle 4 categorie affidabili.

---

## ⚠️ Limiti dichiarati

- Il limite di estrapolazione sui picchi stagionali non si è manifestato
  in questo forecasting specifico, perché l'orizzonte scelto (3 mesi,
  bassa stagione) è stato deliberatamente pensato per evitarlo — ma resta
  un limite strutturale del modello, da tenere in conto per qualunque
  previsione futura che debba coprire un nuovo picco di novembre.
- Il modello usato per la previsione finale è stato riaddestrato su tutto
  lo storico disponibile, quindi non è esattamente lo stesso modello
  valutato con MAE/RMSE/R² — quelle metriche restano una stima
  approssimativa dell'affidabilità, non una descrizione esatta del
  modello finale.
- L'anomalia sulle 2 categorie è un effetto collaterale della scarsità di
  dati di allenamento (126 righe): con una profondità degli alberi
  limitata e pochi esempi, il peso relativo tra le feature stagionali e
  quelle di trend recente può variare in modo incoerente da categoria a
  categoria.

---

## 📁 File in questa cartella

| File | Contenuto |
|---|---|
| [`forecasting.ipynb`](forecasting.ipynb) | Notebook completo: EDA, feature engineering, addestramento, valutazione, previsione finale |
| [`vw_domanda_categoria_mensile.sql`](vw_domanda_categoria_mensile.sql) | Vista Gold di origine |
| [`input/`](input/) | CSV esportato dalla vista, letto dal notebook |
| [`ddl_stock_forecast.sql`](ddl_stock_forecast.sql) | Definizione tabella `gold.stock_forecast` |
| [`load_stock_forecast.sql`](load_stock_forecast.sql) | Stored procedure di caricamento |
| [`output/`](output/) | CSV della previsione finale, ricaricato in Gold |