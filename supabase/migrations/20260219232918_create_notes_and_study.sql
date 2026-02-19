-- Notes
create table public.notes (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  content text,
  subject text,
  exam_id uuid references public.exams(id) on delete set null,
  is_pinned boolean not null default false,
  tags text[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notes enable row level security;
create policy "Users can manage own notes" on public.notes
  for all using (auth.uid() = user_id);

create trigger handle_notes_updated_at
  before update on public.notes
  for each row execute function extensions.moddatetime(updated_at);

-- Study plans
create table public.study_plans (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  exam_id uuid references public.exams(id) on delete set null,
  start_date date not null,
  end_date date,
  daily_minutes int not null default 30,
  schedule jsonb not null default '[]',
  is_active boolean not null default true,
  source text check (source in ('manual', 'ai_generated')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.study_plans enable row level security;
create policy "Users can manage own study plans" on public.study_plans
  for all using (auth.uid() = user_id);

create trigger handle_study_plans_updated_at
  before update on public.study_plans
  for each row execute function extensions.moddatetime(updated_at);

-- Study sessions (logged study time)
create table public.study_sessions (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  exam_id uuid references public.exams(id) on delete set null,
  module text not null,
  topic text,
  duration_seconds int not null,
  xp_earned int not null default 0,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.study_sessions enable row level security;
create policy "Users can manage own study sessions" on public.study_sessions
  for all using (auth.uid() = user_id);
