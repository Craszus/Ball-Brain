# Ball Brain – spillet og menyene (til designalternativer)

Sist oppdatert 2026-11-23. Beskriver appen **slik den er i dag**, og hva som er **planlagt**.
Alle mål er for en mobilskjerm på **375 × 812** (stående). Appen har bare mørk modus.

Statusmerker: ✅ bygget · 🟡 data klart, skjerm ikke bygget · ⬜ planlagt

---

> **Oppdatering 2026-11-23: hovedmenyen følger nå briefen «Premium Nattkamp / Stadion-gull».**
> Eksakte farger: bakgrunn `#0B3D2E` (med svak gress-tekstur), kort `#145A42`, gull `#F5B301` / lys `#FFD84D` /
> `#FFE27A`, gullgradient `#FFD84D → #F5B301 → #D99A00`, ikonbrikke `#0A1224`, tekst hvit / sekundær `#C9D6C8`,
> riktig `#2E9E5B`. Logo = fotball (venstre) + gullhjerne (høyre) med hvit outline (`assets/brand/logo_mark.png`).
> Nivåkort: alltid gull med LVL-skjold, XP-bar og % til høyre. Kort: radius 16, 1 px kant, skygge.
> Ikonbrikker: mørk bakgrunn, 2 px gullkant, gull ikon (aldri grønn brikke med hvitt ikon).
> Referansebilder ligger i `design/`. Tabellene under er fra før oppdateringen og gjelder ikke hovedmenyen lenger.

## 1. Hva er Ball Brain?

En fotballquiz for folk som kan spillet på ordentlig. Du spiller korte runder (ca. 10 oppgaver),
tjener **poeng**, som også er **XP**. XP gir **nivåer**, og nivåer og prestasjoner låser opp **troféer**.
Senere kommer rangeringslister, 1v1 og vennegrupper.

Følelsen skal være: konkurransepreget, fotballsk, belønnende. Det skal se ut som en kamp-dag, ikke
som en skole-quiz.

## 2. Navigasjon (kart over skjermene)

```
Startskjerm ✅
├─ Regler-quiz ✅ ──► Resultat ✅ ──► (Nivåopp-feiring ✅)
├─ Bildesortering ✅ ──► Resultat ✅ ──► (Nivåopp-feiring ✅)
├─ Stadion-quiz (gjett stadion fra bilde) 🟡
├─ Gjett spilleren (portrett) 🟡
├─ Kart-utfordring (plasser stadion/lag på kart) ⬜
├─ Profil og troféer ✅
│   ├─ Rediger profil (avatar, navn, land) ✅
│   └─ Innstillinger ✅ (også fra startskjermen)
│       └─ Bildekreditering / Om appen ⬜ (må på plass når bilder brukes)
└─ Senere: innlogging, rangeringslister, 1v1, vennegrupper ⬜
```

Tilbake-pil øverst til venstre på alle underskjermer. Ingen nedre faner i dag. Det kan komme hvis
menyen vokser (se «Spørsmål til designet» nederst).

## 3. Designsystem (slik det er nå)

**Farger**

| Navn | Hex | Bruk |
|---|---|---|
| Bane (mørk) | `#0B3D2E` | Bakgrunn |
| Bane (lys stripe) | `#0E4A37` | Klippestriper i bakgrunnen |
| Kort | `#145A42` | Kort, felt, flater |
| Gress | `#2E9E5B` | Spillmodus-ikoner, riktig svar |
| Gull | `#F5B301` | Primærknapper, poeng, XP, fremhevinger |
| Blekk | `#0E1F18` | Tekst på gull |
| Hvit | `#FFFFFF` | Hovedtekst (70 % for sekundær) |
| Rød | `#FF5252` | Feil, farlige valg (nullstill) |

**Bakgrunn:** hele appen ligger på en gressbane: 10 vannrette klippestriper som veksler mellom to
grønnfarger, med svake hvite banelinjer (7 %): midtlinje, sentersirkel og et straffefelt øverst.

