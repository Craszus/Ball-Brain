# Fotballskolen – vurdering og forslag

Skrevet 2026-11-26 av Claude. Regelstoffet er kontrollert mot IFAB Laws of the Game 2026/27 (gjelder fra 1. juli 2026), se kilder nederst. Dette er et forslag; ingen kode er endret.

## 1. Vinkling

**Hvem:** (a) nye fotballinteresserte (partner, forelder, ny supporter) som vil henge med på kampen, og (b) quizspillere som bommer på regelspørsmål og vil forstå hvorfor. Ikke dommere og ikke spillere.

**Navn:** «Fotballskolen» med undertittelen «Forstå spillet». Navnet er kort og lar seg oversette til alle sju språk. Undertittelen trengs fordi «fotballskole» på norsk ellers betyr sommertrening for barn.

**Hovedgrep: situasjonen først, forklaringen etterpå.** Eierens idé om en bane sett ovenfra er riktig, og bør være *scenen for alt* – ikke bare én oppgavetype. Hver leksjon er 3–5 minutter og består av 6–8 situasjoner på banen. Man må svare før man får forklaringen. Slik brukes det vi vet om læring:

- **Gjenkalling før forklaring:** å måtte gjette først gjør at forklaringen fester seg bedre enn å lese den først.
- **Kontrastpar:** to nesten like situasjoner med ulik fasit (på linje / én meter foran). Det er slik man lærer hvor grensen går.
- **Forklaring med én gang, maks to setninger,** og fasiten tegnes på banen (offsidelinja, hvor frisparket tas).
- **Repetisjon med mellomrom:** «Dagens tre» henter situasjoner man har sett før, etter ca. 1, 3 og 7 dager, og blander temaer. Lagres lokalt, slik `lib/services/learning.dart` gjør i dag.
- **Kobling til quizen (det viktigste nye):** appen husker allerede hvilke spørsmål man bommer på og i hvilket tema. Bommer man på et offsidespørsmål, vises «Lær dette i Fotballskolen». Etter en leksjon: «Test deg i quizen».

**Morsomt uten poeng:** enig i ingen XP og ingen rangering. Men noe må vise framgang: et stempel per fullført leksjon og et «fløytemerke» når alle situasjonene i en leksjon er riktige. Ingen timer, ingen straff for feil, «prøv igjen» er alltid lov. Tonen: «Du er dommeren».

**Det jeg ville gjort annerledes enn i forslaget:**

1. **«Trening for dommere» bør bli «Du er dommeren».** Ekte dommeropplæring krever video, skjønn og en nøyaktighet vi ikke kan garantere, og forbundene har egne kurs. Som lek for supportere er det derimot kjernen i hele skolen. Skriv tydelig at innholdet ikke er offisielt.
2. **Fritt merke på banen passer bare til noen få spørsmål.** På kartet er «hvor langt unna» et godt mål. Regler er enten–eller. Bruk fritt merke der svaret er et sted (offsidelinja, straffemerket, hvor frisparket tas), og ellers «trykk på spilleren» eller «hva dømmer du?».
3. **Historiske øyeblikk: bruk regelhistorien, ikke omstridte dommeravgjørelser.** «Hvorfor finnes regelen?» (1925, 1970, 1992 osv.) er trygt, kort og forklarer noe. Om en kjent ball var inne eller ikke er skjønn og krangel – ikke fasit. I første utgave: ett «visste du at»-kort per leksjon, ikke en egen del.
4. **VAR: forklar prinsippene, ikke detaljene.** Protokollen ble endret i 2026/27, og noe er valgfritt per turnering. Hold det til det som er stabilt (se punkt 2 i leksjonslisten under).
5. **Skjønnssituasjoner (hands, hvor hard en takling er) egner seg dårlig som tegning.** De utsettes. Ingen videoklipp eller TV-bilder (rettigheter).

## 2. Hva alle burde kunne – prioritert

