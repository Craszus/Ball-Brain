-- Ball Brain: MVP-skjema (kjør i Supabase → SQL Editor)

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  country_code char(2),
  created_at timestamptz not null default now()
);

create table public.questions (
  id bigint generated always as identity primary key,
  type text not null check (type in ('image_sort', 'rules_quiz')),
  era text,                       -- f.eks. '1990s'
  prompt text not null,
  image_url text,
  options jsonb not null,         -- liste med svaralternativer / elementer som skal sorteres
  correct jsonb not null,         -- riktig svar eller riktig rekkefølge
  difficulty smallint not null default 1 check (difficulty between 1 and 5),
  created_at timestamptz not null default now()
);

create table public.scores (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  mode text not null check (mode in ('image_sort', 'rules_quiz', 'duel')),
  points integer not null check (points >= 0),
  created_at timestamptz not null default now()
);
create index scores_mode_points_idx on public.scores (mode, points desc);
create index scores_user_idx on public.scores (user_id);

-- Row Level Security
alter table public.profiles  enable row level security;
alter table public.questions enable row level security;
alter table public.scores    enable row level security;

create policy "profiler er lesbare for innloggede" on public.profiles
  for select to authenticated using (true);
create policy "bruker oppdaterer egen profil" on public.profiles
  for update to authenticated using (auth.uid() = id);
create policy "bruker oppretter egen profil" on public.profiles
  for insert to authenticated with check (auth.uid() = id);

create policy "spørsmål er lesbare for innloggede" on public.questions
  for select to authenticated using (true);

create policy "score er lesbar for innloggede" on public.scores
  for select to authenticated using (true);
create policy "bruker lagrer egen score" on public.scores
  for insert to authenticated with check (auth.uid() = user_id);
