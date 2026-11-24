-- Push-varsler (FCM), samme oppsett som i Logica. Kjør i SQL Editor når Firebase er klart
-- (se docs/PUSH.md). Varsel-id-ene leses bare av serveren (Edge-funksjonen).
create table if not exists public.push_tokens (
  token      text primary key check (length(token) between 20 and 4096),
  user_id    uuid not null references auth.users (id) on delete cascade,
  updated_at timestamptz not null default now()
);
create index if not exists push_tokens_user_idx on public.push_tokens (user_id);
alter table public.push_tokens enable row level security;
revoke all on public.push_tokens from anon, authenticated;

create or replace function public.register_push_token(p_token text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare uid uuid := (select auth.uid());
begin
  if uid is null then raise exception 'ikke innlogget' using errcode = '28000'; end if;
  if p_token is null or length(p_token) < 20 or length(p_token) > 4096 then
    return jsonb_build_object('ok', false, 'error', 'invalid');
  end if;
  insert into public.push_tokens (token, user_id) values (p_token, uid)
  on conflict (token) do update set user_id = uid, updated_at = now();
  return jsonb_build_object('ok', true);
end;
$$;
revoke all on function public.register_push_token(text) from public, anon;
grant execute on function public.register_push_token(text) to authenticated;

create or replace function public.unregister_push_token()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare uid uuid := (select auth.uid());
begin
  if uid is null then raise exception 'ikke innlogget' using errcode = '28000'; end if;
  delete from public.push_tokens where user_id = uid;
  return jsonb_build_object('ok', true);
end;
$$;
revoke all on function public.unregister_push_token() from public, anon;
grant execute on function public.unregister_push_token() to authenticated;