1. **Banen og kampens gang:** linjer og felt, 2 × 45, tilleggstid, bytter, ekstraomganger og straffekonkurranse.
2. **Ball ute og igangsetting:** hele ballen over hele linja; innkast, målspark, hjørnespark, avspark, dommerball.
3. **Offside:** posisjon, tidspunkt, involvering, unntakene.
4. **Frispark og straffe:** direkte/indirekte, fordel, muren (9,15 m), straffefeltet.
5. **Kort:** gult, rødt, to gule, å hindre en åpenbar målsjanse.
6. **Dommerteamet og VAR:** hvem gjør hva, hva VAR kan se på, hvorfor det tar tid.
7. **Keeperen:** hva som er lov med hendene, tilbakespill, åtte sekunder, straffespark.
8. **Hands:** det folk krangler mest om, men mest skjønn – derfor ikke først.
9. **Tabell og turnering:** poeng, målforskjell, opp-/nedrykk, cup mot liga, hvordan en europacup er bygd opp. Nybegynnere trenger dette mer enn vi tror.
10. **Posisjoner og formasjoner:** hva en back, en «sekser» og en spiss gjør; 4-4-2 og 4-3-3; pressing og kontring. Dette er å forstå spillet, ikke å spille det.
11. **Regelhistorien:** hvorfor reglene ble som de ble.
12. **Fotballspråket:** ordliste (hat trick, derby, clean sheet).

## 3. Oppgavetyper

| Type | Vurdering |
|---|---|
| **Trykk på spilleren** («hvem står offside?») | Best. Tydelig fasit, lett å treffe, fungerer på liten skjerm. |
| **Hva dømmer du?** (2–4 valg under banen) | Best. Gjenbruker svarknappene fra quizen. |
| **Sett merket** (linje eller punkt på banen) | Bra til steder: offsidelinja, straffemerket, hvor frisparket tas. Fasit med toleranse (±2 m), ikke avstandspoeng. |
| **Kontrastpar** (samme situasjon, én ting endret) | Svært bra, og billig: én ekstra rad med koordinater. |
| **Sant eller usant om en myte** («siste mann = rødt») | Bra som oppvarming. |
| **Tidslinje** (sorter hendelser) | Finnes allerede i «Sorter rekkefølgen». Lenke dit i stedet for å bygge på nytt. |
| Animerte spillsekvenser | Utsett. Pil for pasning og løp er nok i første utgave. |
| Video/TV-bilder, «var det hands?» fra foto | Frarådes: rettigheter og skjønn. |
| Lange tekstsider | Frarådes. Maks to setninger per kort. |
| Tid, poeng, liv | Frarådes – motarbeider læring og eierens ønske. |

## 4. Første utgave

**Fem leksjoner, ca. 35 situasjoner**, i denne rekkefølgen (hver bygger på den forrige):

1. **Banen** – sett merket: straffemerket, målfeltet, midtlinja; hvor lang er en kamp.
2. **Ute eller inne?** – ball over linja, innkast/målspark/hjørnespark, fem sekunders nedtelling ved sommel (ny 2026/27), keeperens åtte sekunder gir hjørnespark.
3. **Offside** – skrevet ut under.
4. **Frispark, straffe og kort** – inne eller utenfor feltet, direkte/indirekte, åpenbar målsjanse.
5. **Dommerteamet og VAR** – dommeren bestemmer alltid; bare klare og åpenbare feil; mål, straffe, direkte rødt kort og forveksling av spiller; fra 2026/27 også rødt kort etter et klart feil andre gult, og (valgfritt for turneringen) et klart feil hjørnespark.

### Prøveleksjon: Offside

**Koordinater:** x langs banen 0–105 m, y på tvers 0–68 m. Blått lag angriper mot x = 105. Midtlinja er x = 52,5, straffefeltet starter ved x = 88,5, målet står på y = 30,34–37,66. A = angriper, F = forsvarer, K = keeper. «Linja» er offsidelinja (nest siste motspiller).

