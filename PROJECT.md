<!-- odin:start (Odin skriver mellom disse linjene – skriv egne notater utenfor) -->
# Ball Brain

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

## Plan (23/39 ferdige)

**Fase 1: Grunnmur & MVP-prototyp**
- [x] Oppsett Flutter-prosjekt og Supabase-konto (frist 2026-11-23)
- [x] Design database-schema (brukere, highscores, spørsmål) i Supabase (frist 2026-11-24)
- [x] Implementer base-API for å hente spørsmål og lagre poeng (frist 2026-11-25)
- [x] Bygg UI med Flutter for bildesortering (drag-and-drop) (frist 2026-11-26)
- [x] Implementer logikk for regler-quiz og scoring (frist 2026-11-24)

**Fase 2: Sosialt & Konkurranse**
- [x] Legg til seed-database med ~100 spørsmål fra ulike epoker/regler (frist 2026-11-25)
- [x] Implementer lokal rangering (leaderboard) per nasjon via Supabase Edge Functions (frist 2026-11-24)
- [x] Bygg profil-side med visuell trofé-tilstand og highscore-visning (frist 2026-11-24)
- [x] Implementer 1v1-modus med tidsbegrensning og real-time scoring (Supabase Realtime) (frist 2026-11-27)

**Fase 3: Polering, Testing & Lansering**
- [ ] Beta-test med 50–100 brukere, samle bugger og fikse UX (frist 2026-11-26)
- [ ] Oppsett personvern (GDPR), vilkår, datadeling og monetisering (annonser/premium) (frist 2026-11-25)
- [ ] App Store Connect / Google Play Console oppsett og lansering (frist 2026-11-24)

