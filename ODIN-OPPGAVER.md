# Oppgaver – Ball Brain

Kryss av `[x]` når noe er ferdig. Nye oppgaver legges nederst som `- [ ] tekst`. Ikke rør `(#nummer)`.


## Fase 1: Grunnmur & MVP-prototyp
- [x] (#242) Oppsett Flutter-prosjekt og Supabase-konto (frist 2026-11-23)
- [x] (#243) Design database-schema (brukere, highscores, spørsmål) i Supabase (frist 2026-11-24)
- [x] (#244) Implementer base-API for å hente spørsmål og lagre poeng (frist 2026-11-25)
- [x] (#245) Bygg UI med Flutter for bildesortering (drag-and-drop) (frist 2026-11-26)
- [x] (#246) Implementer logikk for regler-quiz og scoring (frist 2026-11-24)

## Fase 2: Sosialt & Konkurranse
- [x] (#247) Legg til seed-database med ~100 spørsmål fra ulike epoker/regler (frist 2026-11-25)
- [x] (#248) Implementer lokal rangering (leaderboard) per nasjon via Supabase Edge Functions (frist 2026-11-24)
- [x] (#249) Bygg profil-side med visuell trofé-tilstand og highscore-visning (frist 2026-11-24)
- [ ] (#250) Implementer 1v1-modus med tidsbegrensning og real-time scoring (Supabase Realtime) (frist 2026-11-27)

## Fase 3: Polering, Testing & Lansering
- [ ] (#251) Beta-test med 50–100 brukere, samle bugger og fikse UX (frist 2026-11-26)
- [ ] (#252) Oppsett personvern (GDPR), vilkår, datadeling og monetisering (annonser/premium) (frist 2026-11-25)
- [ ] (#253) App Store Connect / Google Play Console oppsett og lansering (frist 2026-11-24)

## Fra Claude
- [x] (#269) Personvernerklæring, vilkår og «Slett all min data» i appen (del av #252)
- [ ] (#270) Monetisering (annonser/premium) og datadeling – resten av #252
- [ ] (#271) Juridisk gjennomgang av personvern/vilkår og kontaktadresse før lansering
- [ ] (#272) Språkstøtte etter land: norsk, engelsk, svensk, dansk, tysk, spansk, fransk (menyer og seed-spørsmål)
- [ ] (#273) Språk: juridisk tekst (personvern/vilkår) på sv/da/de/es/fr, og fagspråk gjennomgått av morsmålsbrukere
- [ ] (#274) Språk: spørsmål og stedsnavn fra Supabase/nye spørsmål må få oversettelser
- [ ] (#277) Flere spørsmål (over 600, 11 temaer) og flere bilder (spillere/målvakter/stadioner) mot repetisjon
- [ ] (#278) Mindre repetisjon: husk viste spørsmål/bilder lokalt, stokk svar og startrekkefølge
- [ ] (#279) Mer spenning: dagens utfordring, «på rad»-merke, vanskelighetsprogresjon og nye bildespørsmål
- [ ] (#280) Faktasjekk av de nye spørsmålene (særlig 2025–26-fakta) av en fotballkyndig før lansering
- [x] (#281) Vurder ukentlig/daglig utfordring med egen rangering når Supabase er på plass
- [x] (#291) Pushvarsler: Firebase-app og nøkkel (Jon), deretter utgi funksjonen og teste (docs/PUSH.md)
- [ ] (#292) Test klubbkamp på minst seks telefoner
- [x] (#293) Klubbtabell mot andre klubber og klubbserie innad i klubben
