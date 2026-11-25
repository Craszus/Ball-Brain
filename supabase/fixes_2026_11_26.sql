-- 2026-11-26: faktarettelser i spørsmålene og 1v1-rettelser. Trygg å kjøre flere ganger.
begin;
insert into public.questions (key, type, era, prompt, options, correct, difficulty, active) values
  ('3a3bc7cdd05c', 'rules_quiz', 'Regler', 'Hva er straffen når en utespiller bevisst tar ballen med hånden i eget straffefelt?', '["Innkast", "Straffespark", "Dommerball", "Indirekte frispark"]'::jsonb, '1'::jsonb, 1, true),
  ('c1f42947a8e4', 'rules_quiz', 'Regler', 'Hva kreves av keeperen ved et straffespark?', '["Stå én meter foran mållinja", "Stå i målfeltet", "Begge føttene på mållinja", "Minst én fot på, på linje med eller bak mållinja"]'::jsonb, '3'::jsonb, 3, true),
  ('e76185d9d381', 'rules_quiz', 'Regler', 'Hvilken situasjon kan VAR ikke gripe inn i?', '["Et innkast", "Direkte rødt kort", "Straffespark", "Mål"]'::jsonb, '0'::jsonb, 3, true),
  ('00ed820c3a15', 'rules_quiz', 'VM-historie', 'Hvem er VM-historiens toppscorer hos menn?', '["Miroslav Klose", "Lionel Messi", "Kylian Mbappé", "Ronaldo Nazário"]'::jsonb, '2'::jsonb, 3, true),
  ('ee0268175ee0', 'rules_quiz', 'VM-historie', 'Hvilke land var VM-verter i 2026?', '["Mexico, Brasil og Argentina", "USA, Canada og Costa Rica", "Spania, Portugal og Marokko", "USA, Canada og Mexico"]'::jsonb, '3'::jsonb, 2, true),
  ('b44541f37817', 'rules_quiz', 'VM-historie', 'Hvem vant VM i 1934?', '["Italia", "Ungarn", "Tyskland", "Tsjekkoslovakia"]'::jsonb, '0'::jsonb, 4, true),
  ('a9841fa38712', 'rules_quiz', 'VM-historie', 'Hvor mange VM-titler har Spania for menn?', '["0", "2", "1", "3"]'::jsonb, '1'::jsonb, 2, true),
  ('170717df0a1c', 'rules_quiz', 'Stadioner', 'I hvilken by ligger Romssa Arena (Alfheim)?', '["Tromsø", "Bodø", "Harstad", "Alta"]'::jsonb, '0'::jsonb, 1, true),
  ('e37cf23a4c2e', 'rules_quiz', 'Visste du at?', 'Hvor mange lag deltok i VM 2026?', '["48", "32", "64", "40"]'::jsonb, '0'::jsonb, 1, true),
  ('2cd7907c909f', 'rules_quiz', 'Regler', 'Hvilke situasjoner kan VAR gripe inn i?', '["Innkast, frispark på midtbanen og tilleggstid", "Alle frispark og innkast", "Bare mål", "Mål, straffespark, røde kort og feil spiller"]'::jsonb, '3'::jsonb, 2, true),
  ('892ccdb0778b', 'rules_quiz', 'Regler', 'Spillet stoppes og skal startes med dommerball utenfor straffefeltet. Hvem får ballen?', '["Hjemmelaget", "Laget som ligger under", "Begge lag kjemper om den", "Laget som hadde eller ville ha fått ballen"]'::jsonb, '3'::jsonb, 4, true),
  ('76b57a4178d0', 'rules_quiz', 'Regler', 'Hva får en spiller som bevisst forlater banen uten dommerens tillatelse (ikke i protest)?', '["Rødt kort", "Ingenting", "Frispark mot laget", "Gult kort"]'::jsonb, '3'::jsonb, 3, true),
  ('cea72be012e3', 'rules_quiz', 'Regler', 'Kan dommeren endre hvordan spillet skal settes i gang etter at det er satt i gang igjen?', '["Ja", "Nei"]'::jsonb, '1'::jsonb, 3, true),
  ('e836f1a525ed', 'image_sort', 'Klubbfotball', 'Sorter Champions League-finalene fra eldst til nyest', '["Real Madrid – Dortmund", "Bayern – PSG", "Liverpool – Tottenham", "Chelsea – Man City", "Man City – Inter"]'::jsonb, '[2, 1, 3, 4, 0]'::jsonb, 3, true),
  ('0df3f0bcba35', 'image_sort', 'Klubbfotball', 'Sorter Ballon d''Or-vinnerne etter året de vant (tidligst først)', '["Kaká", "Luka Modrić", "Ousmane Dembélé", "Karim Benzema", "Rodri"]'::jsonb, '[0, 1, 3, 4, 2]'::jsonb, 3, true),
  ('5abc0c8fcfe2', 'image_sort', 'Klubbfotball', 'Sorter Premier League-mesterne etter året de vant (tidligst først)', '["Chelsea (Conte)", "Leicester (eventyret)", "Liverpool (Slot)", "Liverpool (Klopp)", "Man United (Ferguson tar farvel)"]'::jsonb, '[4, 1, 0, 3, 2]'::jsonb, 3, true),
  ('c90bdab17909', 'image_sort', 'VM-historie', 'Sorter VM-vertene fra eldst til nyest', '["Sør-Korea og Japan", "Qatar", "Russland", "Sør-Afrika"]'::jsonb, '[0, 3, 2, 1]'::jsonb, 2, true),
  ('7c77632211bb', 'image_sort', 'Stadioner', 'Sorter stadionene fra størst til minst kapasitet', '["Signal Iduna Park", "Anfield", "Wembley", "Old Trafford"]'::jsonb, '[2, 0, 3, 1]'::jsonb, 3, true),
  ('d5c9baf2edc5', 'image_sort', 'Klubbfotball', 'Sorter Champions League-finalene fra eldst til nyest', '["Real Madrid – Dortmund", "Man United – Chelsea", "Chelsea – Bayern", "Real Madrid – Liverpool"]'::jsonb, '[1, 2, 3, 0]'::jsonb, 3, true),
  ('31aa3fed373d', 'image_sort', 'Spillere og rekorder', 'Sorter Ballon d''Or-vinnerne etter året de vant (tidligst først)', '["George Weah", "Pavel Nedvěd", "Luís Figo", "Zinedine Zidane", "Fabio Cannavaro"]'::jsonb, '[0, 3, 2, 1, 4]'::jsonb, 4, true),
  ('1c47c6e3a265', 'image_sort', 'Spillere og rekorder', 'Sorter Ballon d''Or-vinnerne etter året de vant (tidligst først)', '["Kaká", "Michael Owen", "Andrij Sjevtsjenko", "Rodri", "Ronaldinho"]'::jsonb, '[1, 2, 4, 0, 3]'::jsonb, 3, true),
  ('1fa7c4e2efcd', 'image_sort', 'Ligaer', 'Sorter Premier League-mesterne etter året de vant (tidligst først)', '["Blackburn Rovers", "Man City (første PL-tittel)", "Chelsea (første PL-tittel)", "Arsenal (de ubeseirede)", "Leicester City"]'::jsonb, '[0, 3, 2, 1, 4]'::jsonb, 3, true),
  ('0fc7390b5c92', 'image_sort', 'VM-historie', 'Sorter landene fra flest til færrest VM-titler', '["Brasil", "Argentina", "Frankrike", "England"]'::jsonb, '[0, 1, 2, 3]'::jsonb, 2, true),
  ('959939cab251', 'image_sort', 'EM-historie', 'Sorter EM-vinnerne etter året de vant (tidligst først)', '["Hellas", "Danmark", "Portugal", "Tsjekkoslovakia", "Sovjetunionen"]'::jsonb, '[4, 3, 1, 0, 2]'::jsonb, 3, true)