**Fra Claude**
- [x] Personvernerklæring, vilkår og «Slett all min data» i appen (del av #252)
- [ ] Monetisering (annonser/premium) og datadeling – resten av #252
- [ ] Juridisk gjennomgang av personvern/vilkår og kontaktadresse før lansering
- [x] Språkstøtte etter land: norsk, engelsk, svensk, dansk, tysk, spansk, fransk (menyer og seed-spørsmål)
- [ ] Språk: juridisk tekst (personvern/vilkår) på sv/da/de/es/fr, og fagspråk gjennomgått av morsmålsbrukere
- [ ] Språk: spørsmål og stedsnavn fra Supabase/nye spørsmål må få oversettelser
- [ ] Flere spørsmål (over 600, 11 temaer) og flere bilder (spillere/målvakter/stadioner) mot repetisjon
- [x] Mindre repetisjon: husk viste spørsmål/bilder lokalt, stokk svar og startrekkefølge
- [x] Mer spenning: dagens utfordring, «på rad»-merke, vanskelighetsprogresjon og nye bildespørsmål
- [ ] Faktasjekk av de nye spørsmålene (særlig 2025–26-fakta) av en fotballkyndig før lansering
- [x] Vurder ukentlig/daglig utfordring med egen rangering når Supabase er på plass
- [x] Pushvarsler: Firebase-app og nøkkel (Jon), deretter utgi funksjonen og teste (docs/PUSH.md)
- [ ] Test klubbkamp på minst seks telefoner
- [x] Klubbtabell mot andre klubber og klubbserie innad i klubben
- [x] Ball Brain Pro klargjort i testmodus: ingen annonser, statistikk per tema, bom-trening, 4 spørsmålspakker, klubbskjold, rammer og titler
- [ ] Ball Brain Pro: ekte kjøp i App Store / Google Play, vilkår og personverntekst før publisering
- [ ] Faktasjekk de 60 pakkespørsmålene og oversett dem til svensk, dansk, tysk, spansk og fransk
- [ ] Nye avatarbilder som bare Pro får
- [x] Quizkveld: verten starter en quiz, alle svarer på mobilen (under «Kamper»)
- [x] Nye pokaler for dagens utfordring, klubbkamp, quizkveld og øving, og ryddigere innstillinger og menyer
- [ ] Test quizkveld med flere ekte telefoner (gjerne en pubkveld)
- [x] Tegne pokalbilder til de 16 nye pokalene (viser et enkelt ikon nå)
- [x] Personvernteksten må nevne quizkveld (kallenavn og poeng lagres i opptil 7 dager)
- [ ] Quizkveld i nettleser, så pubgjester slipper å installere appen
- [x] Menyforslag som venter på valg: dagens utfordring på forsiden, nytt navn på «Regler-quiz», Pro-verktøy rett i quizmenyen, varselprikk på «Kamper»
- [ ] Menyforslag som venter på valg: Pro-verktøy rett i quizmenyen
- [x] Dagens utfordring på forsiden, «Regler-quiz» heter «Fotballquiz», varsel med gult kort på «Kamper»

## Andre filer i mappen
- `LICENSE` (1 kB)
- `README.md` (1 kB)
- `analysis_options.yaml` (2 kB)
- `android/app/build.gradle.kts` (3 kB)
- `android/app/google-services.json` (1 kB)
- `android/ball_brain_android.iml` (2 kB)
- `android/build.gradle.kts` (1 kB)
- `android/gradle.properties` (1 kB)
- `android/gradlew` (5 kB)
- `android/gradlew.bat` (2 kB)
- `android/key.properties` (1 kB)
- `android/local.properties` (1 kB)
- `android/settings.gradle.kts` (1 kB)
- `assets/avatars/avatar_01.png` (276 kB)
- `assets/avatars/avatar_02.png` (304 kB)
- `assets/avatars/avatar_03.png` (276 kB)
- `assets/avatars/avatar_04.png` (292 kB)
- `assets/avatars/avatar_05.png` (297 kB)
- `assets/avatars/avatar_06.png` (343 kB)
- `assets/avatars/avatar_07.png` (289 kB)
- `assets/avatars/avatar_08.png` (299 kB)
- `assets/avatars/avatar_09.png` (308 kB)
- `assets/avatars/avatar_10.png` (291 kB)
- `assets/avatars/avatar_11.png` (297 kB)
- `assets/avatars/avatar_12.png` (291 kB)
- `assets/avatars/avatar_13.png` (290 kB)
- `assets/avatars/avatar_14.png` (277 kB)
- `assets/avatars/avatar_15.png` (298 kB)
- `assets/avatars/avatar_16.png` (305 kB)
- `assets/avatars/avatar_17.png` (298 kB)
- `assets/avatars/avatar_18.png` (305 kB)
- `assets/avatars/avatar_19.png` (293 kB)
- `assets/avatars/avatar_20.png` (306 kB)
- `assets/avatars/avatar_21.png` (288 kB)
- `assets/avatars/avatar_22.png` (317 kB)
- `assets/avatars/avatar_23.png` (286 kB)
- `assets/avatars/avatar_24.png` (309 kB)
- `assets/avatars/avatar_25.png` (316 kB)
- `assets/avatars/avatar_26.png` (294 kB)
- `assets/avatars/avatar_27.png` (301 kB)
- `assets/avatars/avatar_28.png` (283 kB)
- `assets/avatars/avatar_29.png` (277 kB)
- `assets/avatars/avatar_30.png` (296 kB)
- `assets/avatars/avatar_31.png` (342 kB)
- `assets/avatars/avatar_32.png` (324 kB)
- `assets/avatars/avatar_33.png` (302 kB)
- `assets/avatars/avatar_34.png` (299 kB)
- `assets/avatars/avatar_35.png` (318 kB)
- `assets/avatars/avatar_36.png` (297 kB)
- `assets/avatars/avatar_37.png` (325 kB)
- `assets/avatars/avatar_38.png` (286 kB)
- `assets/avatars/avatar_39.png` (307 kB)
- `assets/avatars/avatar_40.png` (311 kB)
- `assets/avatars/avatar_41.png` (309 kB)
- `assets/avatars/avatar_42.png` (296 kB)
- `assets/avatars/avatar_43.png` (305 kB)
- `ball_brain.iml` (1 kB)
- `pubspec.lock` (32 kB)
- `pubspec.yaml` (5 kB)
- `supabase.env.json` (1 kB)

## Studio
Studio (bilder/video laget for prosjektet): #1076 image done «Modern minimalist logo for a competitive football knowledge » ★ (bildene og videoene ligger i Odin → Studio).

Du kan krysse av her eller i ODIN-OPPGAVER.md; Odin og Claude Code holder alt i synk automatisk (omtrent hvert 15. sekund).
<!-- odin:end -->

## Beslutninger

Skriv beslutninger som punkter her (`- Valgte X fordi Y`). Odin henter dem inn som notater.
- Avatar 31–33 (Jon og barna) blir i appen; vurderes igjen ved personvern-gjennomgang før lansering.
- Språk følger landet i profilen (NO→norsk, SE→svensk, DK→dansk, DE/AT/CH→tysk, ES/MX/AR/CO/CL→spansk, FR→fransk, ellers engelsk) og kan overstyres i Innstillinger. Norsk er kildespråket i koden; oversettelsene ligger i assets/i18n/ og genereres av tools/make_i18n.py (fra tools/i18n_ui.py og tools/i18n_questions.py).
- Spørsmål og bilder trekkes «uviste først» med lokal historikk per modus; full runde gjennom puljen før gjentakelse. Poeng, nivåer og troféer er ikke endret (på rad-merket gir ingen ekstra poeng).
- Spillerbilder med synlige klubbmerker, sponsor-/produsentlogoer eller barn i bakgrunnen tas ikke med; stadionbilder med store sponsorlogoer (f.eks. Deutsche Bank, Bayer, Red Bull, AVIVA) er fjernet.
- Ingen kvinnefotball i spillet (Jon, 2026-11-24): ingen spørsmål eller spillerbilder av kvinner.
- Supabase i bruk (2026-11-24): anonym innlogging, profil og poeng på serveren; spørsmål fra lokal seed inntil videre; slett-data fjerner også serverdata.

- GitHub (2026-11-24): prosjektet ligger offentlig på https://github.com/Craszus/Ball-Brain (gren main). Ingen nøkler i repoet; supabase.env.json er utelatt. Commits bruker GitHubs noreply-adresse. Ingen lisens er valgt ennå (alle rettigheter forbeholdt). Avatar 31–33 er med etter eget valg.

- Lisens (2026-11-24): ingen åpen lisens; alle rettigheter forbeholdt (filen LICENSE), med unntak for bilder (Wikimedia Commons, egne lisenser) og landegrenser (Natural Earth).
- Utgivelser (2026-11-24): som i Logica, bygges lokalt og legges ut med `python tools/release.py` (ingen hemmeligheter på GitHub).
- Dagens utfordring (2026-11-24): egen rangering for dagen og ukessum (mandag–søndag, norsk døgn); kun første forsøk teller; flest riktige, deretter kortest tid.
- Klubber (2026-11-24): vennegjeng-klubber med eget skjold (ingen ekte logoer). Klubbkamp 3v3 eller 5v5 (ikke 7v7), frist maks 5 min (3 eller 5), 10 sek pr. spørsmål, lagkamerater får ulike spørsmål, samlet pott avgjør. Man kan ikke spille for to klubber samme uke.
- Push-varsler (2026-11-24): settes opp som i Logica (Firebase Cloud Messaging).
- Klubbtabell og klubbserie (2026-11-25): tabellen rangerer alle klubber etter klubbkampene, klubbserien rangerer medlemmene etter 1v1 mot hverandre. Seier 3 poeng, uavgjort 1; bare første oppgjør mellom de samme teller hver dag; visning for måneden og totalt.
- Reklame (2026-11-25): testannonser som i Logica (frivillig, samtykke første gang, kan slås av). Strammet inn samme dag: tilbys bare etter hver 3. runde med poeng, maks 3 annonser og 60 bonus-XP per dag. Bonusen er rundens poeng (opp til taket) og påvirker ikke rangeringene. Ekte leverandør, samtykkeløsning, aldersregler og personverntekst må på plass før butikklansering.
- Ball Brain Pro (2026-11-25): klargjort i testmodus (`proMode` i lib/services/pro.dart), prøves uten betaling. Planlagt pris 39 kr/mnd eller 249 kr/år (forslag). Pro gir aldri fordeler på rangeringene: øvingsrunder gir verken XP eller poeng. Statistikk og bom lagres bare på telefonen. Spørsmålspakkene (tools/make_packs.py) finnes på norsk og engelsk.
- Quizkveld (2026-11-25): ligger under «Kamper». Serveren (supabase/quiznight.sql) styrer spørsmål, tid og poeng; verten går videre mellom spørsmålene; opptil 100 deltakere; gratis for alle foreløpig. Poengene teller ikke på rangeringene.
- Menyer (2026-11-25): gjennomgått av en egen agent. Innstillinger delt i grupper, handlingsknappene øverst i 1v1, reglene under valgene, «Klubber»-fanen i rangeringen byttet med klubbtabellen.
- Forside (2026-11-25): «Regler-quiz» heter nå «Fotballquiz». Dagens utfordring ligger som en gullstripe over spillknappene (overskriften «SPILLMODE» fjernet for å få plass). Ved utfordring viser «Kamper» et gult kort med antall og pulserer i gull.
- Pokaler lages i Blender (tools/make_trophies.py + tools/compose_trophies.py), så nye kan lages i samme stil.
- Frister utsatt tre uker (2026-11-25): MVP-målet flyttes fra 30. november til 21. desember 2026. Personvern/monetisering 16. des., betatest 17. des., lansering 21. des. (satt etter betatesten). Google Play krever lukket test i 14 dager, så testen må starte senest rundt 1. desember.
- MVP-målet flyttet til 15. januar 2027 (2026-11-25, erstatter 21. desember). Lansering (#253) har samme frist; forslag: personvern/monetisering 16. des. og betatest 17. des. Frister og mål må endres i Odin.
