-- Poengvalidering på serveren (kjøres i SQL Editor før answers.sql).
-- Klienten sender svarene sine; serveren regner ut poengene selv.

create table if not exists public.quiz_answers (
  key text primary key,
  type text not null check (type in ('rules_quiz', 'image_sort')),
  answer_hash text not null
);
create table if not exists public.question_log (
  user_id uuid not null references public.profiles(id) on delete cascade,
  key text not null,
  answered_at timestamptz not null default now()
);
create index if not exists question_log_user_idx on public.question_log (user_id, key, answered_at desc);
alter table public.quiz_answers enable row level security;
alter table public.question_log enable row level security;
-- Ingen policyer og ingen rettigheter: bare funksjonen under (security definer) når tabellene.

-- p_answers: [{"key": "...", "answer": "tekst"}] (regler) eller [{"key": "...", "answer": ["a","b",...]}] (sortering)
create or replace function public.submit_round(p_mode text, p_answers jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_last timestamptz; v_today int; v_points int := 0; v_n int;
  a jsonb; v_key text; v_hash text; v_ans text; v_type text; v_fresh boolean;
begin
  if auth.uid() is null or not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'no_profile'; end if;
  if p_mode not in ('rules_quiz', 'image_sort') then raise exception 'bad_mode'; end if;
  if jsonb_typeof(p_answers) <> 'array' then raise exception 'bad_answers'; end if;
  v_n := jsonb_array_length(p_answers);
  if v_n < 1 or v_n > 12 then raise exception 'bad_answers'; end if;
  if (select count(distinct x ->> 'key') from jsonb_array_elements(p_answers) x) <> v_n then
    raise exception 'bad_answers'; end if;

  select max(created_at), count(*) filter (where created_at > now() - interval '24 hours')
    into v_last, v_today from scores where user_id = auth.uid();
  if v_last is not null and v_last > now() - interval '20 seconds' then raise exception 'too_fast'; end if;
  if v_today >= 150 then raise exception 'daily_limit'; end if;

  for a in select * from jsonb_array_elements(p_answers) loop
    v_key := a ->> 'key';
    select type, answer_hash into v_type, v_hash from quiz_answers where key = v_key;
    if not found or v_type <> p_mode then raise exception 'bad_question'; end if;
    if jsonb_typeof(a -> 'answer') = 'array' then
      select string_agg(t, '|' order by o) into v_ans from jsonb_array_elements_text(a -> 'answer') with ordinality as e(t, o);
    else
      v_ans := a ->> 'answer';
    end if;
    v_fresh := not exists (select 1 from question_log
      where user_id = auth.uid() and key = v_key and answered_at > now() - interval '24 hours');
    insert into question_log (user_id, key) values (auth.uid(), v_key);
    if left(md5(v_key || ':' || coalesce(v_ans, '')), 10) = v_hash then
      if v_fresh then v_points := v_points + 2; end if;      -- samme spørsmål gir poeng én gang pr. døgn
    else
      v_points := v_points - 1;
    end if;
  end loop;

  if v_points > 0 then
    insert into scores (user_id, mode, points) values (auth.uid(), p_mode, v_points);
  end if;
  return greatest(v_points, 0);
end $$;

revoke execute on function public.submit_round(text, jsonb) from public, anon;
grant execute on function public.submit_round(text, jsonb) to authenticated;

-- submit_score tar nå bare geografi og bildequiz (de sjekkes ikke ennå, bare begrenset)
create or replace function public.submit_score(p_mode text, p_points int)
returns void language plpgsql security definer set search_path = public as $$
declare v_max int; v_last timestamptz; v_today int;
begin
  if auth.uid() is null or not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'no_profile'; end if;
  v_max := case
    when p_mode in ('photo_mixed', 'photo_player', 'photo_goalkeeper', 'photo_country', 'photo_stadium') then 20
    when p_mode = 'geo' then 50
    else null end;
  if v_max is null then raise exception 'bad_mode'; end if;
  if p_points is null or p_points < 1 or p_points > v_max then raise exception 'bad_points'; end if;
  select max(created_at), count(*) filter (where created_at > now() - interval '24 hours')
    into v_last, v_today from scores where user_id = auth.uid();
  if v_last is not null and v_last > now() - interval '20 seconds' then raise exception 'too_fast'; end if;
  if v_today >= 150 then raise exception 'daily_limit'; end if;
  insert into scores (user_id, mode, points) values (auth.uid(), p_mode, p_points);
end $$;
