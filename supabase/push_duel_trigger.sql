-- Varsler den utfordrede spilleren når en utfordring opprettes (samme mønster som i Logica).
-- Erstatt <PROSJEKT-URL> og <PUBLISHABLE-NOKKEL>. Kjør etter supabase/push.sql og etter at
-- Edge-funksjonen notify-duel er utgitt med hemmeligheten FCM_SERVICE_ACCOUNT.
create extension if not exists pg_net;

create or replace function public.notify_duel()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform net.http_post(
    url := '<PROSJEKT-URL>/functions/v1/notify-duel',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer <PUBLISHABLE-NOKKEL>'),
    body := jsonb_build_object('duel_id', new.id)
  );
  return new;
end;
$$;
revoke all on function public.notify_duel() from public, anon, authenticated;

drop trigger if exists duels_notify on public.duels;
create trigger duels_notify after insert on public.duels
  for each row when (new.mode = 'challenge') execute function public.notify_duel();
