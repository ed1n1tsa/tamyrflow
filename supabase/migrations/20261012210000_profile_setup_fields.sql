-- Profile setup fields for post-registration wizard (Course A / wellness).
-- Run in Supabase SQL Editor if not applied via CLI.

alter table public.profiles
  add column if not exists gender text
    check (gender is null or gender in ('male', 'female', 'unspecified')),
  add column if not exists age integer
    check (age is null or (age >= 5 and age <= 120)),
  add column if not exists height_cm integer
    check (height_cm is null or (height_cm >= 80 and height_cm <= 250)),
  add column if not exists weight_kg numeric(5,1)
    check (weight_kg is null or (weight_kg >= 20 and weight_kg <= 400)),
  add column if not exists profile_completed boolean not null default false,
  add column if not exists profile_completed_at timestamptz;

comment on column public.profiles.gender is 'male | female | unspecified';
comment on column public.profiles.age is 'Age in full years (wizard step 3)';
comment on column public.profiles.height_cm is 'Height in centimeters';
comment on column public.profiles.weight_kg is 'Weight in kilograms';
comment on column public.profiles.profile_completed is 'True after post-signup profile wizard finishes';

-- Existing rows stay incomplete until they finish the wizard (or we backfill).
-- New signups get profile_completed = false via default.
