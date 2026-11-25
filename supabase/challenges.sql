-- Utfordringer til venner (som i Logica): en venn i en felles gruppe utfordres til 1v1.
-- Begge spiller de samme 10 spørsmålene når det passer dem (innen 48 timer), og serveren avgjør
-- vinneren. Mottakeren kan spille, avslå eller slå av utfordringer. Kjøres i SQL Editor etter duels.sql.

alter table public.profiles add column if not exists accepts_challenges boolean not null default true;

alter table public.duels add column if not exists mode text not null default 'live';
alter table public.duels add column if not exists expires_at timestamptz;
alter table public.duels add column if not exists p1_hidden boolean not null default false;
alter table public.duels add column if not exists p2_hidden boolean not null default false;
alter table public.duels add column if not exists notified boolean not null default false;
alter table public.duels drop constraint if exists duels_status_check;
alter table public.duels add constraint duels_status_check
  check (status in ('waiting', 'active', 'finished', 'cancelled', 'declined'));
alter table public.duels drop constraint if exists duels_mode_check;
alter table public.duels add constraint duels_mode_check check (mode in ('live', 'challenge'));

create or replace function public.duel_summary(d public.duels)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare me uuid := auth.uid(); mine boolean := (d.p1 = me); opp uuid; o profiles; m profiles; my_last timestamptz;
begin
  opp := case when mine then d.p2 else d.p1 end;
  my_last := case when mine then d.p1_last else d.p2_last end;
  select * into o from profiles where id = opp;
  select * into m from profiles where id = me;
  return jsonb_build_object(
    'id', d.id, 'code', d.code, 'status', d.status, 'mode', d.mode, 'challenger', mine,
    'total', coalesce(array_length(d.question_keys, 1), 0),
    'now_ms', (extract(epoch from clock_timestamp()) * 1000)::bigint,
    'starts_ms', case when d.mode = 'live' then
        case when d.started_at is null then null else (extract(epoch from d.started_at) * 1000)::bigint end
      else case when my_last is null then null else (extract(epoch from my_last) * 1000)::bigint end end,
    'expires_ms', case when d.expires_at is null then null else (extract(epoch from d.expires_at) * 1000)::bigint end,
    'my_done', (case when mine then d.p1_done_at else d.p2_done_at end) is not null,
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

-- Rydder: ventende live-kamper, hengende live-kamper og utløpte utfordringer (48 timer).
create or replace function public.duel_housekeeping()
returns void language plpgsql security definer set search_path = public as $$
declare x uuid;
begin
  if auth.uid() is null or not exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'no_profile'; end if;
  update duels set status = 'cancelled' where mode = 'live' and status = 'waiting' and created_at < now() - interval '5 minutes';
  update duels set status = 'cancelled' where mode = 'live' and status = 'active' and started_at < now() - interval '15 minutes';
  for x in select id from duels where mode = 'challenge' and status = 'active' and expires_at < now()
           and ((p1_done_at is null) <> (p2_done_at is null)) loop
    perform duel_finalize(x);
  end loop;
  update duels set status = 'cancelled' where mode = 'challenge' and status = 'active' and expires_at < now();
end $$;
revoke execute on function public.duel_housekeeping() from public, anon, authenticated;

-- Hurtigmatch (bare live-kamper)
create or replace function public.duel_find()
returns jsonb language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid();
begin
  perform duel_housekeeping();
  select * into d from duels where mode = 'live' and status in ('waiting', 'active') and (p1 = me or p2 = me)
    and not ((p1 = me and p1_done_at is not null) or (p2 = me and p2_done_at is not null))
    order by created_at desc limit 1;
  if found then return duel_summary(d); end if;
  if (select count(*) from duels where (p1 = me or p2 = me) and created_at > now() - interval '24 hours') >= 40 then
    raise exception 'daily_limit'; end if;
  select * into d from duels where mode = 'live' and status = 'waiting' and is_public and p1 <> me
    order by created_at limit 1 for update skip locked;
  if found then
    perform duel_start(d.id, me);
    select * into d from duels where id = d.id;
    return duel_summary(d);
  end if;
  insert into duels (is_public, p1) values (true, me) returning * into d;
  return duel_summary(d);
end $$;

create or replace function public.duel_get(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid();
begin
  select * into d from duels where id = p_id and (p1 = me or p2 = me);
  if not found then raise exception 'not_found'; end if;
  if d.mode = 'live' and d.status = 'active' and (d.p1_done_at is null) <> (d.p2_done_at is null)
     and now() - coalesce(d.p1_done_at, d.p2_done_at) > interval '60 seconds' then
    perform duel_finalize(p_id);
    select * into d from duels where id = p_id;
  elsif d.mode = 'challenge' and d.status = 'active' and d.expires_at < now() then
    perform duel_housekeeping();
    select * into d from duels where id = p_id;
  end if;
  return duel_summary(d);
end $$;

-- Svar på spørsmål nr. p_idx. Tiden regnes fra at DU startet (live: felles start; utfordring: din egen start).
create or replace function public.duel_answer(p_id uuid, p_idx int, p_answer text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  d duels; me uuid := auth.uid(); mine boolean; base timestamptz; ms int; v_right text; v_ok boolean;
  v_pts int; v_answered int; v_total int; v_opts jsonb; v_corr jsonb; v_both boolean; v_my_last timestamptz;
begin
  select * into d from duels where id = p_id and (p1 = me or p2 = me) for update;
  if not found then raise exception 'not_found'; end if;
  if d.status <> 'active' then raise exception 'not_active'; end if;
  mine := (d.p1 = me);
  v_my_last := case when mine then d.p1_last else d.p2_last end;
  v_answered := case when mine then d.p1_answered else d.p2_answered end;
  v_total := array_length(d.question_keys, 1);
  if p_idx <> v_answered or p_idx >= v_total then raise exception 'bad_index'; end if;
  if v_my_last is null or now() < v_my_last - interval '1 second' then raise exception 'not_started'; end if;
  base := v_my_last + (case when v_answered = 0 then interval '0' else interval '1 second' end);
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

-- Utfordrer en venn (en jeg deler en gruppe med). Feil: self, not_found, not_shared, not_accepting,
-- too_many (maks 5 åpne), already (en åpen utfordring til samme venn), daily_limit.
create or replace function public.create_challenge(p_user uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); d duels; keys text[];
begin
  perform duel_housekeeping();
  if p_user = me then raise exception 'self'; end if;
  if not exists (select 1 from profiles where id = p_user) then raise exception 'not_found'; end if;
  if not exists (select 1 from group_members a join group_members b on a.group_id = b.group_id
                 where a.user_id = me and b.user_id = p_user) then raise exception 'not_shared'; end if;
  if not (select accepts_challenges from profiles where id = p_user) then raise exception 'not_accepting'; end if;
  if (select count(*) from duels where p1 = me and mode = 'challenge' and status = 'active') >= 5 then
    raise exception 'too_many'; end if;
  if exists (select 1 from duels where p1 = me and p2 = p_user and mode = 'challenge' and status = 'active') then
    raise exception 'already'; end if;
  if (select count(*) from duels where (p1 = me or p2 = me) and created_at > now() - interval '24 hours') >= 40 then
    raise exception 'daily_limit'; end if;
  select array_agg(key order by difficulty, random()) into keys from (
    select key, difficulty from questions where type = 'rules_quiz' and active order by random() limit 10) q;
  insert into duels (mode, status, p1, p2, question_keys, expires_at)
    values ('challenge', 'active', me, p_user, keys, now() + interval '48 hours') returning * into d;
  return duel_summary(d);
end $$;

-- Starter min egen runde i en utfordring (4 sekunders nedtelling). Kan bare gjøres én gang.
create or replace function public.duel_start_mine(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid(); mine boolean;
begin
  select * into d from duels where id = p_id and (p1 = me or p2 = me) for update;
  if not found then raise exception 'not_found'; end if;
  if d.status <> 'active' then raise exception 'not_active'; end if;
  mine := (d.p1 = me);
  if d.mode = 'challenge' then
    if (case when mine then d.p1_done_at else d.p2_done_at end) is not null then raise exception 'already_played'; end if;
    if (case when mine then d.p1_last else d.p2_last end) is null then
      if mine then update duels set p1_last = now() + interval '4 seconds' where id = p_id;
      else update duels set p2_last = now() + interval '4 seconds' where id = p_id; end if;
    end if;
  end if;
  select * into d from duels where id = p_id;
  return duel_summary(d);
end $$;

-- Mine utfordringer og ferdige kamper siste 14 dager (uten de jeg har fjernet).
create or replace function public.my_duels()
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid();
begin
  perform duel_housekeeping();
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', d.id, 'mode', d.mode, 'status', d.status,
      'incoming', (d.p2 = me and d.mode = 'challenge'),
      'opponent', coalesce(o.username, '?'), 'country', o.country_code,
      'opponent_id', case when d.p1 = me then d.p2 else d.p1 end,
      'finished_ms', case when d.finished_at is null then null else (extract(epoch from d.finished_at) * 1000)::bigint end,
      'my_score', case when d.p1 = me then d.p1_score else d.p2_score end,
      'their_score', case when d.p1 = me then d.p2_score else d.p1_score end,
      'my_answered', case when d.p1 = me then d.p1_answered else d.p2_answered end,
      'my_done', (case when d.p1 = me then d.p1_done_at else d.p2_done_at end) is not null,
      'their_done', (case when d.p1 = me then d.p2_done_at else d.p1_done_at end) is not null,
      'total', coalesce(array_length(d.question_keys, 1), 0),
      'result', case when d.status <> 'finished' then null when d.winner is null then 'draw'
                     when d.winner = me then 'win' else 'loss' end,
      'created_at', d.created_at,
      'expires_ms', case when d.expires_at is null then null else (extract(epoch from d.expires_at) * 1000)::bigint end
    ) order by d.created_at desc), '[]'::jsonb)
    from duels d left join profiles o on o.id = case when d.p1 = me then d.p2 else d.p1 end
    where (d.p1 = me or d.p2 = me)
      and not (case when d.p1 = me then d.p1_hidden else d.p2_hidden end)
      and d.created_at > now() - interval '14 days'
      and (d.mode = 'challenge' or d.status = 'finished')
      and (d.status in ('active', 'finished') or (d.status = 'declined' and d.p1 = me))
  );
