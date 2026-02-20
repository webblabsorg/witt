-- ── Social post daily limits (server-authoritative) ──────────────────────
--
-- Tracks how many posts a user has made today.
-- Free users: max 1 post/day. Paid users: unlimited.
-- The `record_social_post` function increments the counter and raises an
-- exception if the free-tier limit is exceeded.

create table if not exists public.social_post_daily_limits (
  user_id uuid not null references public.users(id) on delete cascade,
  post_date date not null default current_date,
  post_count int not null default 0,
  primary key (user_id, post_date)
);

alter table public.social_post_daily_limits enable row level security;

create policy "Users can read own limits"
  on public.social_post_daily_limits for select
  using (auth.uid() = user_id);

-- ── RPC: record_social_post ───────────────────────────────────────────────
-- Returns: the new post count for today.
-- Raises:  'post_limit_exceeded' if free-tier limit hit.

create or replace function public.record_social_post(p_user_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_paid boolean;
  v_count   int;
  v_today   date := current_date;
begin
  -- Check subscription tier via user metadata (set by Subrail webhook)
  select coalesce((raw_user_meta_data->>'is_paid')::boolean, false)
  into v_is_paid
  from auth.users
  where id = p_user_id;

  -- Upsert daily counter
  insert into public.social_post_daily_limits (user_id, post_date, post_count)
  values (p_user_id, v_today, 1)
  on conflict (user_id, post_date)
  do update set post_count = social_post_daily_limits.post_count + 1
  returning post_count into v_count;

  -- Enforce free-tier limit (1 post/day)
  if not v_is_paid and v_count > 1 then
    -- Roll back the increment
    update public.social_post_daily_limits
    set post_count = post_count - 1
    where user_id = p_user_id and post_date = v_today;

    raise exception 'post_limit_exceeded'
      using hint = 'Free users may post once per day. Upgrade for unlimited posting.';
  end if;

  return v_count;
end;
$$;

-- ── RPC: get_posts_today ──────────────────────────────────────────────────
-- Returns the number of posts the calling user has made today.

create or replace function public.get_posts_today(p_user_id uuid)
returns int
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (select post_count
     from public.social_post_daily_limits
     where user_id = p_user_id and post_date = current_date),
    0
  );
$$;
