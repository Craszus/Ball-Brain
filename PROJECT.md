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

## Plan (6/23 ferdige)

**Fase 1: Grunnmur & MVP-prototyp**
- [ ] Oppsett Flutter-prosjekt og Supabase-konto (frist 2026-11-23)
- [ ] Design database-schema (brukere, highscores, spørsmål) i Supabase (frist 2026-11-24)
- [x] Implementer base-API for å hente spørsmål og lagre poeng (frist 2026-11-25)
- [x] Bygg UI med Flutter for bildesortering (drag-and-drop) (frist 2026-11-26)
- [x] Implementer logikk for regler-quiz og scoring (frist 2026-11-24)

**Fase 2: Sosialt & Konkurranse**
- [x] Legg til seed-database med ~100 spørsmål fra ulike epoker/regler (frist 2026-11-25)
- [x] Implementer lokal rangering (leaderboard) per nasjon via Supabase Edge Functions (frist 2026-11-24)
- [x] Bygg profil-side med visuell trofé-tilstand og highscore-visning (frist 2026-11-24)
- [ ] Implementer 1v1-modus med tidsbegrensning og real-time scoring (Supabase Realtime) (frist 2026-11-27)

**Fase 3: Polering, Testing & Lansering**
- [ ] Beta-test med 50–100 brukere, samle bugger og fikse UX (frist 2026-11-26)
- [ ] Oppsett personvern (GDPR), vilkår, datadeling og monetisering (annonser/premium) (frist 2026-11-25)
- [ ] App Store Connect / Google Play Console oppsett og lansering (frist 2026-11-24)

**Fra Claude**
- [ ] Personvernerklæring, vilkår og «Slett all min data» i appen (del av #252)
- [ ] Monetisering (annonser/premium) og datadeling – resten av #252
- [ ] Juridisk gjennomgang av personvern/vilkår og kontaktadresse før lansering
- [ ] Språkstøtte etter land: norsk, engelsk, svensk, dansk, tysk, spansk, fransk (menyer og seed-spørsmål)
- [ ] Språk: juridisk tekst (personvern/vilkår) på sv/da/de/es/fr, og fagspråk gjennomgått av morsmålsbrukere
- [ ] Språk: spørsmål og stedsnavn fra Supabase/nye spørsmål må få oversettelser
- [ ] Flere spørsmål (over 600, 11 temaer) og flere bilder (spillere/målvakter/stadioner) mot repetisjon
- [ ] Mindre repetisjon: husk viste spørsmål/bilder lokalt, stokk svar og startrekkefølge
- [ ] Mer spenning: dagens utfordring, «på rad»-merke, vanskelighetsprogresjon og nye bildespørsmål
- [ ] Faktasjekk av de nye spørsmålene (særlig 2025–26-fakta) av en fotballkyndig før lansering
- [ ] Vurder ukentlig/daglig utfordring med egen rangering når Supabase er på plass

## Andre filer i mappen
- `README.md` (1 kB)
- `analysis_options.yaml` (2 kB)
- `android/app/build.gradle.kts` (2 kB)
- `android/ball_brain_android.iml` (2 kB)
- `android/build.gradle.kts` (1 kB)
- `android/gradle.properties` (1 kB)
- `android/gradlew` (5 kB)
- `android/gradlew.bat` (2 kB)
- `android/local.properties` (1 kB)
- `android/settings.gradle.kts` (1 kB)
- `assets/avatars/README.txt` (1 kB)
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
- `assets/avatars/avatar_44.png` (281 kB)
- `assets/avatars/avatar_45.png` (298 kB)
- `ball_brain.iml` (1 kB)
- `pubspec.lock` (30 kB)
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