**Tre kort som dukker opp underveis (etter situasjon 1, 2 og 5):**
- *Posisjon:* Du står i offsideposisjon når du er på motstanderens halvdel og nærmere mållinja enn både ballen og den nest siste motspilleren. Hender og armer teller ikke. På linje er lov.
- *Øyeblikket:* Det som teller er hvor du står idet medspilleren slår ballen – ikke når du får den.
- *Involvert:* Å stå i offsideposisjon er ikke forbudt. Det blir offside først når du spiller ballen, hindrer en motspiller eller drar nytte av en retur.

| # | Oppgave | Oppstilling (x, y) | Fasit | Forklaring |
|---|---|---|---|---|
| 1 | Trykk på spilleren som står i offsideposisjon | Ball/A1 (62, 30). A2 (80, 40), A3 (74, 20). F1 (78, 26), F2 (76, 38), F3 (75, 46), F4 (77, 14), K (103, 34) | A2 | Nest siste motspiller er F1. Linja går ved x = 78. A2 står to meter foran. |
| 2 | Samme pasning. Offside? | Som 1, men A2 (78, 40) | Nei | På linje med nest siste motspiller er ikke offside. |
| 3 | Lang ball over alle. Offside? | Ball/A1 (38, 30). A2 (51, 36). F1–F4 på x = 57–60, K (88, 34) | Nei | A2 sto på egen halvdel da ballen ble slått. Da kan man ikke være offside. |
| 4 | A1 legger ballen bakover til A2, som scorer. Mål? | Ball/A1 (98, 22). A2 (95, 33). F1 (91, 30), F2 (89, 38), K (101, 31) | Mål | A2 er foran forsvarerne, men bak ballen. Da er det ikke offside. |
| 5 | Keeperen har løpt ut. Sett offsidelinja | Ball/A1 (80, 42). A2 (96, 30). K (89, 36), F1 (104, 35), F2 (84, 28), F3 (83, 44) | x = 89 (±2 m). A2 er offside | Linja følger den *nest siste motspilleren*, uansett hvem det er. Her er det keeperen, for F1 står bak ham. |
| 6 | A1 skyter og scorer. A2 står langt ute på kanten. Mål? | Ball/A1 (84, 30). A2 (97, 58). F1 (92, 30), K (103, 34) | Mål | A2 står i offsideposisjon, men gjør ingenting og er ikke i veien. Ingen forseelse. |
| 7 | Samme skudd, men A2 står rett foran keeperen. Mål? | Ball/A1 (84, 30). A2 (100, 35). F1 (93, 32), K (102,5, 34,5) | Offside | A2 stenger utsikten til keeperen og hindrer dermed en motspiller. Indirekte frispark der A2 sto. |
| 8 | Keeperen redder skuddet, returen går til A2, som scorer. Mål? | Ball/A1 (86, 36). A2 (98, 40). F1 (95, 33), K (103, 35) | Offside | A2 sto i offsideposisjon da skuddet gikk, og dro nytte av en redning. En redning «nullstiller» ikke. |

**Bonus (sant/usant):** «Man kan være offside på innkast.» Usant – heller ikke direkte fra målspark eller hjørnespark.
**Visste du at:** Fram til 1925 måtte *tre* motspillere være mellom deg og mållinja. Da kravet ble to, ble det straks scoret flere mål. Først i 1990 ble «på linje» tillatt.

### Skjermen på mobil

Halve banen vises stående med målet øverst (68 m i bredden, 52,5 m i høyden passer et mobilformat); hel bane bare når situasjonen krever det.

```
┌──────────────────────────────┐
│ ←  Offside            3 / 8  │
│ ●●○○○○○○                     │
├──────────────────────────────┤
│        ┌───[ mål ]───┐       │
│     ┌──┴──────K──────┴──┐    │
│     │    straffefelt    │    │
│     └───────────────────┘    │
│                   A2         │
│  F4 ─ ─ F1 ─ ─ ─ ─ ─ ─ ─ ─ ─ │  ← linja tegnes i fasiten
│     A3            F2   F3    │
│                              │
│            A1●  ↗            │
│ ─ ─ ─ ─ ─ midtlinje ─ ─ ─ ─  │
├──────────────────────────────┤
│ Trykk på spilleren som står  │
│ i offsideposisjon            │
│ (eller to–fire svarknapper)  │
├──────────────────────────────┤
│ Riktig! Linja går ved F1.    │
│ A2 står to meter foran.      │
│                  [ Neste → ] │
└──────────────────────────────┘
```

