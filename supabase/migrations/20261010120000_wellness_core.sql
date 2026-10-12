-- TamyrFlow Wellness MVP — core schema (Course A)
-- No doctor/patient roles, no clinician tables.
-- Metrics MVP: heart_rate, steps, sleep, spo2, temperature, blood_pressure

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  email text,
  avatar_url text,
  locale text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

comment on table public.profiles is 'Wellness user profile; 1:1 with auth.users. No clinician roles.';

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'full_name',
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- devices
-- ---------------------------------------------------------------------------

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  model text not null,
  display_name text,
  device_uid text,
  mac_address text,
  firmware_version text,
  connection_meta jsonb not null default '{}'::jsonb,
  last_sync_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint devices_device_uid_unique unique (user_id, device_uid)
);

create index devices_user_id_idx on public.devices (user_id);
create index devices_user_last_sync_idx on public.devices (user_id, last_sync_at desc nulls last);

create trigger devices_set_updated_at
  before update on public.devices
  for each row execute function public.set_updated_at();

comment on table public.devices is 'User wearable devices (e.g. ET488). connection_meta holds SDK/BLE opaque state.';

-- ---------------------------------------------------------------------------
-- measurements
-- ---------------------------------------------------------------------------

create type public.metric_type as enum (
  'heart_rate',
  'steps',
  'sleep',
  'spo2',
  'temperature',
  'blood_pressure'
);

create type public.measurement_source as enum (
  'device',
  'manual',
  'import'
);

create table public.measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  device_id uuid references public.devices (id) on delete set null,
  metric public.metric_type not null,
  -- Primary numeric value (HR bpm, steps count, SpO2 %, temp °C, systolic mmHg, sleep minutes)
  value double precision not null,
  -- Secondary value when needed (e.g. diastolic for blood_pressure)
  value_secondary double precision,
  unit text not null,
  recorded_at timestamptz not null,
  source public.measurement_source not null default 'device',
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  constraint measurements_blood_pressure_secondary_chk check (
    metric <> 'blood_pressure' or value_secondary is not null
  )
);

create index measurements_user_recorded_idx
  on public.measurements (user_id, recorded_at desc);

create index measurements_user_metric_recorded_idx
  on public.measurements (user_id, metric, recorded_at desc);

create index measurements_device_id_idx
  on public.measurements (device_id)
  where device_id is not null;

comment on table public.measurements is
  'Wellness readings. MVP metrics only; ECG/glucose intentionally omitted.';
comment on column public.measurements.value_secondary is
  'Diastolic mmHg for blood_pressure; optional otherwise.';
comment on column public.measurements.meta is
  'Optional extras (sleep stages, sample quality). Not for clinician workflow.';

-- ---------------------------------------------------------------------------
-- sync_state
-- ---------------------------------------------------------------------------

create table public.sync_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  device_id uuid references public.devices (id) on delete cascade,
  metric public.metric_type,
  last_sync_at timestamptz,
  cursor_token text,
  meta jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default timezone('utc', now()),
  constraint sync_state_user_device_metric_unique unique (user_id, device_id, metric)
);

create index sync_state_user_id_idx on public.sync_state (user_id);

create trigger sync_state_set_updated_at
  before update on public.sync_state
  for each row execute function public.set_updated_at();

comment on table public.sync_state is
  'Per-user (and optional per-device/metric) sync cursors for wearable pull.';

-- ---------------------------------------------------------------------------
-- RLS — own rows only
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.devices enable row level security;
alter table public.measurements enable row level security;
alter table public.sync_state enable row level security;

-- profiles
create policy profiles_select_own
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

create policy profiles_update_own
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Insert handled by security definer trigger; no direct client insert needed.
-- Allow authenticated insert of own row as fallback (e.g. legacy users).
create policy profiles_insert_own
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

-- devices
create policy devices_select_own
  on public.devices for select
  to authenticated
  using (user_id = auth.uid());

create policy devices_insert_own
  on public.devices for insert
  to authenticated
  with check (user_id = auth.uid());

create policy devices_update_own
  on public.devices for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy devices_delete_own
  on public.devices for delete
  to authenticated
  using (user_id = auth.uid());

-- measurements
create policy measurements_select_own
  on public.measurements for select
  to authenticated
  using (user_id = auth.uid());

create policy measurements_insert_own
  on public.measurements for insert
  to authenticated
  with check (user_id = auth.uid());

create policy measurements_update_own
  on public.measurements for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy measurements_delete_own
  on public.measurements for delete
  to authenticated
  using (user_id = auth.uid());

-- sync_state
create policy sync_state_select_own
  on public.sync_state for select
  to authenticated
  using (user_id = auth.uid());

create policy sync_state_insert_own
  on public.sync_state for insert
  to authenticated
  with check (user_id = auth.uid());

create policy sync_state_update_own
  on public.sync_state for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy sync_state_delete_own
  on public.sync_state for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Account deletion (cascade own data + auth user)
-- ---------------------------------------------------------------------------
-- Callable by the signed-in user via PostgREST:
--   POST /rest/v1/rpc/delete_own_account
-- Cascades: profiles → devices / measurements / sync_state (FK on delete cascade).
-- auth.users delete removes the auth identity.

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Explicit cleanup first (safe if FKs change later)
  delete from public.sync_state where user_id = uid;
  delete from public.measurements where user_id = uid;
  delete from public.devices where user_id = uid;
  delete from public.profiles where id = uid;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;

comment on function public.delete_own_account() is
  'Security definer: deletes caller data + auth.users row. Alternative: Edge Function with service_role.';

-- ---------------------------------------------------------------------------
-- Grants (tables already in public; ensure authenticated can use)
-- ---------------------------------------------------------------------------

grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant insert on public.profiles to authenticated;
grant select, insert, update, delete on public.devices to authenticated;
grant select, insert, update, delete on public.measurements to authenticated;
grant select, insert, update, delete on public.sync_state to authenticated;
grant usage on type public.metric_type to authenticated;
grant usage on type public.measurement_source to authenticated;
