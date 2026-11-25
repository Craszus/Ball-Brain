<!-- odin:start (Odin skriver mellom disse linjene – skriv egne notater utenfor) -->
# Ball Brain

Dette er et prosjekt fra **Odin**, Jons private AI-assistent. Odin planlegger og følger opp prosjektet; du (Claude) hjelper med programmering, feilsøking og videoredigering her i mappen. Svar på norsk.

- Type: App
- Status: pågår
- Idé: Ball Brain er ikke bare nok en fotballquiz-app.
De fleste fotballquiz-apper tester bare overflatekunnskap — kjente spillere, ferske overganger og grunnleggende historie. Ball Brain går mye dypere. Appen er laget for folk som virkelig elsker og forstår spillet.
Visjonen er å skape den mest komplette plattformen for fotballkunnskap, der brukerne kan teste og utvikle alle sider av sin fotballforståelse:
Kjenne igjen spillere fra bilder
Kjenne fotballhistorien på tvers av epoker
Forstå de faktiske reglene i spillet
Analysere dommer- og VAR-avgjørelser
Vite hvor stadioner og klubber ligger i verden
Konkurrere under press (stresstester og tidsbegrensede utfordringer)
Det som skiller Ball Brain fra andre apper er det sterke sosiale og konkurransepregede laget.
Brukerne skal kunne:
Kjempe i ekte 1v1-kamper
Opprette og bli med i grupper med venner
Se nøyaktig hvor vennene deres ligger på alle highscore-lister
Klatre på nasjonale og globale rangeringer
Samle troféer i både personlig og gruppebasert pokalskap
Den langsiktige visjonen er å bli det naturlige samlingspunktet for fotballkunnskap — et sted der både seriøse fans, vanlige supporters og vennegrupper møtes for å utfordre hverandre, lære og bevise hvem som egentlig kan spillet.
Ball Brain skal føles konkurransepreget, sosialt og givende på samme tid.
Brukerne skal oppleve at fotballkunnskapen deres blir målt, anerkjent og feiret.
- Mål: Lanse MVP (Minimum Viable Product) av Ball Brain på App Store og Google Play med bildesortering, regler-kunnskap, lokal rangering og 1v1-modus innen 30. november 2026.

