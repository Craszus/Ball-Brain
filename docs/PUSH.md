# Push-varsler (samme oppsett som i Logica)

Varsler for 1v1-utfordringer og klubbkamper (utfordring, godtatt, avspark) via Firebase Cloud
Messaging (gratis). Appen er klar; serverdelen utgis og testes når stegene under er gjort.

## Det Jon gjør

1. console.firebase.google.com: lag et prosjekt (f.eks. «Ball Brain»; Google Analytics trengs
   ikke) og legg til en Android-app med pakkenavnet `no.ballbrain.ball_brain`. Last ned
   `google-services.json` og legg den i `android/app/` (den er utelatt fra GitHub).
2. Prosjektinnstillinger → Tjenestekontoer → «Generer ny privat nøkkel». Lim hele innholdet inn
   som hemmeligheten `FCM_SERVICE_ACCOUNT` i Supabase → Edge Functions → Secrets. Ikke legg
   filen i prosjektmappen eller i chatten.

## Det Claude gjør etterpå

3. Utgi `supabase/functions/notify-duel` (navn: notify-duel).
4. Kjør `supabase/push_duel_trigger.sql` og `supabase/push_club_trigger.sql` (bytt inn
   prosjekt-URL og nøkkel). `supabase/push.sql` er allerede kjørt.
5. Bygg appen på nytt, installer og test ende-til-ende med to telefoner.
