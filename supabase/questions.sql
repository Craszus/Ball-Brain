-- Spørsmålene bor i Supabase (kjøres i SQL Editor). Etterpå fylles tabellen med supabase/seed.sql.
-- submit_round sjekker svar direkte mot questions (erstatter quiz_answers).

alter table public.questions add column if not exists key text unique;
alter table public.questions add column if not exists active boolean not null default true;

drop policy if exists "spørsmål er lesbare for innloggede" on public.questions;
create policy "aktive spørsmål er lesbare for innloggede" on public.questions
  for select to authenticated using (active);
grant select on public.questions to authenticated;

create or replace function public.submit_round(p_mode text, p_answers jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_points int := 0; v_n int;
  a jsonb; v_key text; v_ans text; v_right text; v_type text; v_opts jsonb; v_corr jsonb; v_fresh boolean;
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
    select q.type, q.options, q.correct into v_type, v_opts, v_corr
      from questions q where q.key = v_key and q.active;
    if not found or v_type <> p_mode then raise exception 'bad_question'; end if;
    if v_type = 'rules_quiz' then
      v_right := v_opts ->> ((v_corr #>> '{}')::int);
      v_ans := a ->> 'answer';
    else
      select string_agg(v_opts ->> (i::int), '|' order by o) into v_right
        from jsonb_array_elements_text(v_corr) with ordinality as e(i, o);
      if jsonb_typeof(a -> 'answer') = 'array' then
        select string_agg(t, '|' order by o) into v_ans
          from jsonb_array_elements_text(a -> 'answer') with ordinality as e(t, o);
      end if;
    end if;
    v_fresh := not exists (select 1 from question_log
      where user_id = auth.uid() and key = v_key and answered_at > now() - interval '24 hours');
    insert into question_log (user_id, key) values (auth.uid(), v_key);
    if v_ans is not distinct from v_right then
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
revoke execute on function public.submit_round(text, jsonb) from public, anon;
grant execute on function public.submit_round(text, jsonb) to authenticated;

drop table if exists public.quiz_answers;
drop function if exists public.submit_score(text, int);
