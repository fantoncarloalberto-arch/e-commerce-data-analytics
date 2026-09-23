# 📊 Dashboard E-commerce — Overview, Clienti, Prodotti, Campagne, Logistica, Magazzino

Dashboard Power BI a 6 pagine, costruita sul livello **Gold** del data warehouse
e arricchita con gli output dei 4 modelli di Machine Learning (clustering,
churn, forecasting, market basket). Ogni numero riportato qui è stato
verificato direttamente sul modello dati, non stimato a occhio.

> 📁 Il file `.pbix` si trova in questa cartella. Dati sintetici, generati a
> scopo didattico — nessun dato reale di clienti o transazioni.

---

## 📖 Filo conduttore

Il business raccontato da questa dashboard è **sano e in crescita**, ma con
più livelli di concentrazione di rischio annidati uno dentro l'altro: su una
categoria di prodotto, su un segmento di clientela, su un singolo SKU, su un
singolo mese dell'anno. Nessuno di questi rischi è un problema conclamato —
ma il pattern si ripete così spesso, in pagine diverse e indipendenti, da
non essere una coincidenza: **un numero aggregato che sembra raccontare una
buona notizia nasconde quasi sempre una realtà diversa, spesso opposta, a un
livello di dettaglio inferiore**. Il caso più netto è il Paradosso di Simpson
in Logistica (insight 26) — ma lo stesso meccanismo di mix/composizione
attraversa anche Campagne e Magazzino.

---

## 🏠 Pagina Overview

**1. Crescita diffusa, non concentrata in un solo mese.** La crescita YoY del
fatturato è distribuita su quasi tutti i mesi. Il picco di novembre (Black
Friday) c'è ed è coerente con la stagionalità già vista in fase di
forecasting, ma non è l'unica fonte di crescita.

**2. Il margine oscilla, il fatturato assoluto no.** Margine % lordo:
38,33% (2023) → 37,66% (2024) → 38,03% (2025), una "V". Il margine lordo in
**valore assoluto** invece è sempre cresciuto (295.652€ → 459.687€, +55% tra
2023 e 2024): la compressione percentuale è più che compensata dalla crescita
del fatturato — un compromesso di business accettabile, non un segnale di
inefficienza.

**3. Il costo di spedizione va contato anche sugli ordini falliti.** 423
ordini risultano "Annullato" ma con `data_spedizione` valorizzata: partiti e
poi annullati/resi. Quel costo è stato speso realmente e va incluso nel
margine netto, altrimenti il margine reale sembrerebbe più alto di quanto sia.

**4. Il Tasso di Annullamento è alto e va monitorato.** 13,3% del totale
ordini piazzati finisce annullato — fatturato generato ma mai incassato.

**5. Dicembre 2025 è strutturalmente incompleto (right-censoring).** Tutti i
199 ordini "In lavorazione" e gli 85 "Spedito" dell'intero dataset (3 anni)
sono concentrati in dicembre 2025, l'ultimo mese disponibile. Qualsiasi
grafico che mostri quel mese "in calo" sta mostrando un artefatto del taglio
dei dati, non un vero rallentamento.

---

## 👥 Pagina Clienti

**6. Concentrazione forte del valore sui clienti fedeli.** Il 38,33% dei
clienti ("Fedeli") genera il **72,31%** del fatturato totale — confermato
**universale**: si ripete in ogni zona geografica (68–76%), non è un
artefatto di una zona dominante.

**7. Crescita clienti in decelerazione, ma sana.** Nuovi Clienti:
+141,2% (2023) → +61,0% (2024) → +15,2% (2025). Il rallentamento è reale, ma
il **tasso di attivazione** (chi si registra e poi compra davvero) resta
stabile al 97–98% nonostante la base clienti sia quadruplicata — la qualità
dell'acquisizione non si deteriora, solo il ritmo.

**8. Il Tasso di Riacquisto si erode lentamente.** 98,8% (2023) → 97,5%
(2024) → 96,8% (2025) — calo piccolo ma costante, coerente con l'ingresso
crescente di clienti "nuovi dell'anno" che non hanno ancora avuto tempo di
riordinare entro dicembre.

