# Push-varsler for 1v1-utfordringer (samme oppsett som i Logica)

Varsling mens appen er lukket krever Firebase Cloud Messaging (gratis). Serverkoden er forberedt,
men **ikke kjørt eller testet**. Disse stegene må gjøres før appen kan kobles til:

1. Firebase-konsollen (console.firebase.google.com): lag et prosjekt og legg til en Android-app
   med pakkenavnet `no.ballbrain.ball_brain`. Last ned `google-services.json` til `android/app/`.
2. Prosjektinnstillinger → Tjenestekontoer → «Generer ny privat nøkkel». Lim hele JSON-filen inn
   som hemmeligheten `FCM_SERVICE_ACCOUNT` i Supabase → Edge Functions → Secrets. Ikke legg filen
   i repoet.
3. Kjør `supabase/push.sql` i SQL Editor, utgi funksjonen `supabase/functions/notify-duel`
   (navn: notify-duel), og kjør `supabase/push_duel_trigger.sql` (bytt inn prosjekt-URL og
   publishable-nøkkelen).
4. Appen: legg til pakkene firebase_core og firebase_messaging, spør om varseltillatelse, lagre
   enhetens varsel-id med `register_push_token`, og slett den med `unregister_push_token` når
   utfordringer slås av. Oppdater personvernteksten (varsel-id lagres).