**Typografi:** standard Material/Roboto. Tittel i appfeltet: STORE BOKSTAVER, 20, fet, 1 pt
bokstavavstand. Store tall og overskrifter: veldig fet (w900). Små etiketter: 12, STORE BOKSTAVER,
1,5 pt bokstavavstand, 70 % hvit.

**Former:** kort og knapper har 18 radius. Knapper er 56 høye og går over hele bredden. Sidemarg 16–20.
Ikonbrikker 54 × 54 med 16 radius.

**Knapper:** *Primær* = gull med mørk tekst. *Sekundær* = gjennomsiktig hvit 8 % med 25 % hvit kant og
hvit tekst. Lite gullformet «pille» brukes til poeng og tellere.

**Grafikk tegnet i kode (kan erstattes av illustrasjoner):**
fotball-logo, pokaler (bronse/sølv/gull), spiller-avatarer, konfetti, banebakgrunn.

**Lyd og følelse:** korte lydeffekter for riktig, feil, fulltid og nivåopp, pluss vibrasjon.
Kan slås av i innstillinger.

## 4. Skjermene, ovenfra og ned

### 4.1 Startskjerm ✅
- Øverst: **avatar** (56, gullring, trykk åpner profil) til venstre; **tannhjul** (innstillinger) til høyre.
- **Fotball-logo** (96) midtstilt.
- Navnet **BALL BRAIN** (34, w900, 3 pt avstand) og undertittel «Hvor mye kan du egentlig om fotball?».
- **XP-kort:** gullsirkel med nivåtall (52, hvit kant), nivåtittel (f.eks. «Benkesliter»), «650 / 1500 XP»
  og en 12 høy gull XP-bar.
- **Modus-kort** (ikon-brikke, tittel 18 fet, undertittel, pil):
  1. Regler-quiz – «Offside, straffer, VAR og alt dommeren kan» (grønn brikke, fløyte-ikon)
  2. Bildesortering – «Dra i riktig rekkefølge – fra eldst til nyest» (grønn brikke, tidslinje-ikon)
  3. Profil og troféer – «Se rekordene og troféskapet ditt» (gull brikke, pokal-ikon)
- Kommer: kort for Stadion-quiz, Gjett spilleren, Kart-utfordring (listen blir lang → vurder
  rutenett eller faner).

### 4.2 Regler-quiz ✅
- Appfelt: pil, **REGLER-QUIZ**, gull poeng-pille («110 p»).
- **Fremdriftsbar** (8 høy, gull) og etikett «SPØRSMÅL 3 AV 10 · VM-HISTORIE» (kategori vises).
- **Spørsmålskort** med spørsmålet (21, fet, opptil 4 linjer).
- **2–4 svarknapper** (sekundærstil, midtstilt tekst). Ett trykk = svar. Ja/Nei-spørsmål har to knapper.
- **Ingen farge-tilbakemelding i dag**: bare lyd/vibrasjon, og så går det rett til neste. Det er et
  åpent designspørsmål (flash grønt/rødt? vis riktig svar?).
- 10 spørsmål per runde, tilfeldig utvalg.

### 4.3 Bildesortering ✅
- Samme topp som regler-quiz («OPPGAVE 1 AV 9», fremdrift, poengpille).
- Overskriftskort med oppgaven («Sorter VM-vinnerne fra eldst til nyest»).
- **Liste med kort som kan dras.** Hvert kort: **gullsirkel med posisjonsnummer** (1, 2, 3 …), tekst, og
  «dra-håndtak» til høyre.
- Gull knapp nederst: **«Sjekk rekkefølge»**. Etter sjekk vises «FORRIGE: RIKTIG» (grønn) eller «FORRIGE: FEIL» (rød).
- NB: elementene er **tekst i dag**. Det skal bli **bilder** (stadioner/spillere) – design gjerne bildekort.

### 4.4 Resultatskjerm («FULLTID!») ✅
- Liten fotball (64), stor **gullpokal** (130), «FULLTID!» (gull, 16, 4 pt avstand),
  **poeng** (40, w900), «+N XP» (gull), **XP-bar som fylles opp** (1,2 s), kort notat,
  gull knapp **«Spill igjen»**.

