-- Slår på push-varslene. Lim «anon public»-nøkkelen mellom anførselstegnene på linje 3 (over plassholderen), og trykk Run. Ikke service_role. Ikke lagre nøkkelen i denne filen.
create or replace function public.notify_key() returns text language sql set search_path = '' as $$
  select 'NOKKEL-HER'
$$;
create extension if not exists pg_net;
create extension if not exists pg_cron;

revoke all on function public.notify_key() from public, anon, authenticated;
do $$ begin
  if public.notify_key() not like 'eyJ%' then
    raise exception 'Linje 3 har ikke anon-nøkkelen. Den begynner med eyJ';
  end if;
end $$;

create or replace function public.notify_send(p_body jsonb)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform net.http_post(
    url := 'https://hrdwyqnkfomqrhtwwyrh.supabase.co/functions/v1/notify-duel',
    headers := jsonb_build_object('Content-Type', 'application/json',
                                  'Authorization', 'Bearer ' || public.notify_key()),
    body := p_body);
end $$;
revoke all on function public.notify_send(jsonb) from public, anon, authenticated;

-- 1v1: varsle den utfordrede
create or replace function public.notify_duel()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform public.notify_send(jsonb_build_object('duel_id', new.id));
  return new;
end $$;
revoke all on function public.notify_duel() from public, anon, authenticated;
drop trigger if exists duels_notify on public.duels;
create trigger duels_notify after insert on public.duels
  for each row when (new.mode = 'challenge') execute function public.notify_duel();

-- Klubbkamp: utfordring, godtatt og avspark
alter table public.club_games add column if not exists n_invite boolean not null default false;
alter table public.club_games add column if not exists n_accepted boolean not null default false;
alter table public.club_games add column if not exists n_kickoff boolean not null default false;

create or replace function public.club_games_notify()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    perform public.notify_send(jsonb_build_object('game_id', new.id, 'event', 'invite'));
  elsif new.status = 'accepted' and old.status = 'invited' then
    perform public.notify_send(jsonb_build_object('game_id', new.id, 'event', 'accepted'));
  end if;
  return new;
end $$;
revoke all on function public.club_games_notify() from public, anon, authenticated;
drop trigger if exists club_games_push on public.club_games;
create trigger club_games_push after insert or update of status on public.club_games
  for each row execute function public.club_games_notify();

select cron.schedule('club-kickoff', '* * * * *', $$
  select public.notify_send(jsonb_build_object('game_id', id, 'event', 'kickoff'))
  from public.club_games
  where status = 'accepted' and not n_kickoff
    and kickoff <= now() and kickoff > now() - interval '2 minutes'
$$);

select 'Varslene er slått på' as resultat;