**9. Riacquisto e Abbandono sono metriche indipendenti.** I clienti poi
abbandonati avevano riacquistato tanto quanto quelli rimasti attivi (92,9%
contro 98,7%) — il comportamento storico di riacquisto **non predice** chi
abbandonerà. Conferma indiretta del perché il modello di classificazione
churn non ha trovato segnale utile (vedi [`ml/churn/`](../ml/churn/)).

**10. Anomalia Europa — pattern "boom-and-bust".** A differenza di Italia
(decelerazione dolce) e Resto del mondo (stagnazione poi ripartenza),
l'Europa mostra una vera rottura: crescita fortissima nel 2024 (+44 clienti,
la più alta di tutte le zone) seguita da un arresto brusco nel 2025 (82
clienti, quasi fermo) e un crollo del riacquisto (100%→96,35% in un anno). La
base attiva europea **continua comunque a crescere** in assoluto
(57→137→220 clienti) — il problema è nel ritmo di nuovi ingressi e nella
fedeltà comportamentale, non una vera perdita di clienti.

**11. L'Europa ha anche la quota più bassa di clienti fedeli.** 34,09%
contro 39,73% (Italia) e 45,71% (Resto del mondo) — coerente con gli altri
segnali negativi di quella zona.

**12. Il fatturato per zona è proporzionale al numero di clienti.** Italia
50,1% fatturato/51,0% clienti, Europa 35,3%/37,0%, Resto del mondo
14,6%/12,0% — nessuno sbilanciamento geografico marcato. L'unica leggera
eccezione (Resto del mondo genera il 22% in più di fatturato per cliente)
si spiega interamente col suo mix di segmenti più favorevole, non con un
effetto geografico autonomo.

---

## 📦 Pagina Prodotti

**13. Nessuna categoria è "ideale" (alto fatturato + alto margine).** Il
quadrante Fatturato/Margine mostra un vuoto strategico strutturale: ogni
categoria sceglie tra volume e marginalità, nessuna ottiene entrambi.

**14. Elettronica: tanto fatturato, margine basso — ma non per volume di
pezzi.** Genera il 70% del fatturato con il margine più basso in assoluto
(29,6% contro 45–68% delle altre). Non vende più pezzi delle altre categorie
(7.875 unità contro 4.000–8.200) — vende a un **prezzo medio per pezzo**
molto più alto (319€ contro 16–94€).

**15. Il margine di ogni categoria è quasi fisso nel tempo — l'oscillazione
è sempre mix.** Variazioni sotto lo 0,3% su 3 anni. L'intera "V" del punto 2
dipende **esclusivamente** dalle differenze di velocità di crescita tra
categorie: nel 2024 Elettronica cresce più veloce di tutte (+61,3%) e il suo
peso sale (68,9%→70,3%), abbassando il margine medio; nel 2025 rallenta
(+31,1%) e le altre recuperano peso.

**16. Cross-sell: due famiglie di combinazioni, due strategie diverse.**
Relazioni **forti ma meno frequenti** (Ciclismo↔Outdoor, i tre della
Famiglia, Smartphone↔Informatica, Cura Persona↔Make-up — buone per
suggerimenti personalizzati) e una relazione **più diffusa ma meno intensa**
(Libri↔Giochi&Hobby, 6,6% di tutti gli ordini — buona per bundle diretti a
volume). Anche qui un quadrante "ideale" (forte E frequente) risulta vuoto —
vedi [`ml/market_basket/`](../ml/market_basket/).

**17. Concentrazione estrema su un singolo prodotto — l'insight più
critico dell'intera dashboard.** Tra i Top 10 best seller, **un solo
prodotto (Soundbar Wireless) rappresenta il 42–43% dell'intero fatturato
aziendale**, in modo consistente per tutti e 3 gli anni (329.339,80€ su
771.316,68€ nel 2023 = 42,7%). Gli altri 9 del Top 10 contribuiscono
ciascuno tra lo 0,5% e l'1,8%. Più grave della concentrazione di categoria:
Elettronica pesa il 70% come categoria, ma questo singolo prodotto vale da
solo circa il **60%** del fatturato dell'intera categoria — non un rischio
diversificabile, una dipendenza da un singolo SKU. Il fatto che sia lo
stesso prodotto per 3 anni consecutivi indica un prodotto di punta
strutturale, ma segnala anche una mancanza di alternative altrettanto forti
sviluppate nel tempo.

