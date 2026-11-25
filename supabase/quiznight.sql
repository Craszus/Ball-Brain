-- Quizkveld: verten styrer en quiz, deltakerne svarer på hver sin mobil (kjøres i SQL Editor).
-- Flyt: quiz_create -> quiz_join (kode) -> quiz_next (verten) -> quiz_answer -> quiz_next ... ->
-- ferdig. Alle henter quiz_state jevnlig. Fasiten sendes aldri før spørsmålet er stengt.
-- Tabellene har RLS uten policyer: all tilgang går gjennom funksjonene.

create table if not exists public.quiz_nights (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  host uuid not null references public.profiles(id) on delete cascade,
  host_plays boolean not null default false,
  status text not null default 'lobby'
    check (status in ('lobby', 'question', 'reveal', 'finished', 'cancelled')),
  questions jsonb not null,          -- [{prompt, era, options (stokket), right}]
  seconds int not null,
  current int not null default 0,
  q_started timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists quiz_nights_host_idx on public.quiz_nights (host, created_at desc);

create table if not exists public.quiz_players (
  night uuid not null references public.quiz_nights(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  score int not null default 0,
  correct int not null default 0,
  ms bigint not null default 0,
  joined_at timestamptz not null default now(),
  primary key (night, user_id)
);
create index if not exists quiz_players_user_idx on public.quiz_players (user_id);

create table if not exists public.quiz_night_answers (
  night uuid not null references public.quiz_nights(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  idx int not null,
  answer text,
  correct boolean not null,
  points int not null,
  primary key (night, user_id, idx)
);

alter table public.quiz_nights enable row level security;
alter table public.quiz_players enable row level security;
alter table public.quiz_night_answers enable row level security;

-- Hele tilstanden sett fra den som spør. Stenger også spørsmålet når tiden er ute eller alle har
-- svart (så ingen trenger å trykke).
create or replace function public.quiz_state(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare n quiz_nights; me uuid := auth.uid(); q jsonb; players int; answered int;
  is_host boolean; mine quiz_players; a quiz_night_answers; ranked jsonb; my_rank int;
begin
  select * into n from quiz_nights where id = p_id;
  if not found then raise exception 'not_found'; end if;
  is_host := n.host = me;
  select * into mine from quiz_players where night = p_id and user_id = me;
  if not is_host and mine.user_id is null then raise exception 'not_found'; end if;

  select count(*) into players from quiz_players where night = p_id;
  select count(*) into answered from quiz_night_answers where night = p_id and idx = n.current;
  if n.status = 'question' and (clock_timestamp() > n.q_started + make_interval(secs => n.seconds + 1)
                                or (players > 0 and answered >= players)) then
    update quiz_nights set status = 'reveal' where id = p_id and status = 'question' and current = n.current;
    n.status := 'reveal';
  end if;

  q := n.questions -> n.current;
  select * into a from quiz_night_answers where night = p_id and user_id = me and idx = n.current;
  with r as (
    select p.user_id, pr.username, p.score, p.correct,
           rank() over (order by p.score desc, p.ms) as pos
    from quiz_players p join profiles pr on pr.id = p.user_id where p.night = p_id
  )
  select coalesce(jsonb_agg(jsonb_build_object('rank', pos, 'name', username, 'score', score,
             'correct', correct, 'me', user_id = me) order by pos, username)
           filter (where pos <= 100), '[]'::jsonb),
         max(pos) filter (where user_id = me)
    into ranked, my_rank from r;

  return jsonb_build_object(
    'id', n.id, 'code', n.code, 'status', n.status, 'idx', n.current,
    'total', jsonb_array_length(n.questions), 'seconds', n.seconds,
    'host', is_host, 'playing', mine.user_id is not null,
    'players', players, 'answered', answered,
    'left_ms', case when n.status = 'question' then greatest(0,
        (extract(epoch from (n.q_started + make_interval(secs => n.seconds) - clock_timestamp())) * 1000)::int) end,
    'question', case when n.status in ('question', 'reveal') then
        jsonb_build_object('prompt', q ->> 'prompt', 'era', q ->> 'era', 'options', q -> 'options') end,
    'right', case when n.status = 'reveal' then q ->> 'right' end,
    'my_answer', a.answer,
    'my_answered', a.user_id is not null,
    'my_points', case when n.status = 'reveal' then a.points end,
    'my_score', mine.score,
    'my_rank', my_rank,
    -- resultatlisten holdes skjult mens spørsmålet er åpent
    'standings', case when n.status = 'question' then '[]'::jsonb else ranked end);
end $$;

create or replace function public.quiz_create(p_count int, p_seconds int, p_eras text[], p_host_plays boolean)
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); v_code text; v_id uuid; qs jsonb;
begin
  if me is null or not exists (select 1 from profiles where id = me) then raise exception 'no_profile'; end if;
  if p_count not between 5 and 30 or p_seconds not between 10 and 60 then raise exception 'bad_setup'; end if;
  delete from quiz_nights where created_at < now() - interval '7 days';
  update quiz_nights set status = 'cancelled' where host = me and status not in ('finished', 'cancelled');
  if (select count(*) from quiz_nights where host = me and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'daily_limit'; end if;

  -- trekk spørsmål, stokk svarene og sorter lett -> vanskelig
  select jsonb_agg(item order by difficulty, r) into qs from (
    select t.difficulty, random() as r, jsonb_build_object(
        'prompt', t.prompt, 'era', t.era,
        'right', t.options ->> ((t.correct #>> '{}')::int),
        'options', case when t.options @> '["Ja","Nei"]'::jsonb and jsonb_array_length(t.options) = 2
                        then t.options
                        else (select jsonb_agg(o order by random()) from jsonb_array_elements(t.options) o) end
      ) as item
    from (select * from questions
          where type = 'rules_quiz' and active
            and (p_eras is null or cardinality(p_eras) = 0 or era = any (p_eras))
          order by random() limit p_count) t
  ) s;
  if qs is null or jsonb_array_length(qs) < 5 then raise exception 'bad_setup'; end if;

  loop
    v_code := upper(substr(translate(md5(random()::text || clock_timestamp()::text), '01', 'XY'), 1, 5));
    exit when not exists (select 1 from quiz_nights x where x.code = v_code);
  end loop;
  insert into quiz_nights (code, host, host_plays, questions, seconds)
    values (v_code, me, coalesce(p_host_plays, false), qs, p_seconds) returning id into v_id;
  if p_host_plays then insert into quiz_players (night, user_id) values (v_id, me); end if;
  return quiz_state(v_id);
end $$;

create or replace function public.quiz_join(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare n quiz_nights; me uuid := auth.uid();
begin
  if me is null or not exists (select 1 from profiles where id = me) then raise exception 'no_profile'; end if;
  select * into n from quiz_nights where code = upper(trim(p_code))
    and status not in ('finished', 'cancelled') and created_at > now() - interval '12 hours' for update;
  if not found then raise exception 'not_found'; end if;
  if n.host <> me and not exists (select 1 from quiz_players where night = n.id and user_id = me) then
    if (select count(*) from quiz_players where night = n.id) >= 100 then raise exception 'full'; end if;
    insert into quiz_players (night, user_id) values (n.id, me);
  end if;
  return quiz_state(n.id);
end $$;

-- Kvelden jeg er midt i (hvis appen ble lukket), ellers null.
create or replace function public.quiz_mine()
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; me uuid := auth.uid();
begin
  select n.id into v_id from quiz_nights n
    where n.status not in ('finished', 'cancelled') and n.created_at > now() - interval '6 hours'
      and (n.host = me or exists (select 1 from quiz_players p where p.night = n.id and p.user_id = me))
    order by n.created_at desc limit 1;
  if v_id is null then return null; end if;
  return quiz_state(v_id);
end $$;

-- Verten går videre: lobby -> spørsmål -> svar -> neste spørsmål ... -> ferdig.
-- p_status/p_idx er det verten ser, så et dobbelttrykk ikke hopper over noe.
create or replace function public.quiz_next(p_id uuid, p_status text, p_idx int)
returns jsonb language plpgsql security definer set search_path = public as $$
declare n quiz_nights;
begin
  select * into n from quiz_nights where id = p_id and host = auth.uid() for update;
  if not found then raise exception 'not_found'; end if;
  if n.status = p_status and n.current = p_idx then
    if n.status = 'lobby' then
      if not exists (select 1 from quiz_players where night = p_id) then raise exception 'no_players'; end if;
      update quiz_nights set status = 'question', q_started = clock_timestamp() where id = p_id;
    elsif n.status = 'question' then
      update quiz_nights set status = 'reveal' where id = p_id;
    elsif n.status = 'reveal' then
      if n.current + 1 >= jsonb_array_length(n.questions) then
        update quiz_nights set status = 'finished' where id = p_id;
      else
        update quiz_nights set status = 'question', current = n.current + 1, q_started = clock_timestamp()
          where id = p_id;
      end if;
    end if;
  end if;
  return quiz_state(p_id);
end $$;

create or replace function public.quiz_answer(p_id uuid, p_idx int, p_answer text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare n quiz_nights; me uuid := auth.uid(); left_s numeric; ok boolean; pts int := 0;
begin
  select * into n from quiz_nights where id = p_id for update;
  if not found or not exists (select 1 from quiz_players where night = p_id and user_id = me) then
    raise exception 'not_found'; end if;
  if n.status <> 'question' or n.current <> p_idx then raise exception 'not_active'; end if;
  left_s := extract(epoch from (n.q_started + make_interval(secs => n.seconds) - clock_timestamp()));
  if left_s < -1.5 then raise exception 'not_active'; end if;
  left_s := greatest(0, least(left_s, n.seconds));
  ok := coalesce(p_answer = (n.questions -> n.current ->> 'right'), false);
  if ok then pts := 10 + round(5 * left_s / n.seconds); end if;
  insert into quiz_night_answers (night, user_id, idx, answer, correct, points)
    values (p_id, me, p_idx, p_answer, ok, pts) on conflict do nothing;
  if found then
    update quiz_players set score = score + pts, correct = correct + ok::int,
        ms = ms + case when ok then ((n.seconds - left_s) * 1000)::bigint else 0 end
      where night = p_id and user_id = me;
  end if;
  return quiz_state(p_id);
end $$;

-- Deltaker går ut, eller verten avslutter kvelden for alle.
create or replace function public.quiz_leave(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update quiz_nights set status = 'cancelled'
    where id = p_id and host = auth.uid() and status not in ('finished', 'cancelled');
  delete from quiz_players p using quiz_nights n
    where p.night = p_id and p.user_id = auth.uid() and n.id = p_id and n.host <> auth.uid()
      and n.status not in ('finished', 'cancelled');
end $$;

revoke execute on function public.quiz_state(uuid), public.quiz_create(int, int, text[], boolean),
  public.quiz_join(text), public.quiz_mine(), public.quiz_next(uuid, text, int),
  public.quiz_answer(uuid, int, text), public.quiz_leave(uuid) from public, anon;
grant execute on function public.quiz_state(uuid), public.quiz_create(int, int, text[], boolean),
  public.quiz_join(text), public.quiz_mine(), public.quiz_next(uuid, text, int),
  public.quiz_answer(uuid, int, text), public.quiz_leave(uuid) to authenticated;
