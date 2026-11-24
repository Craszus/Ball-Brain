-- 1v1: serverstyrt. Spørsmål, tid og poeng avgjøres av databasen (kjøres i SQL Editor).
-- Flyt: duel_find / duel_create_private / duel_join -> duel_get (+ Realtime) -> duel_questions ->
-- duel_answer x10 -> ferdig (vinner avgjøres på serveren).

create table if not exists public.duels (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  is_public boolean not null default false,
  status text not null default 'waiting' check (status in ('waiting', 'active', 'finished', 'cancelled')),
  p1 uuid not null references public.profiles(id) on delete cascade,
  p2 uuid references public.profiles(id) on delete cascade,
  question_keys text[] not null default '{}',
  created_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  winner uuid,
  p1_score int not null default 0, p2_score int not null default 0,
  p1_answered int not null default 0, p2_answered int not null default 0,
  p1_correct int not null default 0, p2_correct int not null default 0,
  p1_ms bigint not null default 0, p2_ms bigint not null default 0,
  p1_last timestamptz, p2_last timestamptz,
  p1_done_at timestamptz, p2_done_at timestamptz
);
create index if not exists duels_p1_idx on public.duels (p1, created_at desc);
create index if not exists duels_p2_idx on public.duels (p2, created_at desc);
create index if not exists duels_waiting_idx on public.duels (status, is_public, created_at);

create table if not exists public.duel_answers (
  duel_id uuid not null references public.duels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  idx int not null,
  answer text,
  correct boolean not null,
  ms int not null,
  points int not null,
  primary key (duel_id, user_id, idx)
);
alter table public.duels enable row level security;
alter table public.duel_answers enable row level security;

-- Deltakerne kan lese oppgjøret sitt (trengs for Realtime). Ingen skriving fra klienten.
drop policy if exists "deltakere leser egne oppgjør" on public.duels;
create policy "deltakere leser egne oppgjør" on public.duels
  for select to authenticated using (p1 = auth.uid() or p2 = auth.uid());
grant select on public.duels to authenticated;

do $$ begin
  alter publication supabase_realtime add table public.duels;
exception when duplicate_object then null; end $$;

-- Sammendrag sett fra den som spør (jsonb). Intern.
create or replace function public.duel_summary(d public.duels)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare me uuid := auth.uid(); mine boolean := (d.p1 = me); opp uuid; o profiles; m profiles;
begin
  opp := case when mine then d.p2 else d.p1 end;
  select * into o from profiles where id = opp;
  select * into m from profiles where id = me;
  return jsonb_build_object(
    'id', d.id, 'code', d.code, 'status', d.status, 'total', coalesce(array_length(d.question_keys, 1), 0),
    'now_ms', (extract(epoch from clock_timestamp()) * 1000)::bigint,
    'starts_ms', case when d.started_at is null then null else (extract(epoch from d.started_at) * 1000)::bigint end,
    'me', jsonb_build_object('name', m.username, 'country', m.country_code,
      'score', case when mine then d.p1_score else d.p2_score end,
      'answered', case when mine then d.p1_answered else d.p2_answered end,
      'correct', case when mine then d.p1_correct else d.p2_correct end),
    'opp', case when opp is null then null else jsonb_build_object('name', o.username, 'country', o.country_code,
      'score', case when mine then d.p2_score else d.p1_score end,
      'answered', case when mine then d.p2_answered else d.p1_answered end,
      'correct', case when mine then d.p2_correct else d.p1_correct end) end,
    'result', case when d.status <> 'finished' then null
                   when d.winner is null then 'draw'
                   when d.winner = me then 'win' else 'loss' end);
end $$;
revoke execute on function public.duel_summary(public.duels) from public, anon, authenticated;

