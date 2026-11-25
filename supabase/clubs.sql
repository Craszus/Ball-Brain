-- Klubber (vennegjengen med skjold og farger) og klubbkamp 3 mot 3 / 5 mot 5. Kjøres i SQL Editor.
-- En klubb er en gruppe. Utfordreren velger lagstørrelse, avspark og frist (3 eller 5 minutter).
-- Lagkameratene får forskjellige spørsmål, motstanderen får de samme totalt. 10 sekunder pr.
-- spørsmål; riktig svar gir 10 poeng + opptil 5 for fart. Størst samlet pott vinner.

alter table public.groups add column if not exists color1 int not null default 0;
alter table public.groups add column if not exists color2 int not null default 1;
alter table public.groups add column if not exists emblem int not null default 0;
alter table public.groups add column if not exists match_code text unique;

create table if not exists public.club_games (
  id uuid primary key default gen_random_uuid(),
  home uuid not null references public.groups(id) on delete cascade,
  away uuid not null references public.groups(id) on delete cascade,
  size int not null check (size in (3, 5)),
  window_min int not null check (window_min in (3, 5)),
  kickoff timestamptz not null,
  status text not null default 'invited'
    check (status in ('invited', 'accepted', 'finished', 'declined', 'cancelled', 'expired')),
  keys text[],
  home_score int not null default 0,
  away_score int not null default 0,
  winner uuid,
  created_at timestamptz not null default now()
);
create table if not exists public.club_game_players (
  game_id uuid not null references public.club_games(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  club uuid not null,
  slot int not null,
  idx int not null default 0,
  score int not null default 0,
  correct int not null default 0,
  served_at timestamptz,
  joined_at timestamptz not null default now(),
  primary key (game_id, user_id),
  unique (game_id, club, slot)
);
alter table public.club_games enable row level security;
alter table public.club_game_players enable row level security;
revoke all on public.club_games, public.club_game_players from anon, authenticated;

create or replace function public.club_is_member(p_club uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from group_members where group_id = p_club and user_id = auth.uid())
$$;

create or replace function public.club_ends(g public.club_games)
returns timestamptz language sql immutable set search_path = public as $$
  select g.kickoff + make_interval(mins => g.window_min)
$$;

-- Utløper ubesvarte utfordringer og avgjør ferdige kamper.
create or replace function public.club_housekeeping()
returns void language plpgsql security definer set search_path = public as $$
declare g club_games; v_home int; v_away int;
begin
  update club_games set status = 'expired' where status = 'invited' and kickoff <= now();
  for g in
    select * from club_games c where c.status = 'accepted' and (
      now() > club_ends(c) + interval '3 seconds'
      or (select count(*) from club_game_players p where p.game_id = c.id and p.idx >= 10) = 2 * c.size)
    for update skip locked
  loop
    select coalesce(sum(score) filter (where club = g.home), 0),
           coalesce(sum(score) filter (where club = g.away), 0)
      into v_home, v_away from club_game_players where game_id = g.id;
    update club_games set status = 'finished', home_score = v_home, away_score = v_away,
      winner = case when v_home > v_away then g.home when v_away > v_home then g.away end
      where id = g.id;
  end loop;
end $$;

-- Klubbene mine med skjold, utfordringskode og resultater.
create or replace function public.club_my_clubs()
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); r record; v_code text;
begin
  perform club_housekeeping();
  for r in select g.id from groups g join group_members m on m.group_id = g.id
           where m.user_id = me and g.match_code is null loop
    loop
      v_code := upper(substr(translate(md5(random()::text || clock_timestamp()::text), '01', 'XY'), 1, 6));
      exit when not exists (select 1 from groups where match_code = v_code);
    end loop;
    update groups set match_code = v_code where id = r.id;
  end loop;
  return (select coalesce(jsonb_agg(jsonb_build_object(
      'id', g.id, 'name', g.name, 'color1', g.color1, 'color2', g.color2, 'emblem', g.emblem,
      'match_code', g.match_code,
      'members', (select count(*) from group_members x where x.group_id = g.id),
      'can_edit', g.owner_id = me
        or not exists (select 1 from group_members o where o.group_id = g.id and o.user_id = g.owner_id),
      'wins', (select count(*) from club_games c where c.status = 'finished' and c.winner = g.id),
      'draws', (select count(*) from club_games c where c.status = 'finished' and c.winner is null
                and g.id in (c.home, c.away)),
      'losses', (select count(*) from club_games c where c.status = 'finished' and c.winner <> g.id
                 and g.id in (c.home, c.away))
    ) order by g.name), '[]'::jsonb)
    from groups g join group_members m on m.group_id = g.id and m.user_id = me);