**18. Gli altri 9 best seller: due archetipi commerciali.** Un gruppo a
**basso prezzo/alto volume** (11–25€, 420–900 unità — es. Elastici Fitness
Home, Integratore Vitaminico) e un gruppo a **prezzo più alto/volume più
contenuto** (87–160€, 60–83 unità — es. Tappeto Naturale, Rasoio Elettrico
Pro, Speaker Bluetooth Studio), che finiscono comunque nella stessa fascia
di contributo (0,7–1,8%). Questa diversificazione naturale è il contrappeso
sano al rischio del punto 17.

---

## 📢 Pagina Campagne

**19. Il ROAS aggregato migliora, ma è trainato da una sola campagna.** ROAS
Aggregato quasi triplicato in 3 anni: 0,40 (2023) → 0,76 (2024) → 1,02
(2025), superando per la prima volta il pareggio nel 2025. Gran parte del
miglioramento è attribuibile a **Primavera Digitale** (ROAS: 0,37 → 2,37 →
3,56), mentre le altre 4 campagne restano su livelli molto più modesti.
Causa strutturale: Primavera Digitale è l'unica campagna esclusivamente
**Elettronica** in tutti e 3 gli anni — ticket medio molto più alto
(700–1.150€) rispetto alle altre (20–200€). *Limite onesto: la causa
dell'esplosione nel 2024 non è identificabile nei dati disponibili.*

**20. Promo Natale è un problema cronico, non un episodio isolato.** In
tutti e 3 gli anni assorbe la quota di budget più alta (32,4%→29,0%→29,7%)
ma restituisce sistematicamente meno fatturato di quanto la spesa
lascerebbe sperare. Nel 2025 il fatturato **cala anche in valore assoluto**
(-17,2%) nonostante il budget sia aumentato (+34,6%) — l'unica combinazione
"peggio su entrambi i fronti" tra tutte e 15 le campagne osservate.

**21. Lo squilibrio tra budget assorbito e fatturato generato è netto.**
Primavera Digitale 2025 assorbe il 13,5% del budget totale ma genera il
47,4% del fatturato — una sproporzione che da sola giustifica una revisione
dell'allocazione tra le 5 campagne.

**22. Il ROAS è per costruzione una stima prudenziale.** Calcolato solo sui
prodotti effettivamente promossi nella finestra temporale esatta — esclude
l'effetto alone (clienti attratti che comprano anche altro fuori dal
paniere), quindi probabilmente **sottostima** il ritorno reale, non lo
sovrastima.

**23. Primavera Digitale crolla su tre fronti indipendenti, mentre le
campagne generaliste convergono verso l'alto — quasi tutte nello stesso
anno.** Nel 2025 Saldi Estivi (1,11) e Promo Natale (1,01) superano la
soglia del ritmo normale di registrazione, mentre Saldi Invernali (0,99) vi
arriva sostanzialmente alla pari — tutte e tre in salita quasi monotona sui
3 anni. Nello stesso anno **Primavera Digitale — la campagna con il ROAS più
alto in assoluto (insight 19)** — crolla su ogni fronte indipendente: il
ritmo di registrazione scende (1,27 → 0,66 → 0,29), e l'efficienza per euro
e giorno investiti crolla ancora più nettamente (0,288 → 0,156 → 0,037
registrazioni per 1.000€-giorno), dalla più efficiente in assoluto nel 2023
all'ultimo posto nel 2025. Due strumenti di misura indipendenti raccontano
la stessa storia: la campagna che genera più fatturato è quella che genera
sempre meno clienti nuovi, e li genera sempre meno efficientemente.

