-- Ensure account deletion also clears activity + achievement unlocks
-- (FKs already cascade from profiles; this keeps RPC explicit for clarity).

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

  delete from public.user_achievements where user_id = uid;
  delete from public.activity_entries where user_id = uid;
  delete from public.goal_progress where user_id = uid;
  delete from public.goals where user_id = uid;
  delete from public.sync_state where user_id = uid;
  delete from public.measurements where user_id = uid;
  delete from public.devices where user_id = uid;
  delete from public.profiles where id = uid;

  delete from auth.users where id = uid;
end;
$$;
