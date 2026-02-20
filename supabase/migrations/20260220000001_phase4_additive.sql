-- ── Phase 4 additive migration ────────────────────────────────────────────
-- Adds: social_feed_posts, content_reports, translation_history,
--       game_daily_limits (server-authoritative), marketplace_deck_downloads

-- ── Social feed posts (distinct from Q&A community_posts) ─────────────────

create table if not exists public.social_feed_posts (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 2000),
  post_type text not null default 'text'
    check (post_type in ('text', 'image', 'question', 'poll', 'resource')),
  group_id uuid references public.study_groups(id) on delete set null,
  tags text[] not null default '{}',
  likes int not null default 0,
  comment_count int not null default 0,
  is_flagged boolean not null default false,
  is_removed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.social_feed_posts enable row level security;

create policy "Feed posts readable by all authenticated users"
  on public.social_feed_posts for select
  using (auth.uid() is not null and is_removed = false);

create policy "Users can insert own feed posts"
  on public.social_feed_posts for insert
  with check (auth.uid() = user_id);

create policy "Users can update own feed posts"
  on public.social_feed_posts for update
  using (auth.uid() = user_id);

create policy "Users can delete own feed posts"
  on public.social_feed_posts for delete
  using (auth.uid() = user_id);

create trigger handle_social_feed_posts_updated_at
  before update on public.social_feed_posts
  for each row execute function extensions.moddatetime(updated_at);

create index idx_social_feed_posts_user on public.social_feed_posts(user_id);
create index idx_social_feed_posts_group on public.social_feed_posts(group_id);
create index idx_social_feed_posts_created on public.social_feed_posts(created_at desc);

-- ── Social post likes (deduplicated) ──────────────────────────────────────

create table if not exists public.social_post_likes (
  post_id uuid not null references public.social_feed_posts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

alter table public.social_post_likes enable row level security;

create policy "Users can manage own likes"
  on public.social_post_likes for all
  using (auth.uid() = user_id);

-- ── Content reports (moderation) ──────────────────────────────────────────

create table if not exists public.content_reports (
  id uuid primary key default extensions.uuid_generate_v4(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  content_type text not null
    check (content_type in ('feed_post', 'community_post', 'reply', 'group', 'deck')),
  content_id uuid not null,
  reason text not null
    check (reason in ('spam', 'harassment', 'inappropriate', 'misinformation', 'other')),
  details text,
  status text not null default 'pending'
    check (status in ('pending', 'reviewed', 'actioned', 'dismissed')),
  reviewed_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (reporter_id, content_type, content_id)
);

alter table public.content_reports enable row level security;

create policy "Users can submit reports"
  on public.content_reports for insert
  with check (auth.uid() = reporter_id);

create policy "Users can read own reports"
  on public.content_reports for select
  using (auth.uid() = reporter_id);

create trigger handle_content_reports_updated_at
  before update on public.content_reports
  for each row execute function extensions.moddatetime(updated_at);

create index idx_content_reports_status on public.content_reports(status);
create index idx_content_reports_type_id on public.content_reports(content_type, content_id);

-- ── Translation history (server-side, cross-device) ───────────────────────

create table if not exists public.translation_history (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  source_text text not null,
  translated_text text not null,
  source_lang text not null,
  target_lang text not null,
  is_offline boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.translation_history enable row level security;

create policy "Users can manage own translation history"
  on public.translation_history for all
  using (auth.uid() = user_id);

create index idx_translation_history_user on public.translation_history(user_id, created_at desc);

-- ── Game daily limits (server-authoritative for free users) ───────────────

create table if not exists public.game_daily_limits (
  user_id uuid not null references public.users(id) on delete cascade,
  date date not null default current_date,
  games_played int not null default 0,
  primary key (user_id, date)
);

alter table public.game_daily_limits enable row level security;

create policy "Users can manage own daily game limits"
  on public.game_daily_limits for all
  using (auth.uid() = user_id);

-- Function to increment game count and enforce free limit (3/day)
create or replace function public.record_game_played(p_user_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  insert into public.game_daily_limits (user_id, date, games_played)
  values (p_user_id, current_date, 1)
  on conflict (user_id, date)
  do update set games_played = game_daily_limits.games_played + 1
  returning games_played into v_count;
  return v_count;
end;
$$;

-- ── Marketplace deck downloads (deduplication + count) ────────────────────

create table if not exists public.marketplace_deck_downloads (
  deck_id uuid not null,
  user_id uuid not null references public.users(id) on delete cascade,
  downloaded_at timestamptz not null default now(),
  primary key (deck_id, user_id)
);

alter table public.marketplace_deck_downloads enable row level security;

create policy "Users can manage own downloads"
  on public.marketplace_deck_downloads for all
  using (auth.uid() = user_id);

-- ── Social post daily limit (server-authoritative for free users) ─────────

create table if not exists public.social_post_daily_limits (
  user_id uuid not null references public.users(id) on delete cascade,
  date date not null default current_date,
  posts_created int not null default 0,
  primary key (user_id, date)
);

alter table public.social_post_daily_limits enable row level security;

create policy "Users can manage own post limits"
  on public.social_post_daily_limits for all
  using (auth.uid() = user_id);
