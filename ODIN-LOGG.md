# Logg – Ball Brain

Claude: legg til en oppføring etter hver arbeidsøkt (`## ÅÅÅÅ-MM-DD`, så punkter).

## 2026-11-22
- Flutter-prosjekt opprettet (android/ios) med flutter_riverpod og supabase_flutter.
- Lagt inn supabase/schema.sql (profiles, questions, scores med RLS). Må kjøres i Supabase SQL Editor.
- Neste: Jon oppretter Supabase-konto/prosjekt; deretter base-API (#244) og quiz-logikk (#246).

## 2026-11-22 (økt 2)
- Base-API (#244): `QuestionRepository` henter spørsmål og lagrer poeng via Supabase; faller tilbake til 3 lokale eksempelspørsmål uten Supabase-nøkler.
- Regler-quiz + scoring (#246): modeller, `Scoring` (100 × vanskelighet + tidsbonus opptil 50), Riverpod-kontroller og skjerm. 3 enhetstester grønne.
- Supabase kobles på med `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
- Neste: Jon oppretter Supabase-prosjekt og kjører schema.sql; så innlogging (kreves for å lagre poeng), seed-spørsmål (#247) og bildesortering (#245).

## 2026-11-22 (økt 3)
- Beslutning: utvikle videre uten Supabase; Supabase settes opp og testes med brukere når alt annet er på plass (Logica-oppskriften i docs/SUPABASE.md: eget prosjekt i Europa, schema.sql, anonym innlogging, lokal konfigfil).
- Bildesortering (#245): `ImageSortScreen` med drag-and-drop (ReorderableListView), 2 eksempeloppgaver offline. Støtter bilde-URL per element senere.
- Startskjerm med valg mellom regler-quiz og bildesortering.
- Neste: seed-spørsmål (#247) som lokal JSON, profil-side (#249), lokal highscore.

## 2026-11-22 (økt 4)
- Seed-spørsmål (#247): `tools/make_seed.py` genererer `assets/seed/questions.json` (113 spørsmål: 104 quiz, 9 sortering, kategorier Regler, VM/EM-historie, Klubbfotball, Norge, Stadioner) og `supabase/seed.sql`.
- Appen leser seed-filen offline; med Supabase kjøres `seed.sql` etter `schema.sql`.
- Rediger spørsmål i skriptet, ikke i de genererte filene. Fakta er skrevet fra hukommelsen: bør faktasjekkes før lansering (særlig Rosenborg–Milan 1996).
- Neste: profil-side (#249) med lokal highscore, deretter innlogging/Supabase.

## 2026-11-22 (økt 5)
- Profil-side (#249): `ProfileScreen` med statistikk (runder, totalpoeng, beste regler-/sorteringsrunde) og troféskap med 7 troféer (låst/opplåst).
- Statistikken lagres lokalt med shared_preferences (`lib/services/stats.dart`) og oppdateres når en runde er ferdig. Flyttes til Supabase etter innlogging.
- Merk: «visuell trofé-tilstand» er enkel nå (ikon låst/gull); bedre grafikk kan komme med Figma-design.
- Neste: innlogging (anonym) + Supabase-oppsett, lokal rangering (#248), 1v1 (#250).

## 2026-11-22 (økt 6)
- Ny fotballdesign i kode (Figma ikke tilgjengelig herfra): mørkegrønn banebakgrunn, tegnet fotball-logo, gull/grønn palett (lib/ui/).
- Troféer og prestasjoner: tegnet pokal i bronse/sølv/gull med ikon, låst tilstand grå med lås (lib/ui/trophy_badge.dart).
- Avatar og profil: spiller-avatar (hudfarge, frisyre, hårfarge, drakt, mønster, nummer), kallenavn (3–16 tegn) og land, lagret lokalt (lib/services/profile.dart, edit_profile_screen.dart). Land bruker ISO-kode som passer profiles.country_code.
- XP og nivåer: XP = totalpoeng, nivå n starter på 250·(n−1)·n XP, 10 titler fra Benkesliter til Legende. XP-bar på startskjerm, profil og resultatskjerm.
- Innstillinger: lyd av/på, vibrasjon av/på, nullstill fremgang (med bekreftelse).
- Lyder: korte effekter (riktig, feil, fulltid, trykk) generert av tools/make_sounds.py; lagt i assets/sounds/. Lyd er ikke hørt/testet av meg (kun kode og at filene finnes).
- 7 tester grønne, flutter analyze ren.
- Neste: innlogging + Supabase, lokal rangering (#248), 1v1 (#250). Kallenavn bør sjekkes mot banneordsfilter på serveren (se Logica docs/SUPABASE.md).

## 2026-11-23
- Nivåopp-feiring: fullskjerms overlay med konfetti, nivåmerke som spretter inn, tittel på nytt nivå og «Fortsett» (lib/ui/level_up.dart). Vises på resultatskjermen når runden gir et nytt nivå.
- XP-baren på resultatskjermen fylles nå opp fra gammel til ny verdi (og fra 0 ved nivåskifte).
- Egen jubellyd (levelUp.wav) spilles ved nivåopp i stedet for vanlig fulltid-lyd. `StatsController.record` returnerer om nivået økte.
- Testet i nettleser (XP satt til 499, spilte en runde): feiringen kom opp med riktig nivå. 10 tester grønne (inkl. widget-test av feiringen), flutter analyze ren.
- Ikke testet: lyden (ikke hørt), og at feiringen ser bra ut på ekte telefon.

## 2026-11-23 (økt 2)
- Beskrivelse av spillet og alle menyene for design: docs/SPILL-OG-MENYER.md (skjermer, farger, mål, regler, planlagte skjermer, hva designeren kan lage alternativer for).
- Wikimedia Commons: tools/fetch_commons.py henter stadioner (koordinater + bilde) og spillere med fritt lisensierte bilder (kun CC BY, CC BY-SA, CC0, PD; fotograf/lisens/kilde lagres). Første kjøring ga 26 stadioner og 21 spillere; 46 ble hoppet over (assets/media/skipped.txt). Mange hoppet over ser ut som nettverks-/grensefeil og ikke manglende bilder (ikke bekreftet): skriptet må få bedre feillogging og kjøres på nytt.
- Ikke bygget ennå: stadion-quiz, gjett spilleren, kart-utfordring, bildekreditering/ⓘ i appen.

## 2026-11-23 (økt 3)
- Commons-henteren (tools/fetch_commons.py) er rettet: feil logges (api_errors.txt), forsøker på nytt med Retry-After, og bruker Wikidata P18 som reservebilde. Ny kjøring: 37 stadioner og 47 spillere, 9 hoppet over, ingen API-feil.
- Kontrollert: ingen NC/ND/GFDL-lisenser (kun CC BY, CC BY-SA, CC0, public domain), alle har fotograf og kildeside, koordinatene ser riktige ut ved stikkprøve (Anfield, Camp Nou, Ullevaal, Lusail, Maracanã).
- Hoppet over (kan rettes): Mestalla, Parc des Princes, Estádio José Alvalade, La Bombonera, Estadio Centenario (mangler koordinater på Wikipedia-siden, kan hentes fra Wikidata P625 eller legges inn manuelt), Stadio Olimpico (feil sidetittel), Xavi og Luis Suárez (feil sidetittel/ingen bilde), Federico Valverde (bildet er ikke portrett).
- IKKE sjekket: at spillerbildene faktisk er tett beskårede portretter uten klubblogo/draktsponsor. Må ses på før bruk i appen. Skjermer for bildene, ⓘ-kreditering og kart er ikke bygget.

## 2026-11-23 (økt 4)
- Hovedmenyen implementert etter designbriefen «Premium Nattkamp / Stadion-gull» (eksakte farger, se docs/SPILL-OG-MENYER.md og lib/ui/theme.dart).
- Logoen (fotball + gullhjerne) er lagt inn som assets/brand/logo_mark.png (gjennomsiktig bakgrunn, laget av den leverte logoen). Originalene og mockupen ligger i design/.
- Nytt: gull nivåkort med LVL-skjold + XP-bar + % (lib/ui/level_card.dart), mørke ikonbrikker med gullkant, gress-tekstur og vignett på bakgrunnen, topplinje med avatar og tannhjul.
- Global stil: kort har radius 16, 1 px kant og skygge; knapper radius 16. Konfetti bruker bare gull/hvit/grønn.
- Mockupen viser «LVL 7» sammen med «Benkesliter» og 650/1500 XP. Det stemmer ikke med nivåkurven vår (650 XP = nivå 2, «Innbytter»). Appen viser ekte verdier.
- Ikke gjort: app-ikon i Android/iOS (kilde ligger i design/app-ikon-kilde.png), restyling av regler-quiz/profil/troféer i samme stil (briefen dekket bare hovedmenyen).
- 12 tester grønne (inkl. hovedmeny i 375x812 og eksakte farger), flutter analyze ren.

## 2026-11-23 (økt 5)
- Geografi-quiz: kart med tapp for nål, «Bekreft plassering», resultat med «Deg»/«Riktig»-nåler, stiplet sirkel, avstand og XP (0–25 km = 500 … >1500 km = 25). Zoom (klyp, +/−, dobbelttrykk), «Vis hele verden», timeren stopper aldri. Kart: Esri-satellitt farget mørkegrønt.
- «Velg din avatar»: seks ulike avatarer (2×3), spillernavn, nivåkort og «Bekreft». Vises første gang appen åpnes; kan åpnes fra profilen.
- «Min Avatar» (redigering) i samme stil, med «Lagre avatar».
- Tekst endret til «Test regelkunnskapen din». App-ikon generert (Android adaptive + iOS) fra logoen.
- Alle 20 tester grønne, analyze uten feil.
- Åpent: gull landegrenser krever Natural Earth GeoJSON (trenger Jons ok for nedlasting); klubblogoer mangler (initialer brukes); kartfliser må byttes til lisensiert leverandør (MapTiler/Stadia/Mapbox) før lansering; timer 60 s per spørsmål er en antakelse.
- Neste: bilder av stadioner/spillere med bildekreditering (ⓘ), Supabase, rangering, 1v1.

## 2026-11-23 (økt 6)
- Landegrenser: Natural Earth 110m (offentlig eiendom) lagt inn som assets/geo/countries.geojson (192 KB). Kartet er nå eget mørkt verdenskart (land + gull grenser, uten Antarktis); satellittbakgrunn tones inn først ved zoom ≥ 4,5.
- Klubblogoer brukes ikke (varemerker/opphavsrett). Spørsmålskortet viser hele klubbnavnet som tekst.
- Avatarer: kodetegnede avatarer duger ikke visuelt. Beslutning: lag ferdige avatarbilder (30 stk) med Odin og legg dem i assets/avatars/; appen kobles til bildene når de finnes.

## 2026-11-23 (økt 7)
- Kartleverandør: Esri fjernet. Bruker MapTiler «Backdrop Dark» (mørkt kart uten stedsnavn) via `--dart-define=MAP_TILE_KEY=...`. Uten nøkkel vises eget Natural Earth-kart med begrenset zoom (maks 7). Krever MapTiler-konto og betalt plan (Flex) for kommersiell bruk – Jon må opprette konto og nøkkel.
- Geografi-spørsmål viser nå typen: KLUBB/STADION/ARENA og «Hvor ligger klubben Chelsea?» med «Hjemmebane: Stamford Bridge».

## 2026-11-23 (økt 8)
- Kart uten lisens/nøkkel: byttet fra MapTiler til OpenFreeMap (OpenStreetMap-data, åpne vektorfliser, ingen konto, kommersiell bruk tillatt, krever kildehenvisning «OpenFreeMap / OpenMapTiles / OpenStreetMap» – vises i kartets ⓘ). Egen mørk stil uten stedsnavn (lib/geo/vector_map.dart). Gull landegrenser fra Natural Earth ligger oppå. Uten nett vises Natural Earth-fallback.
- Pakker: vector_map_tiles, vector_tile_renderer, http.
- Risiko: OpenFreeMap drives av én utvikler uten SLA; ved stor trafikk bør vi selv-hoste fliser (planet-fil + gratis server) eller sponse dem.

## 2026-11-23 (økt 9)
- Innebygd kart (virker uten nett): to detaljnivåer fra Natural Earth (offentlig eiendom): verdenskart 50m (424 KB) og nærkart 10m (2,2 MB, byttes inn ved zoom ≥ 3,5). Genereres med tools/make_world_maps.py → assets/geo/world_far.json / world_near.json. Maks zoom 9 (regioner og byer, ikke gater).
- Fjernet OpenFreeMap, MapTiler og Esri samt pakkene vector_map_tiles, vector_tile_renderer og http: ingen kartleverandør, ingen lisens, ingen nettavhengighet i geografi-quizen.
- Gull landegrenser er nå finere (50m/10m i stedet for 110m).

## 2026-11-23 (økt 10)
- Hjelpelag i nærkartet (Natural Earth, offentlig eiendom, uten navn): innsjøer, store elver, fylkes-/delstatsgrenser (vises fra zoom 4,5) og byer over 1 million som gule prikker. assets/geo/world_extra.json (3 MB), laget av tools/make_world_maps.py.

## 2026-11-23 (økt 11)
- Kart-ytelse: tegner bare det som er synlig (omkrets per form, viewport-utvalg), høyere forenkling og RepaintBoundary. Regiongrenser først fra zoom 5.
- «Bildesortering» omdøpt til «Sorter rekkefølgen» (ingen bilder). Kortene dras nå i hele kortet (ReorderableDragStartListener) – fikser at de ikke lot seg flytte på telefon.
- Geografi: helt feil (over 1500 km) gir 0 XP.
- Valgmeny før spill: Regler-quiz (Alt/Regler/VM/EM/Klubbfotball/Stadioner/Norge) og Geografi-quiz (Alt/Klubber/Stadioner). «Gjett spilleren» finnes ikke ennå.
- Profil bare via avataren (avatar, navn, land, rediger). Gult nivåkort åpner «Statistikk og troféer». «Profil og trofeer»-kortet fjernet.
- Tekst midtstilt i knapper/bokser (modus-kort, svar, spørsmålskort).
- Sortering uten årstall: alternativene viser ikke lenger år (VM-finaler som «Brasil – Italia», Ballon d'Or-vinnere uten år osv.), så man må kunne historien i stedet for å sortere tall. Nye oppgaver: stadionkapasitet og antall Premier League-titler (11 sorteringsoppgaver, 115 spørsmål totalt).

## 2026-11-23 (økt 12)
- «Gjett fra bilde»: valgmeny Alt / Gjett spilleren / Gjett stadionet. 10 bilder per runde, 4 alternativer, poeng etter tid, riktig/feil vises ved svar. Bilder fra Wikimedia Commons (47 spillere, 37 stadioner) hentes over nett. ⓘ på bildet viser tittel, fotograf og lisens med lenker; «Bildekreditering» i innstillinger lister alle (lib/media/, lib/ui/credited_photo.dart, lib/quiz/photo_quiz_screen.dart).
- Avatarer: appen støtter nå ferdige bilder (assets/avatars/avatar_NN.png, gullkantsirkel legges på av appen). Brief til Odin: docs/AVATAR-BRIEF.md. Bildene finnes ikke ennå – til da brukes de tegnede avatarene.
- Åpent: spillerutsnittene (beskjæring rundt ansiktet) er ikke gjennomgått for logoer/sponsorer; 9 spillere/stadioner hoppet over pga. lisens (se assets/media/skipped.txt); bildene krever nett.
- Fikset «kunne ikke laste bildet» på telefon: release-bygget manglet INTERNET-tillatelse i Android-manifestet (lagt til). Appnavnet på Android er nå «Ball Brain».
- Ansiktsutsnitt: tools/face_crops.py finner ansiktet i hvert spillerbilde (OpenCV) og lagrer utsnittet (cx, cy, s) i assets/media/players.json; appen viser nøyaktig det utsnittet. Gjennomgått på kontaktark; 5 rettet for hånd. Steven Gerrard fjernet (sponsorlogoer i bakgrunnen). Bildestørrelsene i json rettet til faktisk størrelse (960 px). 46 spillere gjenstår.
- Bilder offline: 46 spillerbilder (beskåret rundt ansiktet, 640 px) og 37 stadionbilder (900 px) ligger nå i appen (assets/media/img/, 8,9 MB) – ingen nett nødvendig. Laget med tools/bundle_media.py. Kreditering vises fortsatt via ⓘ og Bildekreditering.

## 2026-11-23 (økt 13)
- ⓘ på bilder er mindre (24 px) og ligger øverst til høyre.
- Poeng nedjustert: riktig svar = 20 × vanskelighet + tidsbonus opptil 10 (før 100 og 50). Geografi: 100/70/40/20/0 (før 500/350/200/100/0). En runde gir nå ca. 150–500 XP.
- Ny nivåkurve (levelThresholds i lib/services/levels.dart): 300, 900, 2 400, 5 400, 11 000, 21 000, 38 000, 68 000, 125 000 XP for nivå 2–10. Hvert steg blir tyngre enn forrige; Legende (nivå 10) krever 125 000 XP. Etter det kan man samle poeng uendelig; kortet viser «X XP · høyeste nivå».
- Troféterskler justert til de nye poengene (Regelekspert 400, Tidslinje-mester 300).

## 2026-11-23 (økt 14)
- Bildefeilen («Kunne ikke laste bildet»): innpakkingsskriptet kunne ikke skrive filer med æøå/aksenter i navnet (cv2 feilet stille). Rettet: ascii-filnavn og sikker skriving; appen faller tilbake til nettbildet hvis filen mangler.
- Flere spillere: 133 spillere (26 målvakter) og 37 stadioner, alle bundet inn i appen (16 MB). Nye valg i «Gjett fra bilde»: Målvakter og Hvilket land?. Fjernet bilder med synlige sponsorlogoer/dårlig utsnitt (bl.a. Gerrard, Gakpo, Cafu, Szczęsny, Raúl, Puyol, Riise, James Rodríguez, Donnarumma, Nyland). Hoppet over pga. lisens: se assets/media/skipped_extra.txt.
- Verktøy: tools/more_players.py (hent flere), tools/face_crops.py (ansiktsutsnitt, kun nye), tools/bundle_media.py (pakk inn).
- Hovedmenyen: kortene viser bare tittel. Forklaringene (f.eks. «Test regelkunnskapen din») står øverst i valgmenyen inne i hvert spill.
- Hovedmenyen: bare de fire spillknappene er gjort smalere og lavere (liten ikonbrikke, smalere bredde) så alt får plass uten scrolling på ca. 760 dp høyde. Toppstreken med avatar/tannhjul, logo, tittel og gult XP-kort er som før. Valgmenyene har også smalere knapper.
- Hovedmenyen: de fire spillknappene fyller nå hele plassen fra det gule XP-kortet og ned til bunnen av skjermen (like høye, full bredde, vanlig størrelse på ikon og tekst). Toppstrek, logo, tittel og XP-kort er uendret.
- Regler og forklaringer er flyttet fra hovedmenyen inn i menyene: boksen «Slik fungerer det» (poeng, tid, kart, kreditering) i Regler-quiz, Gjett fra bilde og Geografi-quiz. «Sorter rekkefølgen» har fått en startmeny med regler.
- Ny poengmodell: riktig svar +2, feil svar −1 (regler, bildequiz, sortering). Geografi: 0–25 km +5, 25–100 +3, 100–500 +2, 500–1500 +1, lenger unna eller ingen nål −1. Man faller aldri under starten av nivået man har nådd (applyPoints i levels.dart).
- Nivåkurven skalert til de nye poengene: 20, 60, 160, 360, 730, 1 400, 2 500, 4 500, 8 300 XP for nivå 2–10 (Legende). Poeng kan samles uendelig etter det. Troféterskler justert (Hundrelappen 100, Ballkjenner 1 000, Regelekspert 16, Tidslinje-mester 12). Forklaringene i menyene er oppdatert.
- Nivåkurve justert: nivå 2 = 50 XP, Legende (nivå 10) = 15 000 XP. Mellomtrinn: 120, 250, 500, 1 000, 2 000, 4 000, 7 500 XP (hvert steg tyngre enn forrige).

## 2026-11-23 (økt 15)
- 30 ferdige avatarer laget med ComfyUI (Krea 2 Turbo, RTX 4090) i 3D-/Pixar-stil: varierte hudtoner, frisyrer, drakter, kjønn og alder; ingen tekst eller logoer. Lagt i assets/avatars/avatar_01..30.png (512 px, 8,6 MB). Appen bruker dem automatisk i «Velg din avatar» og «Min Avatar» (gullkantsirkelen tegnes av appen). Velgeren har navn, nivå og «Bekreft» fast nederst, og avatarene i et rullbart rutenett over.
- Prompt og seeds ligger i scratchpad-skriptet gen_avatars.py (Krea 2 Turbo, seed 1000+nummer); kan flyttes til tools/ ved behov.
- 15 nye avatarer (nr. 31–45): 12 barn under 13 år (Krea 2 Turbo) og 3 familieavatarer i samme stil laget fra Jons bilder av datteren, Jon (med caps) og sønnen (Qwen Image 2.1 bilderedigering, lokalt i ComfyUI; bildene forlot ikke maskinen). Totalt 45 avatarer (13 MB). OBS: nr. 31–33 ligner ekte personer – vurder å fjerne dem fra offentlig utgivelse (assets/avatars/avatar_31–33.png).

## 2026-11-24
- Gullring (lib/ui/gold_ring.dart) lagd om etter mockupen: tynn, flat gullring med tynne delte buer utenfor og kuler i ulik størrelse. Brukes rundt alle avatarer (inkl. hovedmenyen) og trofeer (bronse/sølv/gull).
- Ny avatarvelger: karusell (blar sidelengs, valgt avatar vokser) med filter Alle/Voksne/Barn og «Tilfeldig». Brukes ved første oppstart og i «Rediger profil».
- 32 nye Pixar-lignende trofeer laget i ComfyUI (assets/trophies/), vist i ringer. Trofeskapet er delt i grupper: Generelt, Nivåer, Regler, Sortering, Bilde, Geografi og 1v1.
- Statistikk utvidet per spillmodus (runder, beste, perfekte runder) og 1v1-tellere; 5 PVP-trofeer er låst til 1v1 finnes.
- Neste: 1v1-modus (#250, Supabase Realtime) – avklar om første versjon skal være lokal/hot-seat. Avatar 31–33 ligner ekte personer: fjern før offentlig lansering.
- Nivåskjold: ti unike skjold (assets/shields/lvl_01–10), laget i ComfyUI ut fra skjold 1 – fra enkelt gult til dypt gull med stjerne, vinger, laurbær, krone, edelstener og krone med diamanter på nivå 10 (uten glød og flammer). Nivåtallet legges oppå i Flutter (LevelShield).
- Geografi-lyder: fire nye lyder etter poeng (5/3/2/1 poeng) og feil-lyd bare ved −1 (tidligere sjekket den gamle poenggrensen, derfor feil lyd). Genereres av tools/make_sounds.py.
- Kartknappene +/− ligger nå nederst midt; «Vis hele verden» øverst til venstre. Land-feltet i profilen er midtstilt.

## 2026-11-24 (økt 2)
- Personvern og vilkår: nye skjermer (lib/legal_screens.dart) som beskriver hva som lagres (kallenavn, land, avatar, poeng), hvor, hvem som ser det, barn, rettigheter og lovvalg. Åpnes fra Innstillinger, og lenkes fra «Velg din avatar» ved første oppstart.
- «Slett all min data» i Innstillinger: tømmer profil, avatar, innstillinger og statistikk lokalt, og starter onboarding på nytt. Egen «Nullstill fremgang» finnes fortsatt.
- 3 nye tester (test/legal_test.dart); alle 26 tester grønne, flutter analyze rent.
- Neste: når Supabase kommer må «Slett all min data» også slette raden på serveren, og teksten må vurderes juridisk (kontaktadresse, aldersgrense). Monetisering gjenstår under #252. Avatar 31–33 (deg og barna) avgjøres her.

## 2026-11-24 (økt 3)
- Språk etter land: appen får språk ut fra landet i profilen (NO norsk, SE svensk, DK dansk, DE/AT/CH tysk, ES/MX/AR/CO/CL spansk, FR fransk, ellers engelsk); før profilen er lagret brukes telefonens språk. Eget valg i Innstillinger → Språk (eller «Automatisk»).
- Teknikk: egen enkel løsning uten kodegenerering. `Text` i lib/l10n/l10n.dart erstatter Flutters Text og slår opp teksten (norsk er nøkkel) i assets/i18n/<språk>.json, med maler ({}) for tekster med tall/navn, og engelsk som reserve. MaterialApp får også språk (flutter_localizations) så «Tilbake» o.l. følger med.
- Alt er oversatt: menyer, innstillinger, troféer, nivåer, avatar-valg, geografi og alle 115 seed-spørsmål med svar. Navn på spillere, klubber og byer er ikke oversatt. Personvern og vilkår er bare på norsk og engelsk (øvrige språk viser engelsk).
- Oversettelsene lages i tools/i18n_ui.py og tools/i18n_questions.py; kjør `python tools/make_i18n.py` etter endringer. Ny norsk tekst i koden uten oversettelse vises på norsk.
- 31 tester grønne, flutter analyze rent. Ikke prøvd på telefonen (telefonen var ikke koblet til); APK er bygget.
- Neste: prøv språkene på telefonen (særlig lange tekster som kan bli kuttet), la morsmålsbrukere lese gjennom, og oversett juridisk tekst til de andre språkene.

## 2026-11-24 (økt 4)
- Mindre repetisjon (tilbakemelding fra testere): 618 spørsmål (før 115): 584 quiz + 34 sortering i 11 temaer. Nye temaer: Ligaer, Spillere og rekorder, Trenere, Kvinnefotball, Visste du at?. Alle oversatt til 6 språk (mange som maler i tools/i18n_questions.py). make_seed.py sjekker nå fasit, 2–4 alternativer og duplikater, og gir hvert spørsmål en fast `key`; make_i18n.py feiler hvis et spørsmål mangler oversettelse.
- Rettet faktafeil: Rosenborg slo Milan 2–1 på San Siro i 1996 (ikke Lerkendal).
- Bilder: 264 spillere (før 133), av dem 56 målvakter (før 26) og 8 kvinner; 132 stadioner (før 37). Alle CC BY/BY-SA/CC0/PD/«Attribution» fra Commons, fotograf og lisens lagret. Gått gjennom på kontaktark: 38 spillere og 12 stadioner fjernet (logoer/sponsorer, dårlig utsnitt, barn i bakgrunnen, usikker person). Hoppet over: se assets/media/skipped_extra.txt og skipped_stadiums.txt (10 spillere fikk ikke pakket inn pga. Wikimedia 429 – kan kjøres på nytt). Geografi-quizen har nå 132 steder. Assets totalt ca. 61 MB.
- Repetisjon: appen husker viste spørsmål/bilder/steder lokalt (lib/services/seen_history.dart, shared_preferences) og trekker uviste først til alt er brukt. Svaralternativene stokkes hver gang, og sorteringskortene starter i tilfeldig rekkefølge.
- Mer spenning (poeng/nivåer/troféer uendret): «Dagens utfordring» (10 spørsmål, like for alle samme dag), «3 PÅ RAD!»-merke, lett→vanskelig i hver runde, «Alt» blander temaene jevnt, nye bildespørsmål for stadioner (land og hjemmeklubb), kvinner og menn blandes ikke i svaralternativene.
- 41 tester grønne (nye i test/content_test.dart), flutter analyze rent. Ikke prøvd på telefon.
- Neste: fotballkyndig faktasjekk av nye spørsmål, hent de 10 manglende spillerbildene, vurder egen rangering for dagens utfordring når Supabase finnes.

## 2026-11-24 (økt 5)
- Beslutning: ingen kvinnefotball i spillet. Fjernet temaet «Kvinnefotball» (24 spørsmål, også ett i Norge-temaet), 8 kvinnelige spillerbilder og valget på hovedmenyen. Nå 593 spørsmål og 256 spillerbilder. analyze rent, 41 tester grønne.

## 2026-11-24 (økt 6)
- Supabase koblet til: prosjekt i London (eu-west-2), skjema kjørt (profiles, questions, scores med RLS), anonym innlogging slått på, rettigheter gitt kun til `authenticated`, slettepolicyer for egen profil/score. Kallenavn er ikke lenger unikt.
- Appen logger inn anonymt ved oppstart, lagrer kallenavn og land i `profiles` (lib/services/cloud.dart) og poeng i `scores`. «Slett all min data» sletter nå også serverraden (#243). Alt er best effort: uten nett eller nøkler virker appen som før.
- Spørsmålene leses fortsatt fra seed-filen (bryter `_serverQuestions` i question_repository.dart); seed.sql er ikke lastet opp.
- Konfig ligger lokalt i supabase.env.json (ikke i ODIN-filene). Kjør: flutter run --release --dart-define-from-file=supabase.env.json
- Verifisert mot serveren: anonym bruker kan lagre egen profil/poeng og slette dem, men ikke skrive poeng for andre.
- Neste: nasjonal rangering (#248) via view/Edge Function, vise vennenes plassering, evt. flytte statistikk til serveren.

## 2026-11-24 (økt 7)
- Rangering (#248): ny skjerm (lib/leaderboard_screen.dart) med fane for landet ditt og Verden, topp 50 etter samlet poengsum, egen plassering uthevet (og vist under listen hvis du ikke er på topp 50). Åpnes med pokalknappen ved siden av tannhjulet på hovedmenyen.
- Server: funksjonene `leaderboard` og `leaderboard_me` (kun innloggede). `scores.mode` godtar nå alle spillmoduser.
- Alle moduser (regler, sortering, bilde, geografi) sender poeng til serveren via Stats.record (Cloud.submitScore). Verifisert mot serveren med testbrukere (ryddet bort etterpå).
- Svakhet: klienten kan i prinsippet sende falske poeng. Før lansering bør poeng valideres på serveren (Edge Function) eller begrenses per runde.
- Neste: gruppe/venner med egen rangering, evt. ukentlig/daglig liste; flytte statistikk til serveren.

## 2026-11-24 (økt 8)
- Grupper med venner: fanen «Venner» i Rangering (lib/groups_view.dart). Lag en gruppe (får en seks-tegns invitasjonskode), bli med med kode, se gruppens rangering etter samlet poengsum, kopier invitasjon og forlat gruppen. Maks 10 grupper per bruker og 50 medlemmer per gruppe; tom gruppe slettes automatisk.
- Server: tabellene `groups` og `group_members` (RLS på, ingen direkte tilgang) og funksjonene create_group, join_group, leave_group, my_groups og group_leaderboard (security definer; kun medlemmer ser en gruppes rangering). Sletter du profilen din forsvinner medlemskapene automatisk.
- Verifisert mot serveren med tre testbrukere (lage, bli med, feil kode, utenforstående ser ingenting, forlate, opprydding). 41 tester grønne, analyze rent.
- Neste: dele invitasjon via telefonens delemeny (krever share_plus), «se hvor vennene ligger på alle lister» (#-vision), egen dagslister for gruppen, og server-validering av poeng.

## 2026-11-24 (økt 9)
- Poengvalidering på serveren: klienter kan ikke lenger skrive rett i `scores` (insert-rettighet og policy fjernet). Poeng sendes via funksjonen `submit_score(modus, poeng)` som sjekker: kjent spillmodus, poeng mellom 1 og makspoeng for modusen (20 for regler/sortering/bilde, 50 for geografi), minst 20 sekunder siden forrige runde og maks 150 runder per døgn.
- Verifisert mot serveren: direkte insert avvist, for høye poeng, ukjent modus, 0 poeng og for rask innsending avvist; gyldige runder lagret.
- Begrensning: serveren kjenner ikke svarene (spørsmålene ligger i appen), så en som kjenner API-et kan fortsatt sende maks poeng for hver runde, men bare ca. 3 runder i minuttet og 150 per døgn. Full sikring krever at spørsmål og fasit sjekkes på serveren (spørsmål i Supabase + Edge Function), særlig før 1v1.
- Appen sender poeng via Cloud.submitScore; gamle saveScore er fjernet.

## 2026-11-24 (økt 10)
- Serverstyrt poengberegning for regler-quiz og sortering: appen sender svarene (valgt tekst pr. spørsmålsnøkkel), og funksjonen `submit_round` på serveren regner ut poengene selv (+2 riktig, −1 feil). Valgt løsning: Postgres-funksjon i stedet for Edge Function (samme sikkerhet, atomisk lagring, ingen egen utrulling).
- Fasiten ligger som hash (10 tegn av md5(nøkkel:riktig svar)) i `quiz_answers` – klienter kan ikke lese den, og svaret står ikke i klartekst. Genereres med tools/make_answers.py (supabase/answers.compact.txt/answers.sql); skjema og funksjoner i supabase/validate_rounds.sql. Må lastes på nytt når spørsmål endres.
- Regler: ukjent spørsmål/feil modus avvises, 1–12 spørsmål unike pr. runde, samme spørsmål gir poeng bare én gang pr. døgn, minst 20 s mellom runder, maks 150 runder pr. døgn.
- Geografi og bildequiz bruker fortsatt `submit_score` med tak (20/50 pr. runde); serverstyrt sjekk av disse krever steder/medier i Supabase.
- Verifisert mot serveren: 8 riktige + 2 feil ga 14, for rask/ukjent nøkkel/feil modus avvist, sortering ga riktig poeng, fasiten kan ikke leses og direkte skriving er stengt. Engangs-lasterfunksjonen er slettet.
- Neste: geografi (steder med fasitkoordinater) og bildequiz på serveren; flytte spørsmålene til Supabase før 1v1.

## 2026-11-24 (økt 11)
- Serverstyrt poengberegning også for geografi og bildequiz. Geografi: appen sender nålen (lat/lon, eller tom når tiden går ut) pr. sted; funksjonen `submit_geo` regner avstand (haversine) mot serverens koordinater (`geo_places`) og gir 5/3/2/1/−1 poeng som i appen. Bildequiz: appen sender bilde, spørsmålstype (name/country/club) og valgt tekst; `submit_photo` sjekker mot `photo_answers` (908 svar). Begge bruker samme vakt som regler/sortering (`round_guard`: 20 s mellom runder, 150 runder pr. døgn) og gir poeng bare én gang pr. sted/bilde pr. døgn (`question_log`).
- Den gamle takbaserte `submit_score` og Cloud.submitScore er fjernet; alle poeng på serveren kommer nå fra serverberegnede runder. Verifisert mot serveren (geo 8 poeng fra 0 km/55 km/333 km/feil/tom nål, gjentatt sted 0 poeng, ukjent sted og feil modus avvist, foto 3 poeng). Fasiten kan ikke leses av klienter.
- Fasitdata lages av tools/make_media_answers.py (supabase/geo_places.tsv og photo_answers.tsv), SQL i supabase/validate_geo_photo.sql. Lastes på nytt når steder/bilder endres (engangslaster beskyttet med tilfeldig kode, slettet etterpå).
- Merk: Et forsøk på en generell «kjør SQL»-funksjon ble avslått av verktøyet (med rette); i stedet brukes smale lastere som bare fyller to tabeller.
- Neste: flytte spørsmålene til Supabase (nødvendig før 1v1), og vurdere ukentlig/daglig liste.

## 2026-11-24 (økt 12)
- Spørsmålene ligger nå i Supabase (593 rader i `questions`, unik `key`, `active`-flagg; supabase/questions.sql). Appen leser dem slik: lagret kopi fra forrige gang → ellers spørsmålene som følger med i appen; i bakgrunnen (én gang pr. oppstart) hentes oppdatert liste fra Supabase og lagres lokalt. Nye eller rettede spørsmål når brukerne uten ny apputgave, og appen virker offline.
- `submit_round` sjekker nå svarene direkte mot `questions` (fasit-hash-tabellen `quiz_answers` og tools/make_answers.py er ikke lenger nødvendig; tabellen er slettet). Gamle `submit_score` er slettet.
- Oppdatere spørsmål: kjør `python tools/make_seed.py` (lager assets/seed/questions.json og supabase/seed.sql med «on conflict (key) do update») og kjør supabase/seed.sql i Supabase SQL Editor. Fjern et spørsmål ved å sette `active = false`.
- Verifisert: 593 rader identiske med lokal seed (0 avvik), innlogget kan lese, uinnlogget ikke; regler (7 riktig + 3 feil = 11) og sortering (2 riktig + 1 feil = 3) gir riktig poeng mot den nye tabellen; engangslasteren er slettet.
- Merk: `correct` er lesbar for innloggede brukere (appen trenger den for umiddelbar tilbakemelding), så en som vil juksemessig kan lese fasiten; poengvalidering hindrer likevel at poeng sendes uten gyldige spørsmål, maks 150 runder/døgn og én poeng-gang pr. spørsmål pr. døgn. For 1v1 må serveren dele ut spørsmål uten fasit og sjekke svar selv.
- Oversettelser: spørsmål som legges til i Supabase mangler oversettelse til sv/da/de/es/fr til de legges i tools/i18n_questions.py (appen viser norsk) – egen oppgave.
- Neste: 1v1 med serverstyrte spørsmål, oversettelser for nye spørsmål fra Supabase, ukentlig/daglig liste.

## 2026-11-24 (økt 13)
- 1v1 (#250) over nett med Supabase, serverstyrt: kortet «1v1» på hovedmenyen (lib/duel/). «Finn motstander» (hurtigmatch), «Utfordre en venn» (kode på 5 tegn) og «Bli med med kode». To spillere får de samme ti regelspørsmålene (lett til vanskelig), 15 sekunder per spørsmål; riktig svar 10 poeng + opptil 5 for fart, feil/tom tid 0; høyest poeng vinner, ved likt vinner den raskeste. Nedtelling synkronisert mot serverklokka, live fremdrift og poeng for motstanderen (Supabase Realtime + polling hvert 2. sekund), seier/tap/uavgjort-skjerm, «forlat kampen» og at en kamp avsluttes 60 sekunder etter at motstanderen er ferdig og den andre har sluttet. Seier/tap teller i statistikken og låser opp 1v1-troféene.
- Server (supabase/duels.sql): tabellene duels og duel_answers (kun lesing av egne oppgjør, ingen skriving fra appen), funksjonene duel_find/create_private/join/cancel/get/questions/answer. Serveren trekker spørsmålene, regner tid og poeng og avgjør vinneren. Maks 40 oppgjør per døgn per bruker. 1v1-poeng teller ikke på rangeringslistene (hindrer juks/samarbeid).
- Ende-til-ende-test mot serveren med to testbrukere: python tools/test_duel.py (18 kontroller, alle OK; ryddes bort etterpå).
- Hovedmenyen justert så seks kort fortsatt får plass uten å rulle på 360 x 760 (mindre logo og mellomrom); tester oppdatert. 45 tester grønne, analyze rent.
- Personvernteksten rettet: tidligere sto det at alt bare lagres på enheten; nå beskriver den at kallenavn, land, poeng og 1v1-resultater lagres hos Supabase (London), at avatar/XP/nivå/troféer bare er på enheten, anonym innlogging og at «Slett all min data» sletter serverdata. Må uansett gjennom juridisk gjennomgang.
- Kjent begrensning: `correct` er lesbar for innloggede (appen trenger den i solo-modus), så en tekniker kan slå opp fasit i 1v1; samme data ligger i appen. Reell sikring krever at solo og 1v1 sjekkes uten at fasit sendes til klient.
- Neste: prøve 1v1 med to telefoner/venn, avgjøre om duell-seire skal gi XP/rangering, og oversettelse av nye spørsmål.

## 2026-11-24 (økt 14)
- «Del appen» i Innstillinger (lib/share_screen.dart): viser en QR-kode som vennene kan skanne, lenken under, og «Kopier lenke» (kopierer en invitasjonstekst med lenken). Lenken er som standard appens side i Google Play (`https://play.google.com/store/apps/details?id=no.ballbrain.ball_brain`) og kan byttes ved bygging med `--dart-define=APP_SHARE_URL=https://...` (f.eks. en nettside som sender iPhone-brukere til App Store og Android-brukere til Google Play). Pakken qr_flutter er lagt til; oversatt til alle språk; 3 nye tester.
- Merk: Lenken virker først når appen er publisert i Google Play. Det finnes ingen App Store-lenke ennå (krever eget nettsted/lenke når iOS-versjonen er ute).
