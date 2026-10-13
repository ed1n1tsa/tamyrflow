-- TamyrFlow Activity: workout log, daily metrics (water/kcal/weight), achievements.

-- ---------------------------------------------------------------------------
-- Extend measurements metrics for manual daily values
-- ---------------------------------------------------------------------------

alter type public.metric_type add value if not exists 'calories';
alter type public.metric_type add value if not exists 'water';
alter type public.metric_type add value if not exists 'weight';

-- ---------------------------------------------------------------------------
-- activity_entries (manual workout wizard)
-- ---------------------------------------------------------------------------

create type public.activity_category as enum (
  'workouts',
  'walk_run',
  'adaptive',
  'sport',
  'everyday'
);

create type public.activity_intensity as enum (
  'light',
  'medium',
  'high'
);

create table public.activity_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  category public.activity_category not null,
  activity_type text not null,
  title text not null,
  duration_min integer not null check (duration_min > 0 and duration_min <= 24 * 60),
  started_at timestamptz not null,
  intensity public.activity_intensity not null default 'medium',
  notes text not null default '',
  distance_km numeric(10, 2),
  calories_est numeric(10, 2),
  source text not null default 'manual'
    check (source in ('manual', 'device', 'import')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint activity_notes_len check (char_length(notes) <= 200)
);

create index activity_entries_user_started_idx
  on public.activity_entries (user_id, started_at desc);

create trigger activity_entries_set_updated_at
  before update on public.activity_entries
  for each row execute function public.set_updated_at();

comment on table public.activity_entries is
  'Manual (and later device) activity/workout log for the Activity tab.';

-- ---------------------------------------------------------------------------
-- Achievements
-- ---------------------------------------------------------------------------

create table public.achievement_defs (
  id text primary key,
  kind text not null check (kind in ('steps', 'calories', 'water', 'sleep', 'weight', 'workout')),
  threshold numeric(12, 2) not null check (threshold > 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.user_achievements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id text not null references public.achievement_defs (id) on delete cascade,
  unlocked_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, achievement_id)
);

create index user_achievements_user_idx
  on public.user_achievements (user_id, unlocked_at desc);

insert into public.achievement_defs (id, kind, threshold, sort_order) values
  ('steps_7000', 'steps', 7000, 10),
  ('kcal_300', 'calories', 300, 20),
  ('water_2l', 'water', 2, 30),
  ('sleep_8h', 'sleep', 8, 40),
  ('weight_goal', 'weight', 1, 50),
  ('workout_1', 'workout', 1, 60)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.activity_entries enable row level security;
alter table public.achievement_defs enable row level security;
alter table public.user_achievements enable row level security;

create policy activity_entries_select_own
  on public.activity_entries for select to authenticated
  using (auth.uid() = user_id);

create policy activity_entries_insert_own
  on public.activity_entries for insert to authenticated
  with check (auth.uid() = user_id);

create policy activity_entries_update_own
  on public.activity_entries for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy activity_entries_delete_own
  on public.activity_entries for delete to authenticated
  using (auth.uid() = user_id);

create policy achievement_defs_select_all
  on public.achievement_defs for select to authenticated
  using (true);

create policy user_achievements_select_own
  on public.user_achievements for select to authenticated
  using (auth.uid() = user_id);

create policy user_achievements_insert_own
  on public.user_achievements for insert to authenticated
  with check (auth.uid() = user_id);

create policy user_achievements_delete_own
  on public.user_achievements for delete to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on public.activity_entries to authenticated;
grant select on public.achievement_defs to authenticated;
grant select, insert, delete on public.user_achievements to authenticated;