**24. Black Friday: un ritmo alto non significa convenienza, e il segnale
resta comunque fragile.** In 2 anni su 3 il ritmo di registrazione di Black
Friday è tra i più alti della pagina (1,25 nel 2023, 1,25 nel 2024, sopra
la soglia normale) — ma sulla stessa campagna, l'efficienza per euro e
giorno investiti resta quasi sempre tra le più basse (0,074 · 0,092 · 0,073
registrazioni per 1.000€-giorno, mai tra le prime 3 su 5). *Limite onesto:
con soli 7 giorni di durata fissa ogni anno, il ritmo di registrazione di
Black Friday è statisticamente fragile — bastano una o due registrazioni in
più o in meno per farlo oscillare vistosamente (1,25 → 1,25 → 0,89) — ma il
basso rendimento per euro-giorno è un pattern stabile su tutti e 3 gli anni,
non un artefatto della scarsità di dati. Nota a margine: il budget di Black
Friday risulta identico all'euro tra 2024 e 2025 (7.797,89€) — una
coincidenza nei dati sintetici, non un pattern di business da interpretare.*

**25. Promo Natale nel 2025: più iscrizioni, meno fatturato — nella stessa
campagna.** Il ritmo di registrazione di Promo Natale passa da sotto il
normale (2023, 2024) a sopra il normale proprio nel 2025 (insight 20 e 23),
l'anno in cui il fatturato della stessa campagna cala anche in valore
assoluto nonostante il budget aumentato. Un'ulteriore conferma che
acquisizione di nuovi clienti e valore generato non vanno necessariamente
di pari passo.

---

## 🚚 Pagina Logistica

**26. Il miglioramento aggregato è un'illusione statistica — Paradosso di
Simpson.** Costo medio di spedizione (-3,6%) e tempo di transito (-7,6%)
migliorano a livello aziendale nel 2025, ma **ogni singolo corriere,
singolarmente, peggiora** quasi su tutta la linea nel 2024 (Global Shipping
+0,4% costo, EuroLogistics +0,7% costo e +1,4% tempo, Corriere Nazionale
+0,3% costo). Verificato scomponendo l'effetto (2023→2024, Costo Medio):
l'effetto mix da solo avrebbe fatto scendere il costo di 0,13€; l'effetto
prezzo da solo lo avrebbe fatto salire di 0,04€. La somma (-0,09€) coincide
quasi esattamente con la variazione reale. Il miglioramento nasce
interamente dallo spostamento del mix di volume verso i corrieri più
economici/veloci, non da un'efficienza reale conquistata da nessuno dei tre.

**27. Il vero problema non è "Global Shipping", è il mercato Resto del
mondo.** Global Shipping serve sia UK sia Resto del mondo (per ragioni
doganali post-Brexit). Scomponendo: il Regno Unito cresce sanamente
(+30,1% nel 2024, +16,4% nel 2025), mentre il **Resto del mondo si è quasi
fermato** (+41,1% nel 2024, appena **+1,8%** nel 2025). Senza questa
scomposizione si sarebbe conclusa erroneamente una debolezza generale del
corriere internazionale.

**28. Il collo di bottiglia è nel trasporto, non nel magazzino.** Il Tempo
di Elaborazione (ordine→spedizione) è pressoché identico per tutti i
corrieri (2,8–2,9 giorni), stabile anche nei picchi stagionali nonostante il
volume ordini sia quasi raddoppiato in 2 anni. Il Tempo di Transito invece
scala fortemente con la distanza: 3,0 (Nazionale) → 6,5 (EuroLogistics) →
15,0 giorni (Global Shipping).

**29. La convenienza "per giorno" può ingannare se letta da sola.** Global
Shipping, il più caro in assoluto (13,52€/spedizione), ha il **miglior
rapporto costo/giorno** (0,90€/gg) — il costo fisso si spalma su più giorni
di viaggio. Nel 2024 EuroLogistics ha mostrato un costo/giorno
apparentemente migliorato (-0,7%) pur peggiorando sia in costo assoluto
(+0,7%) sia in tempo di transito (+1,4%) — un artefatto della divisione, non
un vero miglioramento.

**30. Corriere Nazionale si muove in direzione opposta agli altri due.** Sul
Tempo di Elaborazione, verificato su entrambi gli anni: quando Corriere
Nazionale migliora (-4,0% nel 2024), gli altri due peggiorano (+1,9% e
+2,3%); quando peggiora (+2,5% nel 2025), gli altri due migliorano (-2,2% e
-1,5%). Ipotesi plausibile ma **non verificata**: riallocazione di risorse
tra rotte nazionali e internazionali.

---

## 🏭 Pagina Magazzino

