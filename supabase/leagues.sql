-- Klubbtabellen (alle klubber, fra klubbkampene) og klubbserien (medlemmene mot hverandre, fra 1v1).
-- Kjøres i SQL Editor etter clubs.sql. Seier gir 3 poeng, uavgjort 1. Bare det første oppgjøret
-- mellom de samme to teller hver dag (norsk døgn), så man ikke kan sanke poeng ved å spille om igjen.

-- Starten på perioden: 'month' = denne måneden (norsk tid), ellers alt.
create or replace function public.league_since(p_period text)
returns timestamptz language sql stable set search_path = public as $$
  select case when p_period = 'month'
    then date_trunc('month', now() at time zone 'Europe/Oslo') at time zone 'Europe/Oslo'
    else '-infinity'::timestamptz end
$$;

create or replace function public.club_table(p_period text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid();
begin
  if me is null then raise exception 'not_signed_in'; end if;
  perform club_housekeeping();
  return (
    with games as (
      select distinct on (least(c.home, c.away), greatest(c.home, c.away),
                          (c.kickoff at time zone 'Europe/Oslo')::date)
             c.home, c.away, c.home_score, c.away_score
      from club_games c
      where c.status = 'finished' and c.kickoff >= league_since(p_period)
      order by least(c.home, c.away), greatest(c.home, c.away),
               (c.kickoff at time zone 'Europe/Oslo')::date, c.kickoff
    ), sides as (
      select home as club, home_score as f, away_score as a from games
      union all
      select away, away_score, home_score from games
    ), totals as (
      select club, count(*) as played,
        count(*) filter (where f > a) as w, count(*) filter (where f = a) as d,
        count(*) filter (where f < a) as l, sum(f) as pf, sum(a) as pa
      from sides group by club
    ), ranked as (
      select t.*, 3 * t.w + t.d as points, g.name, g.color1, g.color2, g.emblem,
        exists (select 1 from group_members m where m.group_id = g.id and m.user_id = me) as mine,
        row_number() over (order by 3 * t.w + t.d desc, t.pf - t.pa desc, t.pf desc, g.name) as rank
      from totals t join groups g on g.id = t.club
      where exists (select 1 from group_members m where m.group_id = g.id)
    )
    select coalesce(jsonb_agg(jsonb_build_object(
        'rank', rank, 'id', club, 'name', name, 'color1', color1, 'color2', color2, 'emblem', emblem,
        'mine', mine, 'played', played, 'w', w, 'd', d, 'l', l, 'points', points, 'diff', pf - pa
      ) order by rank), '[]'::jsonb)
    from ranked where rank <= 50 or mine);
end $$;

create or replace function public.club_league(p_club uuid, p_period text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid();
begin
  if not club_is_member(p_club) then raise exception 'not_member'; end if;
  return (
    with members as (
      select m.user_id from group_members m where m.group_id = p_club
    ), games as (
      select distinct on (least(d.p1, d.p2), greatest(d.p1, d.p2),
                          (d.finished_at at time zone 'Europe/Oslo')::date)
             d.p1, d.p2, d.p1_score, d.p2_score, d.winner
      from duels d
      where d.status = 'finished' and d.finished_at >= league_since(p_period)
        and d.p1 in (select user_id from members) and d.p2 in (select user_id from members)
      order by least(d.p1, d.p2), greatest(d.p1, d.p2),
               (d.finished_at at time zone 'Europe/Oslo')::date, d.finished_at
    ), sides as (
      select p1 as u, p1_score - p2_score as diff, winner from games
      union all
      select p2, p2_score - p1_score, winner from games
    ), totals as (
      select m.user_id as u, count(s.u) as played,
        count(*) filter (where s.winner = m.user_id) as w,
        count(*) filter (where s.u is not null and s.winner is null) as d,
        count(*) filter (where s.winner is not null and s.winner <> m.user_id) as l,
        coalesce(sum(s.diff), 0) as diff
      from members m left join sides s on s.u = m.user_id group by m.user_id
    ), ranked as (
      select t.*, 3 * t.w + t.d as points, p.username,
        row_number() over (order by 3 * t.w + t.d desc, t.diff desc, t.played, p.username) as rank
      from totals t join profiles p on p.id = t.u
    )
    select coalesce(jsonb_agg(jsonb_build_object(
        'rank', rank, 'user_id', u, 'name', username, 'me', u = me, 'played', played,
        'w', w, 'd', d, 'l', l, 'points', points, 'diff', diff
      ) order by rank), '[]'::jsonb)
    from ranked);
end $$;

revoke execute on function
  public.league_since(text), public.club_table(text), public.club_league(uuid, text)
  from public, anon, authenticated;
grant execute on function public.club_table(text), public.club_league(uuid, text) to authenticated;

select 'Klubbtabell og klubbserie er på plass' as resultat;