on conflict (key) do update set type = excluded.type, era = excluded.era, prompt = excluded.prompt,
  options = excluded.options, correct = excluded.correct, difficulty = excluded.difficulty, active = true;
update public.questions set active = false where key in ('1144f18e303b', '12e858f1dcda', '1a7c4b78d9df', '1ace3a988f12', '1e5ceec1d449', '214bd61c7bb1', '39ca6171dbd3', '4e7eea632f71', '6d27eb4b285b', '7212df3bdacf', '7aa09dcd9044', '7cd260c7bfe1', '7e2bef67fcfd', '82ba0b7ee465', '8f1f635b0c55', '9055dfc1dd84', 'aa3da96b7a23', 'bddf3bc1c553', 'c9bc5bc18a2b', 'd5249138f71c', 'e5e77f557e28', 'f1d034e4fac4', 'fee7a4611611');
update public.photo_answers set answer = 'Romssa Arena (Alfheim)' where item = 'stadium:alfheim-stadion' and qtype = 'name';
create or replace function public.duel_finalize(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare d duels; w uuid;
begin
  select * into d from duels where id = p_id and status = 'active' for update;
  if not found then return; end if;
  if d.p1_score > d.p2_score then w := d.p1;
  elsif d.p2_score > d.p1_score then w := d.p2;
  -- likt, men bare én har spilt ferdig: den vinner (den andre har ikke «brukt» noe tid)
  elsif d.p1_done_at is not null and d.p2_done_at is null then w := d.p1;
  elsif d.p2_done_at is not null and d.p1_done_at is null then w := d.p2;
  elsif d.p1_ms < d.p2_ms then w := d.p1;
  elsif d.p2_ms < d.p1_ms then w := d.p2;
  else w := null; end if;
  update duels set status = 'finished', finished_at = now(), winner = w where id = p_id;
end $$;
create or replace function public.duel_get(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid();
begin
  select * into d from duels where id = p_id and (p1 = me or p2 = me);
  if not found then raise exception 'not_found'; end if;
  if d.mode = 'live' and d.status = 'active' and (d.p1_done_at is null) <> (d.p2_done_at is null)
     -- avslutt bare når den som ikke er ferdig har sluttet å svare (en aktiv spiller svarer innen ca. 17 s)
     and now() - (case when d.p1_done_at is null then d.p1_last else d.p2_last end) > interval '30 seconds' then
    perform duel_finalize(p_id);
    select * into d from duels where id = p_id;
  elsif d.mode = 'challenge' and d.status = 'active' and d.expires_at < now() then
    perform duel_housekeeping();
    select * into d from duels where id = p_id;
  end if;
  return duel_summary(d);
end $$;
commit;
select (select count(*) from public.questions where active) as aktive,
  (select count(*) from public.questions where not active) as utgatt;
