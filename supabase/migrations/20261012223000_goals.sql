-- TamyrFlow Goals (wellness) — supports empty state, create wizard, and goals list.
-- Categories match Figma: steps / activity / sleep / water / weight.

create type public.goal_category as enum (
  'steps',
  'activity',
  'sleep',
  'water',
  'weight'
);

create type public.goal_period as enum (
  'daily',
  'weekly',
  'monthly'
);

-- ---------------------------------------------------------------------------
-- goals
-- ---------------------------------------------------------------------------

create table public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  category public.goal_category not null,
  title text not null,
  target_value numeric(12, 2) not null check (target_value > 0),
  unit text not null,
  period public.goal_period not null default 'daily',
  reminders_enabled boolean not null default false,
  reminder_time time,
  -- ISO weekday 1=Mon … 7=Sun (matches Figma Пн–Вс)
  reminder_days smallint[] not null default '{}'::smallint[],
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint goals_reminder_days_valid check (
    reminder_days <@ array[1,2,3,4,5,6,7]::smallint[]
  )
);

create index goals_user_id_idx on public.goals (user_id);
create index goals_user_active_idx on public.goals (user_id, is_active);

create trigger goals_set_updated_at
  before update on public.goals
  for each row execute function public.set_updated_at();

comment on table public.goals is 'User wellness goals (steps, activity kcal, sleep, water, weight).';
comment on column public.goals.unit is 'Display/unit key: steps | kcal | hours | liters | kg';
comment on column public.goals.reminder_days is 'Weekdays 1=Mon … 7=Sun when reminders_enabled';

-- ---------------------------------------------------------------------------
-- goal_progress (per period bucket: day/week/month start date)
-- ---------------------------------------------------------------------------

create table public.goal_progress (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  period_start date not null,
  current_value numeric(12, 2) not null default 0 check (current_value >= 0),
  source text not null default 'manual'
    check (source in ('manual', 'device', 'import')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint goal_progress_unique_period unique (goal_id, period_start)
);

create index goal_progress_user_idx on public.goal_progress (user_id, period_start desc);
create index goal_progress_goal_idx on public.goal_progress (goal_id, period_start desc);

create trigger goal_progress_set_updated_at
  before update on public.goal_progress
  for each row execute function public.set_updated_at();

comment on table public.goal_progress is 'Progress snapshots per goal period_start (local calendar day/week/month).';

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.goals enable row level security;
alter table public.goal_progress enable row level security;

create policy goals_select_own
  on public.goals for select
  to authenticated
  using (auth.uid() = user_id);

create policy goals_insert_own
  on public.goals for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy goals_update_own
  on public.goals for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy goals_delete_own
  on public.goals for delete
  to authenticated
  using (auth.uid() = user_id);

create policy goal_progress_select_own
  on public.goal_progress for select
  to authenticated
  using (auth.uid() = user_id);

create policy goal_progress_insert_own
  on public.goal_progress for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy goal_progress_update_own
  on public.goal_progress for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy goal_progress_delete_own
  on public.goal_progress for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on public.goals to authenticated;
grant select, insert, update, delete on public.goal_progress to authenticated;
