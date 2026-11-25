-- Varsler for klubbkamper: utfordring, godtatt og avspark. Erstatt <PROSJEKT-URL> og <NOKKEL>.
-- Kjør etter supabase/push.sql, clubs.sql og push_duel_trigger.sql, og etter at Edge-funksjonen
-- notify-duel er utgitt med hemmeligheten FCM_SERVICE_ACCOUNT.
create extension if not exists pg_net;
create extension if not exists pg_cron;

alter table public.club_games add column if not exists n_invite boolean not null default false;
alter table public.club_games add column if not exists n_accepted boolean not null default false;
alter table public.club_games add column if not exists n_kickoff boolean not null default false;

create or replace function public.notify_club(p_game uuid, p_event text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform net.http_post(
    url := '<PROSJEKT-URL>/functions/v1/notify-duel',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer <NOKKEL>'),
    body := jsonb_build_object('game_id', p_game, 'event', p_event)
  );
end;
$$;
revoke all on function public.notify_club(uuid, text) from public, anon, authenticated;

create or replace function public.club_games_notify()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    perform public.notify_club(new.id, 'invite');
  elsif new.status = 'accepted' and old.status = 'invited' then
    perform public.notify_club(new.id, 'accepted');
  end if;
  return new;
end;
$$;
revoke all on function public.club_games_notify() from public, anon, authenticated;

drop trigger if exists club_games_push on public.club_games;
create trigger club_games_push after insert or update of status on public.club_games
  for each row execute function public.club_games_notify();

-- Avspark: sjekkes hvert minutt.
select cron.schedule('club-kickoff', '* * * * *', $$
  select public.notify_club(id, 'kickoff') from public.club_games
  where status = 'accepted' and not n_kickoff
    and kickoff <= now() and kickoff > now() - interval '2 minutes'
$$);