### 4.5 Nivåopp-feiring ✅
Vises over resultatskjermen når runden gir nytt nivå. Mørk 92 % bakgrunn, **konfetti** (90 biter i
6 farger faller i 4 s), «NIVÅ OPP!» (gull, 34), **stort nivåmerke** (150, gull, hvit 8 kant, glød,
tall 80) som spretter inn, nivåtittel (26), «Du er nå nivå N», gull knapp «Fortsett». Trykk hvor som
helst lukker.

### 4.6 Profil og troféer ✅
- Appfelt: **PROFIL**, tannhjul til høyre.
- **Profilkort:** avatar (92), kallenavn (22, w900), «NO · Norge», knapp **«Rediger»**, XP-bar under.
- **4 stat-kort** (2 × 2): Runder spilt, Poeng totalt, Beste regler-runde, Beste sortering
  (gullikon, tall 24, etikett 12).
- **Troféskap** med gullpille «5/7». **Rutenett 2 kolonner**: pokal (84), tittel, beskrivelse.
  Opptjent = farge (bronse/sølv/gull + ikon i skålen). Ikke opptjent = grå pokal med lås, nedtonet tekst.

### 4.7 Rediger profil ✅
- Stor **avatar-forhåndsvisning** (170) som oppdateres live.
- Felt: **Kallenavn** (3–16 tegn, bokstaver/tall/punktum/understrek/bindestrek) og **Land** (nedtrekk,
  14 land, lagres som tobokstavs-kode).
- Valg: **Hudfarge** (6 sirkler) · **Frisyre** (Kort, Langt, Snauet, Krøll, Hanekam) · **Hårfarge** (6) ·
  **Drakt** (8 todelte sirkler: rød, blå, grønn, svart/gull, gul/blå, hvit/rød, lilla, himmelblå) ·
  **Mønster** (Ensfarget, Striper, Ringer, Halvdelt) · **Draktnummer** (skyver 1–99).
- Gull knapp **«Lagre»** (deaktivert ved ugyldig navn).

### 4.8 Innstillinger ✅
- **INNSTILLINGER.** Kort med to brytere: **Lydeffekter**, **Vibrasjon**.
- Kort **«Nullstill fremgang»** (rødt ikon). Åpner en bekreftelsesdialog («Dette kan ikke angres.
  Profil og avatar beholdes.»).
- Liten tekst nederst: «Ball Brain · versjon 1.0.0». Mangler: **Om appen / bildekreditering**, personvern, vilkår.

## 5. Spillregler (for tekster og skjermer)

**Poeng per riktig svar** = 100 × vanskelighetsgrad (1–5) + **tidsbonus** på opptil 50 (faller jevnt
over 15 sekunder). Feil svar = 0.

**XP = totalpoeng.** Nivå n starter på 250 × (n−1) × n XP (nivå 2 = 500, 3 = 1 500, 4 = 3 000 …).
Titler: 1 Benkesliter · 2 Innbytter · 3 Rotasjonsspiller · 4 Fast på laget · 5 Midtbanegeneral ·
6 Lagkaptein · 7 Stjernespiller · 8 Landslagsspiller · 9 Verdensstjerne · 10+ Legende.

**Troféer (7 i dag):** Første kamp (bronse, 1 runde) · Fast gjest (sølv, 10 runder) · Veteran (gull,
50 runder) · Tusenkroner (bronse, 1 000 poeng) · Ballkjenner (gull, 10 000 poeng) · Regelekspert
(sølv, 1 000 p i én regler-runde) · Tidslinje-mester (sølv, 500 p i én sorteringsrunde).

**Innhold i dag:** 113 spørsmål (regler, VM/EM-historie, klubbfotball, Norge, stadioner) og 9
sorteringsoppgaver.

## 6. Planlagte skjermer (trenger design)

**Stadion-quiz 🟡** – stort stadionbilde (4:3, avrundet) med **ⓘ-knapp** nede i hjørnet, spørsmålet
«Hvilket stadion er dette?», 4 svarknapper. Etter svar: vis riktig stadion og klubb.

