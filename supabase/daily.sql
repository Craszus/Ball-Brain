-- Dagens utfordring med egen rangering (dag og uke). Kjøres i SQL Editor.
-- Alle får de samme ti spørsmålene hver dag (norsk døgn). Bare første forsøk teller.
-- Rangert etter antall riktige, deretter kortest tid. Uka (mandag–søndag) er summen av dagene.

create table if not exists public.daily_sets (
  day date primary key,
  keys text[] not null
);
create table if not exists public.daily_results (
  user_id uuid not null references public.profiles(id) on delete cascade,
  day date not null,
  started_at timestamptz not null default clock_timestamp(),
  finished_at timestamptz,
  correct int,
  ms int,
  token uuid not null default gen_random_uuid(),
  primary key (user_id, day)
);
create index if not exists daily_results_day_idx on public.daily_results (day, correct desc, ms);
alter table public.daily_sets enable row level security;
alter table public.daily_results enable row level security;
-- Ingen policyer og ingen rettigheter: bare funksjonene under (security definer) når tabellene.
revoke all on public.daily_sets, public.daily_results from anon, authenticated;

create or replace function public.daily_today()
returns date language sql stable set search_path = public as $$
  select (now() at time zone 'Europe/Oslo')::date
$$;

-- Dagens spørsmål. «token» gis bare første gang spilleren starter i dag; uten det kan
-- resultatet ikke leveres, så bare første forsøk teller.
create or replace function public.daily_start()
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); v_day date := daily_today(); v_keys text[]; v_token uuid;
begin
  if not exists (select 1 from profiles where id = me) then raise exception 'no_profile'; end if;
  insert into daily_sets (day, keys)
    select v_day, array_agg(key) from (
      select key from questions where type = 'rules_quiz' and active and key is not null
      order by md5(key || v_day::text) limit 10) s
    on conflict (day) do nothing;
  select keys into v_keys from daily_sets where day = v_day;
  insert into daily_results (user_id, day) values (me, v_day)
    on conflict do nothing returning token into v_token;
  return jsonb_build_object(
    'day', v_day,
    'token', v_token,
    'questions', (select jsonb_agg(jsonb_build_object(
        'id', q.id, 'type', q.type, 'era', q.era, 'prompt', q.prompt, 'options', q.options,
        'correct', q.correct, 'difficulty', q.difficulty, 'key', q.key)
        order by q.difficulty, md5(q.key || v_day::text))
      from questions q where q.key = any (v_keys)));
end $$;

-- p_answers: [{"key": "...", "answer": "valgt tekst"}]. Teller bare én gang, innen 30 minutter.
create or replace function public.daily_submit(p_token uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); r daily_results; v_keys text[]; v_correct int;
begin
  if jsonb_typeof(p_answers) <> 'array' or jsonb_array_length(p_answers) > 10 then
    raise exception 'bad_answers'; end if;
  select * into r from daily_results where user_id = me and token = p_token for update;
  if not found or r.finished_at is not null or r.started_at < clock_timestamp() - interval '30 minutes' then
    return jsonb_build_object('counted', false);
  end if;
  select keys into v_keys from daily_sets where day = r.day;
  select count(distinct q.key) into v_correct
    from jsonb_array_elements(p_answers) a
    join questions q on q.key = a ->> 'key' and q.key = any (v_keys)
    where a ->> 'answer' = q.options ->> ((q.correct #>> '{}')::int)
      -- flere svar på samme spørsmål teller ikke
      and (select count(*) from jsonb_array_elements(p_answers) b where b ->> 'key' = q.key) = 1;
  update daily_results set finished_at = clock_timestamp(), correct = v_correct,
      ms = (extract(epoch from clock_timestamp() - r.started_at) * 1000)::int
    where user_id = me and day = r.day;
  return jsonb_build_object('counted', true, 'correct', v_correct);
end $$;

-- p_period: 'day' | 'week'. p_scope: 'country' | 'world' | 'friends' (alle i gruppene mine).
-- Gir topp 50, pluss min egen rad hvis jeg er lenger nede.
create or replace function public.daily_board(p_period text, p_scope text)
returns table (rank bigint, user_id uuid, username text, country_code text,
               correct bigint, ms bigint, days bigint)
language plpgsql security definer set search_path = public as $$
#variable_conflict use_column
declare me uuid := auth.uid(); v_to date := daily_today(); v_from date; v_country text;
begin
  v_from := case when p_period = 'week' then date_trunc('week', v_to)::date else v_to end;
  select p.country_code into v_country from profiles p where p.id = me;
  return query
    with sums as (
      select d.user_id, sum(d.correct)::bigint as correct, sum(d.ms)::bigint as ms, count(*)::bigint as days
      from daily_results d
      where d.day between v_from and v_to and d.finished_at is not null
      group by d.user_id),
    ranked as (
      select rank() over (order by s.correct desc, s.ms) as rank, s.user_id, p.username,
             p.country_code::text as country_code, s.correct, s.ms, s.days
      from sums s join profiles p on p.id = s.user_id
      where p_scope = 'world'
         or (p_scope = 'country' and p.country_code = v_country)
         or (p_scope = 'friends' and (s.user_id = me or exists (
               select 1 from group_members a join group_members b on a.group_id = b.group_id
               where a.user_id = me and b.user_id = s.user_id))))
    select r.rank, r.user_id, r.username, r.country_code, r.correct, r.ms, r.days
    from ranked r
    where r.rank <= 50 or r.user_id = me
    order by r.rank, r.username
    limit 60;
end $$;

revoke execute on function public.daily_today(), public.daily_start(),
  public.daily_submit(uuid, jsonb), public.daily_board(text, text) from public, anon;
grant execute on function public.daily_start(), public.daily_submit(uuid, jsonb),
  public.daily_board(text, text) to authenticated;
