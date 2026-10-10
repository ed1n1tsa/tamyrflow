# Supabase (TamyrFlow Wellness)

Course **A** schema: personal wellness only — no doctor/patient roles.

## Layout

- `migrations/` — ordered SQL applied to a fresh Supabase project

## Apply migrations (requires elevated access)

Anon key **cannot** run DDL. Use one of:

### Option A — Dashboard SQL Editor (fastest for Zen)

1. Open project → **SQL** → New query
2. Paste contents of `migrations/20261010120000_wellness_core.sql`
3. Run
4. Confirm tables under **Table Editor**: `profiles`, `devices`, `measurements`, `sync_state`

### Option B — CLI (`supabase db push`)

Needs project linked with DB password or access token:

```bash
npx supabase login
npx supabase link --project-ref zqdpyzgocnbhgowxbgwi
npx supabase db push
```

### Option C — Connection string

Needs **Database password** (Settings → Database) or **service_role** is not enough alone for `psql` — use the Postgres URI:

```bash
psql "$DATABASE_URL" -f supabase/migrations/20261010120000_wellness_core.sql
```

## What to give the agent next

To apply remotely without Dashboard paste, provide **one** of:

- Supabase **service_role** key (server-only; never commit / never ship in iOS)
- Database password + allow connection (or use pooler URI)
- Personal access token for `supabase link` / Management API

## Auth notes

- Email/password is enabled on the project (verified via `/auth/v1/settings`).
- Signup creates `profiles` via trigger `on_auth_user_created`.
- Account deletion: authenticated RPC `delete_own_account()`.

## Secrets

Do **not** commit URL keys, service_role, or DB passwords into this repo. Keep them in local env / agent store only.