end $$;

create or replace function public.club_set_look(p_club uuid, p_color1 int, p_color2 int, p_emblem int)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not club_is_member(p_club) then raise exception 'not_member'; end if;
  if exists (select 1 from groups g join group_members o on o.group_id = g.id and o.user_id = g.owner_id
             where g.id = p_club and g.owner_id <> auth.uid()) then raise exception 'not_owner'; end if;
  if p_color1 not between 0 and 7 or p_color2 not between 0 and 7 or p_emblem not between 0 and 7 then
    raise exception 'bad_look'; end if;
  update groups set color1 = p_color1, color2 = p_color2, emblem = p_emblem where id = p_club;
end $$;

-- Melder meg på laget (første ledige plass). Man kan ikke spille for to klubber samme uke.
create or replace function public.club_join(p_game uuid, p_club uuid)
returns void language plpgsql security definer set search_path = public as $$
declare g club_games; me uuid := auth.uid(); v_slot int;
begin
  select * into g from club_games where id = p_game for update;
  if not found or p_club not in (g.home, g.away) then raise exception 'not_found'; end if;
  if not club_is_member(p_club) then raise exception 'not_member'; end if;
  if exists (select 1 from club_game_players where game_id = p_game and user_id = me) then return; end if;
  if not (g.status = 'accepted' or (g.status = 'invited' and p_club = g.home)) or now() >= club_ends(g) then
    raise exception 'closed'; end if;
  if exists (select 1 from club_game_players p join club_games c on c.id = p.game_id
             where p.user_id = me and p.club <> p_club and p.joined_at > now() - interval '7 days'
               and c.status in ('invited', 'accepted', 'finished')) then
    raise exception 'locked'; end if;
  select s into v_slot from generate_series(0, g.size - 1) s
    where not exists (select 1 from club_game_players p
                      where p.game_id = p_game and p.club = p_club and p.slot = s)
    order by s limit 1;
  if v_slot is null then raise exception 'team_full'; end if;
  insert into club_game_players (game_id, user_id, club, slot) values (p_game, me, p_club, v_slot);
end $$;

-- Forlater laget før man har begynt å svare.
create or replace function public.club_leave_game(p_game uuid)
returns void language sql security definer set search_path = public as $$
  delete from club_game_players where game_id = p_game and user_id = auth.uid()
    and idx = 0 and served_at is null;
$$;

create or replace function public.club_challenge(
  p_club uuid, p_code text, p_size int, p_kickoff timestamptz, p_window int)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_away uuid; v_id uuid;