Blå og røde brikker med bokstav (aldri bare farge – fargeblinde), trykkflate minst 44 px, minst 2 m mellom spillere som kan trykkes på.

## 5. Omfang, risiko og hva som bør vente

**Omfang (én person + Claude, januar):**
- Banetegning (`CustomPainter`, hel/halv bane, brikker, piler, trykk → meter): 2–3 økter. Banebakgrunnen i `lib/ui/football.dart` og svarknapper/kort fra quizen gjenbrukes.
- Leksjonsmotor, dataformat (JSON i `assets/`, generert av et skript slik som `tools/make_seed.py`), framgang lokalt, menyflis i `lib/home_screen.dart`: 2–3 økter.
- Innhold: fem leksjoner à 6–8 situasjoner: 3–4 økter. Sju språk via dagens oversettelsesoppsett: 1–2 økter.
- Faktasjekk: én fotballdommer eller regelkyndig leser alle 35 situasjonene (én kveld). Dette bør ikke hoppes over.

**Risiko:**
- **Feil i regelstoffet** svekker hele appens troverdighet. Tiltak: hver situasjon merkes med regelnummer og utgave («Regel 11, 2026/27»), og gjennomgås hver sommer når nye regler trer i kraft 1. juli.
- **Fagspråk på sju språk:** bruk termene forbundene selv bruker (NFF, SvFF, DBU, DFB, RFEF, FFF), ikke direkte oversettelse fra norsk. Trenger morsmålskontroll, som den juridiske teksten.
- **Opphavsrett og varemerker:** Reglene som sådan er fakta og kan forklares fritt *med egne ord og egne tegninger*. Ikke kopier tekst, figurer eller oppsett fra regelboken, og ikke bruk merkene til IFAB, FIFA, UEFA eller forbund. Ikke kall innholdet «offisielt». Navn på spillere, lag og turneringer kan brukes i nøkterne faktasetninger, men uten bilder (unntatt fritt lisensierte), uten å antyde samarbeid og uten nedsettende påstander om navngitte personer. Tas med i den planlagte juridiske gjennomgangen.
- **Omfangsglidning:** fem leksjoner er nok til å teste om folk bruker dette.

**Utsett til etter betatesten:** hands, keeperen som egen leksjon, tabell og turnering, posisjoner og formasjoner, egen historiedel/tidslinje, animasjoner, ordliste, repetisjon med mellomrom utover en enkel «Dagens tre».

## Kilder

- IFAB, regelendringer 2026/27: https://theifab.com/law-changes/latest/
- IFAB, Regel 11 Offside: https://www.theifab.com/laws/latest/offside/
- IFAB, VAR-protokollen: https://www.theifab.com/laws/latest/video-assistant-referee-var-protocol/
- IFAB, regelendringer 2025/26: https://www.theifab.com/law-changes/2025-26/ og https://www.theifab.com/news/the-ifab-tackles-goalkeeper-time-wasting
- IFAB, nyhet om endringene for 2026/27: https://www.theifab.com/news/the-ifab-introduces-further-measures-to-improve-match-flow-and-player-behaviour
- Regelhistorie (1891, 1925, 1970, 1990, 1992, 2012, 2018): https://en.wikipedia.org/wiki/Laws_of_the_Game_(association_football) og https://theifab.com/background

**Ikke verifisert:** IFABs rundskriv 33 og 34 (sommeren 2026) lot seg ikke lese; de presiserer bl.a. VAR-protokollen og bør leses før leksjon 5 skrives. IFABs egne vilkår for gjengivelse av regelboken er ikke lest. Regelhistorien er bare sjekket mot Wikipedia, og påstanden om flere mål etter 1925 er ikke kontrollert mot kilde. De norske fagtermene er ikke sjekket mot NFFs regelbok.