**Gjett spilleren 🟡** – **tett beskåret portrett** (hode, 1:1, avrundet, evt. sirkel), ⓘ-knapp,
«Hvem er dette?», 4 navn. Hint-knapp (nasjonalitet) mot lavere poeng kan vurderes.
Viktig: klubblogoer og draktsponsorer skal ikke synes.

**Kart-utfordring ⬜** – mørkt verdenskart **uten stedsnavn**. Øverst: «Hvor ligger *Anfield*?» eller
«Hvor spiller *Liverpool*?». Spilleren trykker for å sette en nål → «Bekreft». Resultat: riktig
sted markert, linje mellom nål og fasit, **avstand i km** og poeng (nærmere = mer).

**Bildekreditering / Om appen ⬜** – liste over alle bilder: miniatyr, tittel, fotograf, lisens (CC BY /
CC BY-SA) med lenke. Åpnes fra Innstillinger. **Påkrevd av lisensene.**

**ⓘ-kreditering på bilde ⬜** – liten ⓘ-knapp i hjørnet av hvert bilde. Trykk åpner et lite kort med
tittel (lenke til kilden), fotograf og lisens (lenke til lisensteksten).

**Senere (ikke bestemt):** velkomst/innlogging (anonym først, kobles til e-post senere) ·
rangeringslister (Nasjonal, Global, Venner – «se hvor vennene dine ligger») · 1v1-duell (lobby,
nedtelling, sanntidspoeng, resultat) · vennegrupper (opprett/bli med via kode og delingslenke,
gruppetoppliste, gruppetroféer) · VAR-/dommermodus · delingskort for resultat.

## 7. Det designeren kan lage alternativer for

Appen er bevisst enkel i dag. Ting som er åpne for nytt utseende:

1. **Visuell stil** – f.eks. (a) mørk «kampkveld» med flomlys, (b) retro samlekort/Panini, (c) lys og
   ren «sportsavis», (d) slik den er nå, men penere.
2. **Logo, ordmerke og app-ikon** + oppstartsskjerm.
3. **Pokaler og prestasjoner** – egne illustrasjoner per trofé (ikke bare farge + ikon); egne
   **nivåmerker** (f.eks. ulike rammer for nivå 1–10); prestasjonsmerker for gruppeseire.
4. **Spillmodus-ikoner/kort** – hver modus med egen illustrasjon i stedet for et ikon.
5. **Spørsmålsskjerm** – tilbakemelding ved svar (farge, animasjon, forklaring), tidsbar,
   vanskelighetsgrad-indikator, kategori-merker.
6. **Bildekort** for stadion/spiller/sortering: ramme, ⓘ-plassering, lasteskjelett.
7. **Avatar-system** – flere deler (skjegg, briller, skotyper, hodebånd), og en dedikert
   avatar-/garderobeskjerm.
8. **Navigasjon** – nedre fanelinje (Spill · Rangering · Venner · Profil) i stedet for lang startskjerm?
9. **Tomme/låste tilstander** – før første runde, låst modus, ingen venner ennå, ingen nett.
10. **Tilgjengelighet** – kontrast (gull på grønt), skriftstørrelse, fargeblindhet (riktig/feil bør ikke
    bare være grønn/rød).

**Leveranser som er nyttige fra design:** logo (SVG), app-ikon (1024 px), pokal-sett (SVG/PNG, bronse/sølv/gull
+ låst), nivåmerker, modus-illustrasjoner, ikonsett, bakgrunnsmønster, avatar-deler (SVG), fargepalett
og skrifttyper (Flutter kan bruke egne fonter).

## Tillegg 2026-11-23
- **Velg din avatar** (første oppstart): 6 avatarer, spillernavn, nivåkort, «Bekreft».
- **Min Avatar**: hudfarge, hår, hårfarge, drakt, mønster, nummer, «Lagre avatar».
- **Geografi-quiz**: spørsmålskort, mørkt verdenskart, tapp for nål, zoom, resultat med avstand og XP.
- **App-ikon**: logoen (fotball + gullhjerne) på mørkegrønn bunn.
