-- User progress (per-exam, per-topic)
create table public.user_progress (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  exam_id uuid references public.exams(id) on delete cascade,
  section_id uuid references public.exam_sections(id) on delete set null,
  topic text,
  total_questions int not null default 0,
  correct_answers int not null default 0,
  mastery_score numeric not null default 0,
  last_practiced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, exam_id, section_id, topic)
);

alter table public.user_progress enable row level security;
create policy "Users can manage own progress" on public.user_progress
  for all using (auth.uid() = user_id);

create trigger handle_user_progress_updated_at
  before update on public.user_progress
  for each row execute function extensions.moddatetime(updated_at);

-- Bookmarks
create table public.bookmarks (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, question_id)
);

alter table public.bookmarks enable row level security;
create policy "Users can manage own bookmarks" on public.bookmarks
  for all using (auth.uid() = user_id);

-- Saved questions
create table public.saved_questions (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, question_id)
);

alter table public.saved_questions enable row level security;
create policy "Users can manage own saved questions" on public.saved_questions
  for all using (auth.uid() = user_id);

-- Achievements
create table public.achievements (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  achievement_type text not null,
  achievement_key text not null,
  title text not null,
  description text,
  icon_url text,
  xp_reward int not null default 0,
  earned_at timestamptz not null default now(),
  unique (user_id, achievement_key)
);

alter table public.achievements enable row level security;
create policy "Users can read own achievements" on public.achievements
  for select using (auth.uid() = user_id);
create policy "Users can insert own achievements" on public.achievements
  for insert with check (auth.uid() = user_id);

-- Leaderboards
create table public.leaderboards (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  scope text not null check (scope in ('global', 'friends', 'school')),
  period text not null check (period in ('daily', 'weekly', 'all_time')),
  xp_score int not null default 0,
  rank int,
  updated_at timestamptz not null default now(),
  unique (user_id, scope, period)
);

alter table public.leaderboards enable row level security;
create policy "Leaderboards are publicly readable" on public.leaderboards
  for select using (true);
create policy "Users can manage own leaderboard entries" on public.leaderboards
  for all using (auth.uid() = user_id);