begin
  perform club_housekeeping();
  if not club_is_member(p_club) then raise exception 'not_member'; end if;
  select id into v_away from groups where match_code = upper(trim(p_code));
  if v_away is null then raise exception 'not_found'; end if;
  if v_away = p_club then raise exception 'own_club'; end if;
  if p_size not in (3, 5) or p_window not in (3, 5) then raise exception 'bad_setup'; end if;
  if p_kickoff < now() + interval '1 minute' or p_kickoff > now() + interval '7 days' then
    raise exception 'bad_time'; end if;
  if (select count(*) from group_members where group_id = p_club) < p_size then raise exception 'too_few'; end if;
  if (select count(*) from group_members where group_id = v_away) < p_size then
    raise exception 'opp_too_few'; end if;
  if exists (select 1 from club_games where status in ('invited', 'accepted')
             and ((home = p_club and away = v_away) or (home = v_away and away = p_club))) then
    raise exception 'already'; end if;
  if (select count(*) from club_games where status in ('invited', 'accepted') and home = p_club) >= 3
     or (select count(*) from club_games where home = p_club and created_at > now() - interval '24 hours') >= 10 then
    raise exception 'too_many'; end if;
  insert into club_games (home, away, size, window_min, kickoff)
    values (p_club, v_away, p_size, p_window, p_kickoff) returning id into v_id;
  perform club_join(v_id, p_club);
  return v_id;
end $$;