## Oppgaver (14/39 ferdige) – se ODIN-OPPGAVER.md
**Fase 1: Grunnmur & MVP-prototyp:** ✓ Oppsett Flutter-prosjekt og Supabase-konto; ✓ Design database-schema (brukere, highscores, spørsmål) i Supabase; ✓ Implementer base-API for å hente spørsmål og lagre poeng; ✓ Bygg UI med Flutter for bildesortering (drag-and-drop); ✓ Implementer logikk for regler-quiz og scoring
**Fase 2: Sosialt & Konkurranse:** ✓ Legg til seed-database med ~100 spørsmål fra ulike epoker/regler; ✓ Implementer lokal rangering (leaderboard) per nasjon via Supabase Edge Functions; ✓ Bygg profil-side med visuell trofé-tilstand og highscore-visning; Implementer 1v1-modus med tidsbegrensning og real-time scoring (Supabase Realtime)
**Fase 3: Polering, Testing & Lansering:** Beta-test med 50–100 brukere, samle bugger og fikse UX; Oppsett personvern (GDPR), vilkår, datadeling og monetisering (annonser/premium); App Store Connect / Google Play Console oppsett og lansering
**Fra Claude:** ✓ Personvernerklæring, vilkår og «Slett all min data» i appen (del av #252); Monetisering (annonser/premium) og datadeling – resten av #252; Juridisk gjennomgang av personvern/vilkår og kontaktadresse før lansering; Språkstøtte etter land: norsk, engelsk, svensk, dansk, tysk, spansk, fransk (menyer og seed-spørsmål); Språk: juridisk tekst (personvern/vilkår) på sv/da/de/es/fr, og fagspråk gjennomgått av morsmålsbrukere; Språk: spørsmål og stedsnavn fra Supabase/nye spørsmål må få oversettelser; Flere spørsmål (over 600, 11 temaer) og flere bilder (spillere/målvakter/stadioner) mot repetisjon; Mindre repetisjon: husk viste spørsmål/bilder lokalt, stokk svar og startrekkefølge; Mer spenning: dagens utfordring, «på rad»-merke, vanskelighetsprogresjon og nye bildespørsmål; Faktasjekk av de nye spørsmålene (særlig 2025–26-fakta) av en fotballkyndig før lansering; ✓ Vurder ukentlig/daglig utfordring med egen rangering når Supabase er på plass; ✓ Pushvarsler: Firebase-app og nøkkel (Jon), deretter utgi funksjonen og teste (docs/PUSH.md)

## Verktøy
- **Flutter & Dart**: Kodebasert apputvikling for iOS og Android med én kodebase. Bruk Flutter SDK, Riverpod/Provider for state management.
- **Supabase**: Backend som leverer database (PostgreSQL), autentisering, lagring av bilder og real-time funksjonalitet via Edge Functions.
- **Figma**: Design UI/UX før implementering. Lag prototyper for bildesortering og leaderboard.
- **Google Play Console / App Store Connect**: Plattformene for å distribuere appen til brukerne. Krav: konto, betalingsmetode og testing med beta-programmer.
- **Firebase Performance & Crashlytics**: Overvåke ytelse (lagtid, rendering) og feilrapportering i live-appen for rask retting av bugs.

## Tips
- **Start med én spillmodus**: Fokus på bildesortering og regler-quiz først. Legg til VAR/stadioner i en neste iterasjon for å unngå scope creep.
- **Bygg community tidlig**: La brukere invitere venner via delingslenker allerede i MVP. En aktiv gruppe skaper engasjement og viral spredning.
- **Personvern fra dag én**: Definer hva du samler inn (GDPR), lagre dataene minimalt, og ha en tydelig 'Vilkår'-side. Dette er avgjørende for lansering i Europa.

## Notater
- **Fra Claude – 2026-11-22**: - Flutter-prosjekt opprettet (android/ios) med flutter_riverpod og supabase_flutter.
- Lagt inn supabase/schema.sql (profiles, questions, scores med RLS). Må kjøres i Supabase SQL Editor.
- Neste: Jon oppretter Supabase-konto/prosjekt; deretter base-API (#244) og quiz-logikk (#246).
- **Fra Claude – 2026-11-22 (økt 2)**: - Base-API (#244): `QuestionRepository` henter spørsmål og lagrer poeng via Supabase; faller tilbake til 3 lokale eksempelspørsmål uten Supabase-nøkler.
- Regler-quiz + scoring (#246): modeller, `Scoring` (100 × vanskelighet + tidsbonus opptil 50), Riverpod-kontroller og skjerm. 3 enhetstester grønn
- **Fra Claude – 2026-11-22 (økt 3)**: - Beslutning: utvikle videre uten Supabase; Supabase settes opp og testes med brukere når alt annet er på plass (Logica-oppskriften i docs/SUPABASE.md: eget prosjekt i Europa, schema.sql, anonym innlogging, lokal konfigfil).
- Bildesortering (#245): `ImageSortScreen` med drag-and-drop (ReorderableLi
- **Fra Claude – 2026-11-22 (økt 4)**: - Seed-spørsmål (#247): `tools/make_seed.py` genererer `assets/seed/questions.json` (113 spørsmål: 104 quiz, 9 sortering, kategorier Regler, VM/EM-historie, Klubbfotball, Norge, Stadioner) og `supabase/seed.sql`.
- Appen leser seed-filen offline; med Supabase kjøres `seed.sql` etter `schema.sql`.
- 
- **Fra Claude – 2026-11-22 (økt 5)**: - Profil-side (#249): `ProfileScreen` med statistikk (runder, totalpoeng, beste regler-/sorteringsrunde) og troféskap med 7 troféer (låst/opplåst).
- Statistikken lagres lokalt med shared_preferences (`lib/services/stats.dart`) og oppdateres når en runde er ferdig. Flyttes til Supabase etter innlogg
- **Fra Claude – 2026-11-22 (økt 6)**: - Ny fotballdesign i kode (Figma ikke tilgjengelig herfra): mørkegrønn banebakgrunn, tegnet fotball-logo, gull/grønn palett (lib/ui/).
- Troféer og prestasjoner: tegnet pokal i bronse/sølv/gull med ikon, låst tilstand grå med lås (lib/ui/trophy_badge.dart).
- Avatar og profil: spiller-avatar (hudfar
- **Fra Claude – 2026-11-23**: - Nivåopp-feiring: fullskjerms overlay med konfetti, nivåmerke som spretter inn, tittel på nytt nivå og «Fortsett» (lib/ui/level_up.dart). Vises på resultatskjermen når runden gir et nytt nivå.
- XP-baren på resultatskjermen fylles nå opp fra gammel til ny verdi (og fra 0 ved nivåskifte).
- Egen jub
- **Fra Claude – 2026-11-23 (økt 2)**: - Beskrivelse av spillet og alle menyene for design: docs/SPILL-OG-MENYER.md (skjermer, farger, mål, regler, planlagte skjermer, hva designeren kan lage alternativer for).
- Wikimedia Commons: tools/fetch_commons.py henter stadioner (koordinater + bilde) og spillere med fritt lisensierte bilder (kun
- **Fra Claude – 2026-11-23 (økt 3)**: - Commons-henteren (tools/fetch_commons.py) er rettet: feil logges (api_errors.txt), forsøker på nytt med Retry-After, og bruker Wikidata P18 som reservebilde. Ny kjøring: 37 stadioner og 47 spillere, 9 hoppet over, ingen API-feil.
- Kontrollert: ingen NC/ND/GFDL-lisenser (kun CC BY, CC BY-SA, CC0, 
- **Fra Claude – 2026-11-23 (økt 4)**: - Hovedmenyen implementert etter designbriefen «Premium Nattkamp / Stadion-gull» (eksakte farger, se docs/SPILL-OG-MENYER.md og lib/ui/theme.dart).
- Logoen (fotball + gullhjerne) er lagt inn som assets/brand/logo_mark.png (gjennomsiktig bakgrunn, laget av den leverte logoen). Originalene og mockupe
- **Fra Claude – 2026-11-23 (økt 5)**: - Geografi-quiz: kart med tapp for nål, «Bekreft plassering», resultat med «Deg»/«Riktig»-nåler, stiplet sirkel, avstand og XP (0–25 km = 500 … >1500 km = 25). Zoom (klyp, +/−, dobbelttrykk), «Vis hele verden», timeren stopper aldri. Kart: Esri-satellitt farget mørkegrønt.
- «Velg din avatar»: seks 
- **Fra Claude – 2026-11-23 (økt 6)**: - Landegrenser: Natural Earth 110m (offentlig eiendom) lagt inn som assets/geo/countries.geojson (192 KB). Kartet er nå eget mørkt verdenskart (land + gull grenser, uten Antarktis); satellittbakgrunn tones inn først ved zoom ≥ 4,5.
- Klubblogoer brukes ikke (varemerker/opphavsrett). Spørsmålskortet 
- **Fra Claude – 2026-11-23 (økt 7)**: - Kartleverandør: Esri fjernet. Bruker MapTiler «Backdrop Dark» (mørkt kart uten stedsnavn) via `--dart-define=MAP_TILE_KEY=...`. Uten nøkkel vises eget Natural Earth-kart med begrenset zoom (maks 7). Krever MapTiler-konto og betalt plan (Flex) for kommersiell bruk – Jon må opprette konto og nøkkel.
- **Fra Claude – 2026-11-23 (økt 8)**: - Kart uten lisens/nøkkel: byttet fra MapTiler til OpenFreeMap (OpenStreetMap-data, åpne vektorfliser, ingen konto, kommersiell bruk tillatt, krever kildehenvisning «OpenFreeMap / OpenMapTiles / OpenStreetMap» – vises i kartets ⓘ). Egen mørk stil uten stedsnavn (lib/geo/vector_map.dart). Gull landeg
- **Fra Claude – 2026-11-23 (økt 9)**: - Innebygd kart (virker uten nett): to detaljnivåer fra Natural Earth (offentlig eiendom): verdenskart 50m (424 KB) og nærkart 10m (2,2 MB, byttes inn ved zoom ≥ 3,5). Genereres med tools/make_world_maps.py → assets/geo/world_far.json / world_near.json. Maks zoom 9 (regioner og byer, ikke gater).
- 

## Slik jobber vi
- Hold **ODIN-OPPGAVER.md** oppdatert: kryss av `[x]` når en oppgave er ferdig, og legg nye oppgaver nederst som `- [ ] tekst`. Ikke endre eller fjern `(#nummer)`.
- **PROJECT.md** er prosjektets felles oversikt (mål, plan, status). Skriv nye beslutninger som punkter under «## Beslutninger» nederst – Odin henter dem automatisk.
- Mappen **inbox/** er innboksen: filer Jon legger der (bilder, dokumenter) hører til prosjektet. **filer/** har kopier av bildene og dokumentene Jon har lagt inn i Odin – PROJECT.md lister dem alle, så les den for å vite hvilke filer som finnes.
- Etter hver arbeidsøkt: legg til en kort oppføring i **ODIN-LOGG.md** med overskriften `## ÅÅÅÅ-MM-DD` og punkter for hva som er gjort, beslutninger og neste steg.
- Jon trykker «Hent tilbake fra Claude» i Odin, så havner avkrysningene, nye oppgaver og loggen i prosjektet.
- Skriv aldri passord, nøkler eller private opplysninger i disse filene.
<!-- odin:end -->
