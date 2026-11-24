-- Serverstyrt poengberegning for geografi og bildequiz (kjøres i SQL Editor etter validate_rounds.sql).
-- Fasitdata (steder og bildesvar) lastes med tools/make_media_answers.py.

create table if not exists public.geo_places (
  id text primary key,
  lat double precision not null,
  lon double precision not null
);
create table if not exists public.photo_answers (
  item text not null,      -- 'player:<id>' eller 'stadium:<id>'
  qtype text not null,     -- 'name' | 'country' | 'club'
  answer text not null,
  primary key (item, qtype)
);
alter table public.geo_places enable row level security;
alter table public.photo_answers enable row level security;

-- Felles vakt: profil finnes, minst 20 s siden forrige runde, maks 150 runder pr. døgn.
create or replace function public.round_guard()
returns void language plpgsql security definer set search_path = public as $$
declare v_last timestamptz; v_today int;
begin
  if auth.uid() is null or not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'no_profile'; end if;
  select max(created_at), count(*) filter (where created_at > now() - interval '24 hours')
    into v_last, v_today from scores where user_id = auth.uid();
  if v_last is not null and v_last > now() - interval '20 seconds' then raise exception 'too_fast'; end if;
  if v_today >= 150 then raise exception 'daily_limit'; end if;
end $$;
revoke execute on function public.round_guard() from public, anon, authenticated;

-- p_answers: [{"id": "...", "lat": 59.9, "lon": 10.7}] (lat/lon null = tiden gikk ut)
create or replace function public.submit_geo(p_answers jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare
  a jsonb; v_n int; v_points int := 0; v_id text; g geo_places; v_lat double precision; v_lon double precision;
  v_km double precision; v_xp int; v_fresh boolean;
begin
  perform round_guard();
  if jsonb_typeof(p_answers) <> 'array' then raise exception 'bad_answers'; end if;
  v_n := jsonb_array_length(p_answers);
  if v_n < 1 or v_n > 12 then raise exception 'bad_answers'; end if;
  if (select count(distinct x ->> 'id') from jsonb_array_elements(p_answers) x) <> v_n then
    raise exception 'bad_answers'; end if;
  for a in select * from jsonb_array_elements(p_answers) loop
    v_id := a ->> 'id';
    select * into g from geo_places where id = v_id;
    if not found then raise exception 'bad_question'; end if;
    if jsonb_typeof(a -> 'lat') = 'number' and jsonb_typeof(a -> 'lon') = 'number' then
      v_lat := (a ->> 'lat')::double precision; v_lon := (a ->> 'lon')::double precision;
      v_km := 2 * 6371.0088 * asin(least(1, sqrt(
        power(sin(radians(g.lat - v_lat) / 2), 2) +
        cos(radians(v_lat)) * cos(radians(g.lat)) * power(sin(radians(g.lon - v_lon) / 2), 2))));
      v_xp := case when v_km <= 25 then 5 when v_km <= 100 then 3 when v_km <= 500 then 2
                   when v_km <= 1500 then 1 else -1 end;
    else
      v_xp := -1;
    end if;
    v_fresh := not exists (select 1 from question_log
      where user_id = auth.uid() and key = 'geo:' || v_id and answered_at > now() - interval '24 hours');
    insert into question_log (user_id, key) values (auth.uid(), 'geo:' || v_id);
    if v_xp > 0 and not v_fresh then v_xp := 0; end if;     -- samme sted gir poeng én gang pr. døgn
    v_points := v_points + v_xp;
  end loop;
  if v_points > 0 then
    insert into scores (user_id, mode, points) values (auth.uid(), 'geo', v_points);
  end if;
  return greatest(v_points, 0);
end $$;

-- p_answers: [{"item": "player:abc", "q": "name|country|club", "answer": "valgt tekst"}]
create or replace function public.submit_photo(p_mode text, p_answers jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare
  a jsonb; v_n int; v_points int := 0; v_item text; v_q text; v_right text; v_fresh boolean; v_key text;
begin
  perform round_guard();
  if p_mode not in ('photo_mixed', 'photo_player', 'photo_goalkeeper', 'photo_country', 'photo_stadium') then
    raise exception 'bad_mode'; end if;
  if jsonb_typeof(p_answers) <> 'array' then raise exception 'bad_answers'; end if;
  v_n := jsonb_array_length(p_answers);
  if v_n < 1 or v_n > 12 then raise exception 'bad_answers'; end if;
  if (select count(distinct (x ->> 'item') || ':' || (x ->> 'q')) from jsonb_array_elements(p_answers) x) <> v_n then
    raise exception 'bad_answers'; end if;
  for a in select * from jsonb_array_elements(p_answers) loop
    v_item := a ->> 'item'; v_q := a ->> 'q';
    select answer into v_right from photo_answers where item = v_item and qtype = v_q;
    if not found then raise exception 'bad_question'; end if;
    v_key := 'photo:' || v_item || ':' || v_q;
    v_fresh := not exists (select 1 from question_log
      where user_id = auth.uid() and key = v_key and answered_at > now() - interval '24 hours');
    insert into question_log (user_id, key) values (auth.uid(), v_key);
    if (a ->> 'answer') = v_right then
      if v_fresh then v_points := v_points + 2; end if;
    else
      v_points := v_points - 1;
    end if;
  end loop;
  if v_points > 0 then
    insert into scores (user_id, mode, points) values (auth.uid(), p_mode, v_points);
  end if;
  return greatest(v_points, 0);
end $$;

revoke execute on function public.submit_geo(jsonb), public.submit_photo(text, jsonb) from public, anon;
grant execute on function public.submit_geo(jsonb), public.submit_photo(text, jsonb) to authenticated;

-- Gamle takbaserte innsendingen er ikke lenger i bruk
drop function if exists public.submit_score(text, int);

-- Samme runde-vakt for regler/sortering
create or replace function public.submit_round(p_mode text, p_answers jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_points int := 0; v_n int;
  a jsonb; v_key text; v_hash text; v_ans text; v_type text; v_fresh boolean;
begin
  perform round_guard();
  if p_mode not in ('rules_quiz', 'image_sort') then raise exception 'bad_mode'; end if;
  if jsonb_typeof(p_answers) <> 'array' then raise exception 'bad_answers'; end if;
  v_n := jsonb_array_length(p_answers);
  if v_n < 1 or v_n > 12 then raise exception 'bad_answers'; end if;
  if (select count(distinct x ->> 'key') from jsonb_array_elements(p_answers) x) <> v_n then
    raise exception 'bad_answers'; end if;
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
      if v_fresh then v_points := v_points + 2; end if;
    else
      v_points := v_points - 1;
    end if;
  end loop;
  if v_points > 0 then
    insert into scores (user_id, mode, points) values (auth.uid(), p_mode, v_points);
  end if;
  return greatest(v_points, 0);
end $$;