**31. Nessuna categoria copre 3 mesi di domanda prevista.** Confrontando la
giacenza attuale (fine 2025) con la domanda prevista dal modello di
forecasting (Fase 4 ML, orizzonte gen-mar 2026), la copertura varia dal
37,3% (Elettronica) al 61,4% (Abbigliamento) — nessuna categoria raggiunge
il 100%. In giorni: da 33,6 a 55,3. *Limite onesto: il dato assume zero
riassortimento nel periodo — è un indicatore di urgenza relativa, non una
previsione certa di rottura di stock.*

**32. Elettronica converge su due segnali di rischio indipendenti.** È sia
la categoria con la copertura futura più bassa (37,3%) sia quella col
prodotto singolo storicamente più critico: **Smartphone Air**, 3 rotture di
stock in 2 anni (feb 2024, feb 2025, nov 2025) — l'unico prodotto al primo
posto da solo nella classifica di criticità.

**33. Novembre è il mese critico per le rotture di stock, in modo
trasversale.** Il **42% di tutte le rotture storiche** (21 su 50, su 3 anni)
si concentra nel solo mese di novembre — coerente con Black Friday. Dicembre
è secondo (7 eventi, 14%). Il magazzino regge bene i volumi di quel periodo
(Tempo di Elaborazione stabile, punto 28), ma è proprio lì che lo stock si
esaurisce più spesso.

**34. Un'eccezione al pattern generale: Sport & Tempo Libero.** Unica
categoria a non seguire lo schema di novembre: il picco storico di rotture è
ad **aprile** (3 su 7, il 43%), non a novembre (1 solo evento). Anomalia non
ancora spiegata.

**35. Abbigliamento: la copertura migliore nasconde il rischio stagionale
più concentrato.** Copertura futura più rassicurante di tutte (61,4%),
eppure il **71% delle sue rotture storiche (5 su 7)** è avvenuto a
novembre — la concentrazione stagionale più estrema tra tutte le categorie.

**36. Bellezza & Salute: rischio distribuito su più prodotti, non
concentrato su uno.** A differenza di Elettronica (un solo colpevole),
Bellezza & Salute ha **4 prodotti diversi** appaiati al livello di
criticità più alto (2 rotture ciascuno) — un rischio gestionalmente diverso:
risolvere un singolo prodotto non risolve quello della categoria.

---

## ⚠️ Limiti dichiarati

- Questi insight descrivono **pattern verificati nei dati**, non le loro
  cause ultime esterne (perché Primavera Digitale è esplosa nel 2024, perché
  Sport & Tempo Libero rompe lo schema di novembre) — rispondere richiederebbe
  contesto di business non ricavabile dai soli dati.

---

## 🖼️ Screenshot

| Pagina | File |
|---|---|
| Overview | [`screenshot/overview.png`](screenshot/overview.png) |
| Clienti — Segmentazione | [`screenshot/clienti.segmentazione.png`](screenshot/clienti.segmentazione.png) |
| Clienti — Crescita | [`screenshot/clienti.crescita.png`](screenshot/clienti.crescita.png) |
| Clienti — Fedeltà | [`screenshot/clienti.fedeltà.png`](screenshot/clienti.fedeltà.png) |
| Prodotti — Marginalità | [`screenshot/prodotti.marginalità.png`](screenshot/prodotti.marginalità.png) |
| Prodotti — MBA (Cross-sell) | [`screenshot/prodotti.MBA.png`](screenshot/prodotti.MBA.png) |
| Prodotti — Best Seller | [`screenshot/prodotti.BestSeller.png`](screenshot/prodotti.BestSeller.png) |
| Campagne — ROAS | [`screenshot/campagne.ROAS.png`](screenshot/campagne.ROAS.png) |
| Campagne — Registrazioni Campagna | [`screenshot/campagne.RegistrazioniCampagna.png`](screenshot/campagne.RegistrazioniCampagna.png) |
| Logistica — Corrieri | [`screenshot/logistica.corrieri.png`](screenshot/logistica.corrieri.png) |
| Logistica — Mix Corrieri | [`screenshot/logistica.MixCorrieri.png`](screenshot/logistica.MixCorrieri.png) |
| Logistica — Trend Mensile |