end $$;

-- Avslår en utfordring jeg har fått (utfordreren ser at den ble avslått).
create or replace function public.duel_decline(p_id uuid)
returns void language sql security definer set search_path = public as $$
  update duels set status = 'declined'
  where id = p_id and p2 = auth.uid() and mode = 'challenge' and status = 'active' and p2_done_at is null;
$$;

-- «Avslutt/Fjern»: avbryter en åpen utfordring (utfordrer) eller avslår den (mottaker), og skjuler
-- ferdige/avslåtte/avbrutte kamper fra listen min.
create or replace function public.duel_remove(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare d duels; me uuid := auth.uid();
begin
  select * into d from duels where id = p_id and (p1 = me or p2 = me) for update;
  if not found then return; end if;
  if d.status = 'active' and d.mode = 'challenge' then
    update duels set status = case when d.p1 = me then 'cancelled' else 'declined' end where id = p_id;
  elsif d.status = 'waiting' and d.p1 = me then
    update duels set status = 'cancelled' where id = p_id;
  end if;
  if d.p1 = me then update duels set p1_hidden = true where id = p_id;
  else update duels set p2_hidden = true where id = p_id; end if;
end $$;

-- Slå utfordringer av/på (mottaker). Av: ingen kan utfordre meg.
create or replace function public.set_accepts_challenges(p_on boolean)
returns void language sql security definer set search_path = public as $$
  update profiles set accepts_challenges = coalesce(p_on, true) where id = auth.uid();
$$;

revoke execute on function
  public.duel_find(), public.duel_get(uuid), public.duel_answer(uuid, int, text),
  public.create_challenge(uuid), public.duel_start_mine(uuid), public.my_duels(),
  public.duel_decline(uuid), public.duel_remove(uuid), public.set_accepts_challenges(boolean)
  from public, anon;
grant execute on function
  public.duel_find(), public.duel_get(uuid), public.duel_answer(uuid, int, text),
  public.create_challenge(uuid), public.duel_start_mine(uuid), public.my_duels(),
  public.duel_decline(uuid), public.duel_remove(uuid), public.set_accepts_challenges(boolean)
  to authenticated;