-- Den utfordrede klubben godtar eller avslår. Spørsmålene trekkes når kampen godtas.
create or replace function public.club_respond(p_game uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = public as $$
declare g club_games; v_keys text[];
begin
  perform club_housekeeping();
  select * into g from club_games where id = p_game for update;
  if not found or not club_is_member(g.away) then raise exception 'not_found'; end if;
  if g.status <> 'invited' then raise exception 'closed'; end if;
  if not p_accept then
    update club_games set status = 'declined' where id = p_game;
    return;
  end if;
  -- Sortert på vanskelighet og delt ut annenhver plass, så alle får like tunge spørsmål.
  -- Plass s får spørsmålene på posisjon s, s + size, s + 2*size ...
  select array_agg(key order by difficulty, r) into v_keys from (
    select key, difficulty, random() as r from questions
    where type = 'rules_quiz' and active and key is not null
    order by random() limit g.size * 10) q;
  update club_games set status = 'accepted', keys = v_keys where id = p_game;
end $$;

-- Utfordreren trekker utfordringen (før den er godtatt).
create or replace function public.club_cancel(p_game uuid)
returns void language sql security definer set search_path = public as $$
  update club_games set status = 'cancelled'
  where id = p_game and status = 'invited' and club_is_member(home);
$$;

-- Neste spørsmål til meg. Klokka (10 s) starter når spørsmålet hentes første gang.
create or replace function public.club_next(p_game uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare g club_games; p club_game_players; me uuid := auth.uid(); v_key text; q questions; v_served timestamptz;
begin
  select * into p from club_game_players where game_id = p_game and user_id = me for update;
  if not found then raise exception 'not_player'; end if;
  select * into g from club_games where id = p_game;
  if p.idx >= 10 then return jsonb_build_object('done', true); end if;
  if g.status = 'finished' or now() >= club_ends(g) then return jsonb_build_object('done', true); end if;
  if g.status <> 'accepted' or now() < g.kickoff then raise exception 'not_started'; end if;
  select k into v_key from (
    select k from unnest(g.keys) with ordinality as t(k, o)
    where (o - 1) % g.size = p.slot
    order by md5(k || me::text)) s
    offset p.idx limit 1;
  select * into q from questions where key = v_key;
  v_served := coalesce(p.served_at, clock_timestamp());
  update club_game_players set served_at = v_served where game_id = p_game and user_id = me;
  return jsonb_build_object(
    'done', false, 'idx', p.idx, 'total', 10, 'prompt', q.prompt, 'era', q.era,
    'options', (select jsonb_agg(o order by md5(o || me::text || v_key))
                from jsonb_array_elements_text(q.options) o),
    'remaining_ms', greatest(0, 10000 - (extract(epoch from clock_timestamp() - v_served) * 1000)::int));
end $$;

-- Svar på spørsmål nr. p_idx. p_answer = valgt tekst, eller null når tiden gikk ut.
create or replace function public.club_answer(p_game uuid, p_idx int, p_answer text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare g club_games; p club_game_players; me uuid := auth.uid(); v_key text; v_right text;
  ms int; v_ok boolean; v_pts int;
begin
  select * into p from club_game_players where game_id = p_game and user_id = me for update;
  if not found then raise exception 'not_player'; end if;
  select * into g from club_games where id = p_game;
  if g.status <> 'accepted' or now() > club_ends(g) + interval '2 seconds' then raise exception 'closed'; end if;
  if p_idx <> p.idx or p.idx >= 10 or p.served_at is null then raise exception 'bad_index'; end if;
  select k into v_key from (
    select k from unnest(g.keys) with ordinality as t(k, o)
    where (o - 1) % g.size = p.slot
    order by md5(k || me::text)) s
    offset p.idx limit 1;
  select options ->> ((correct #>> '{}')::int) into v_right from questions where key = v_key;
  ms := greatest(0, (extract(epoch from clock_timestamp() - p.served_at) * 1000)::int);
  v_ok := p_answer is not null and p_answer = v_right and ms <= 12000;  -- 2 s slingringsmonn for nettet
  v_pts := case when v_ok then 10 + least(5, greatest(0, (10000 - ms) / 2000)) else 0 end;
  update club_game_players set idx = idx + 1, served_at = null, score = score + v_pts,
    correct = correct + (case when v_ok then 1 else 0 end)
    where game_id = p_game and user_id = me;
  perform club_housekeeping();
  return jsonb_build_object('correct', v_ok, 'points', v_pts, 'right', v_right);
end $$;

-- Kampene til klubbene mine de siste 14 dagene, med lagoppstilling og stilling.
create or replace function public.club_game_list()
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid();
begin
  perform club_housekeeping();
  return (select coalesce(jsonb_agg(jsonb_build_object(
      'id', c.id, 'status', c.status, 'size', c.size, 'window_min', c.window_min,
      'kickoff_ms', (extract(epoch from c.kickoff) * 1000)::bigint,
      'ends_ms', (extract(epoch from club_ends(c)) * 1000)::bigint,
      'now_ms', (extract(epoch from clock_timestamp()) * 1000)::bigint,
      'winner', c.winner,
      'home', (select jsonb_build_object('id', g.id, 'name', g.name, 'color1', g.color1,
                 'color2', g.color2, 'emblem', g.emblem, 'mine', club_is_member(g.id))
               from groups g where g.id = c.home),
      'away', (select jsonb_build_object('id', g.id, 'name', g.name, 'color1', g.color1,
                 'color2', g.color2, 'emblem', g.emblem, 'mine', club_is_member(g.id))
               from groups g where g.id = c.away),
      'players', (select coalesce(jsonb_agg(jsonb_build_object(
                    'name', pr.username, 'club', p.club, 'score', p.score, 'answered', p.idx,
                    'me', p.user_id = me) order by p.club, p.slot), '[]'::jsonb)
                  from club_game_players p join profiles pr on pr.id = p.user_id where p.game_id = c.id)
    ) order by c.kickoff desc), '[]'::jsonb)
    from club_games c
    where (club_is_member(c.home) or club_is_member(c.away))
      and c.kickoff > now() - interval '14 days');
end $$;

revoke execute on function
  public.club_is_member(uuid), public.club_ends(public.club_games), public.club_housekeeping(),
  public.club_my_clubs(), public.club_set_look(uuid, int, int, int), public.club_join(uuid, uuid),
  public.club_leave_game(uuid), public.club_challenge(uuid, text, int, timestamptz, int),
  public.club_respond(uuid, boolean), public.club_cancel(uuid), public.club_next(uuid),
  public.club_answer(uuid, int, text), public.club_game_list()
  from public, anon, authenticated;
grant execute on function
  public.club_my_clubs(), public.club_set_look(uuid, int, int, int), public.club_join(uuid, uuid),
  public.club_leave_game(uuid), public.club_challenge(uuid, text, int, timestamptz, int),
  public.club_respond(uuid, boolean), public.club_cancel(uuid), public.club_next(uuid),
  public.club_answer(uuid, int, text), public.club_game_list()
  to authenticated;