-- Avslutter et aktivt oppgjør og avgjør vinneren (høyest poeng, så lavest samlet tid). Intern.
create or replace function public.duel_finalize(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare d duels; w uuid;
begin
  select * into d from duels where id = p_id and status = 'active' for update;
  if not found then return; end if;
  if d.p1_score > d.p2_score then w := d.p1;
  elsif d.p2_score > d.p1_score then w := d.p2;
  elsif d.p1_ms < d.p2_ms then w := d.p1;
  elsif d.p2_ms < d.p1_ms then w := d.p2;
  else w := null; end if;
  update duels set status = 'finished', finished_at = now(), winner = w where id = p_id;
end $$;
revoke execute on function public.duel_finalize(uuid) from public, anon, authenticated;

-- Rydder gamle oppgjør og begrenser antall pr. døgn. Intern.
create or replace function public.duel_housekeeping()
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'no_profile'; end if;
  update duels set status = 'cancelled' where status = 'waiting' and created_at < now() - interval '5 minutes';
  update duels set status = 'cancelled' where status = 'active' and started_at < now() - interval '15 minutes';
end $$;
revoke execute on function public.duel_housekeeping() from public, anon, authenticated;

-- Starter oppgjøret: trekker 10 regelspørsmål (lett -> vanskelig) og setter start 4 sekunder frem i tid.
create or replace function public.duel_start(p_id uuid, p_p2 uuid)
returns void language plpgsql security definer set search_path = public as $$
declare keys text[]; st timestamptz := now() + interval '4 seconds';
begin
  select array_agg(key order by difficulty, random()) into keys from (
    select key, difficulty from questions where type = 'rules_quiz' and active order by random() limit 10) q;
  update duels set status = 'active', p2 = p_p2, question_keys = keys, started_at = st,
    p1_last = st, p2_last = st where id = p_id;
end $$;
revoke execute on function public.duel_start(uuid, uuid) from public, anon, authenticated;

-- Raskt oppgjør: bli med i en ventende offentlig kamp, ellers lag en. Gjenopptar pågående kamp.
create or replace function public.duel_find()
returns jsonb language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid();
begin
  perform duel_housekeeping();
  select * into d from duels where status in ('waiting', 'active') and (p1 = me or p2 = me)
    and not ((p1 = me and p1_done_at is not null) or (p2 = me and p2_done_at is not null))
    order by created_at desc limit 1;
  if found then return duel_summary(d); end if;
  if (select count(*) from duels where (p1 = me or p2 = me) and created_at > now() - interval '24 hours') >= 40 then
    raise exception 'daily_limit'; end if;
  select * into d from duels where status = 'waiting' and is_public and p1 <> me
    order by created_at limit 1 for update skip locked;
  if found then
    perform duel_start(d.id, me);
    select * into d from duels where id = d.id;
    return duel_summary(d);
  end if;
  insert into duels (is_public, p1) values (true, me) returning * into d;
  return duel_summary(d);
end $$;

-- Utfordre en venn: lager en kamp med kode.
create or replace function public.duel_create_private()
returns jsonb language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid(); v_code text;
begin
  perform duel_housekeeping();
  update duels set status = 'cancelled' where status = 'waiting' and p1 = me;
  if (select count(*) from duels where (p1 = me or p2 = me) and created_at > now() - interval '24 hours') >= 40 then
    raise exception 'daily_limit'; end if;
  loop
    v_code := upper(substr(translate(md5(random()::text || clock_timestamp()::text), '01', 'XY'), 1, 5));
    exit when not exists (select 1 from duels x where x.code = v_code);
  end loop;
  insert into duels (code, is_public, p1) values (v_code, false, me) returning * into d;
  return duel_summary(d);
end $$;

create or replace function public.duel_join(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid();
begin
  perform duel_housekeeping();
  select * into d from duels where code = upper(btrim(p_code)) and status = 'waiting' for update;
  if not found then raise exception 'not_found'; end if;
  if d.p1 = me then raise exception 'own_duel'; end if;
  perform duel_start(d.id, me);
  select * into d from duels where id = d.id;
  return duel_summary(d);
end $$;

-- Avbryt en ventende kamp.
create or replace function public.duel_cancel(p_id uuid)
returns void language sql security definer set search_path = public as $$
  update duels set status = 'cancelled' where id = p_id and p1 = auth.uid() and status = 'waiting';
$$;

-- Status akkurat nå. Avslutter kampen hvis motstanderen har vært borte i over 60 sekunder.
create or replace function public.duel_get(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid();
begin
  select * into d from duels where id = p_id and (p1 = me or p2 = me);
  if not found then raise exception 'not_found'; end if;
  if d.status = 'active' and (d.p1_done_at is null) <> (d.p2_done_at is null)
     and now() - coalesce(d.p1_done_at, d.p2_done_at) > interval '60 seconds' then
    perform duel_finalize(p_id);
    select * into d from duels where id = p_id;
  end if;
  return duel_summary(d);
end $$;

-- Spørsmålene (uten fasit). Først tilgjengelig for deltakerne når kampen er i gang.
create or replace function public.duel_questions(p_id uuid)
returns table(idx int, key text, era text, prompt text, options jsonb)
language plpgsql stable security definer set search_path = public as $$
declare d duels; me uuid := auth.uid();
begin
  select * into d from duels where id = p_id and (p1 = me or p2 = me) and status in ('active', 'finished');
  if not found then raise exception 'not_found'; end if;
  return query
    select (k.o - 1)::int, q.key, q.era, q.prompt, q.options
    from unnest(d.question_keys) with ordinality as k(key, o) join questions q on q.key = k.key
    order by k.o;
end $$;

-- Svar på spørsmål nr. p_idx (0-basert). p_answer = valgt tekst, eller null når tiden gikk ut.
-- 15 sekunder pr. spørsmål; riktig svar gir 10 poeng + opptil 5 for fart.
create or replace function public.duel_answer(p_id uuid, p_idx int, p_answer text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  d duels; me uuid := auth.uid(); mine boolean; base timestamptz; ms int; v_right text; v_ok boolean;
  v_pts int; v_answered int; v_total int; v_opts jsonb; v_corr jsonb; v_both boolean;
begin
  select * into d from duels where id = p_id and (p1 = me or p2 = me) for update;
  if not found then raise exception 'not_found'; end if;
  if d.status <> 'active' then raise exception 'not_active'; end if;
  mine := (d.p1 = me);
  v_answered := case when mine then d.p1_answered else d.p2_answered end;
  v_total := array_length(d.question_keys, 1);
  if p_idx <> v_answered or p_idx >= v_total then raise exception 'bad_index'; end if;
  base := (case when mine then d.p1_last else d.p2_last end)
    + (case when v_answered = 0 then interval '0' else interval '1 second' end); -- 1 s pause for svar-feedback
  if now() < d.started_at - interval '1 second' then raise exception 'not_started'; end if;
  ms := greatest(0, (extract(epoch from now() - base) * 1000)::int);
  select q.options, q.correct into v_opts, v_corr from questions q where q.key = d.question_keys[p_idx + 1];
  v_right := v_opts ->> ((v_corr #>> '{}')::int);
  v_ok := p_answer is not null and p_answer = v_right and ms <= 16500;
  v_pts := case when v_ok then 10 + least(5, greatest(0, ((15000 - ms) / 3000))) else 0 end;
  insert into duel_answers (duel_id, user_id, idx, answer, correct, ms, points)
    values (p_id, me, p_idx, p_answer, v_ok, least(ms, 20000), v_pts);
  if mine then
    update duels set p1_answered = p1_answered + 1, p1_score = p1_score + v_pts,
      p1_correct = p1_correct + (case when v_ok then 1 else 0 end), p1_ms = p1_ms + least(ms, 20000),
      p1_last = now(), p1_done_at = case when p1_answered + 1 >= v_total then now() else p1_done_at end
      where id = p_id;
  else
    update duels set p2_answered = p2_answered + 1, p2_score = p2_score + v_pts,
      p2_correct = p2_correct + (case when v_ok then 1 else 0 end), p2_ms = p2_ms + least(ms, 20000),
      p2_last = now(), p2_done_at = case when p2_answered + 1 >= v_total then now() else p2_done_at end
      where id = p_id;
  end if;
  select (p1_done_at is not null and p2_done_at is not null) into v_both from duels where id = p_id;
  if v_both then perform duel_finalize(p_id); end if;
  return jsonb_build_object('correct', v_ok, 'points', v_pts, 'right', v_right, 'ms', ms);
end $$;

revoke execute on function
  public.duel_find(), public.duel_create_private(), public.duel_join(text), public.duel_cancel(uuid),
  public.duel_get(uuid), public.duel_questions(uuid), public.duel_answer(uuid, int, text)
  from public, anon;
grant execute on function
  public.duel_find(), public.duel_create_private(), public.duel_join(text), public.duel_cancel(uuid),
  public.duel_get(uuid), public.duel_questions(uuid), public.duel_answer(uuid, int, text)
  to authenticated;
