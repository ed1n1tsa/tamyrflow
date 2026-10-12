-- Enforce at most one active goal per category per user (product rule).
create unique index if not exists goals_one_active_per_category_idx
  on public.goals (user_id, category)
  where is_active = true;
