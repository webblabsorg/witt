-- Exams catalog
create table public.exams (
  id uuid primary key default extensions.uuid_generate_v4(),
  name text not null,
  slug text not null unique,
  description text,
  country_codes text[] not null default '{}',
  category text not null check (category in ('university_entrance', 'professional', 'language', 'k12', 'graduate', 'certification', 'medical', 'legal', 'other')),
  scoring_type text not null default 'points' check (scoring_type in ('points', 'percentage', 'pass_fail', 'band', 'scaled')),
  score_min numeric,
  score_max numeric,
  passing_score numeric,
  pricing_tier int not null default 1 check (pricing_tier between 1 and 5),
  is_active boolean not null default true,
  icon_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.exams enable row level security;
create policy "Exams are publicly readable" on public.exams for select using (true);

create trigger handle_exams_updated_at
  before update on public.exams
  for each row execute function extensions.moddatetime(updated_at);

-- Exam sections
create table public.exam_sections (
  id uuid primary key default extensions.uuid_generate_v4(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  name text not null,
  slug text not null,
  description text,
  question_count int,
  time_limit_minutes int,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (exam_id, slug)
);

alter table public.exam_sections enable row level security;
create policy "Exam sections are publicly readable" on public.exam_sections for select using (true);

-- Questions
create table public.questions (
  id uuid primary key default extensions.uuid_generate_v4(),
  exam_id uuid references public.exams(id) on delete cascade,
  section_id uuid references public.exam_sections(id) on delete set null,
  question_type text not null default 'mcq' check (question_type in ('mcq', 'multi_select', 'true_false', 'fill_blank', 'short_answer', 'essay', 'matching', 'ordering')),
  difficulty text not null default 'medium' check (difficulty in ('easy', 'medium', 'hard', 'expert')),
  topic text,
  subtopic text,
  question_text text not null,
  question_media_url text,
  options jsonb,
  correct_answer jsonb not null,
  explanation text,
  explanation_media_url text,
  tags text[] default '{}',
  source text check (source in ('pre_generated', 'ai_claude', 'ai_groq', 'ai_openai', 'community', 'imported')),
  is_free boolean not null default false,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.questions enable row level security;
create policy "Free questions are publicly readable" on public.questions
  for select using (is_free = true);

-- Question attempts
create table public.question_attempts (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  exam_id uuid references public.exams(id) on delete set null,
  selected_answer jsonb not null,
  is_correct boolean not null,
  time_spent_seconds int,
  attempt_number int not null default 1,
  created_at timestamptz not null default now()
);

alter table public.question_attempts enable row level security;
create policy "Users can read own attempts" on public.question_attempts
  for select using (auth.uid() = user_id);
create policy "Users can insert own attempts" on public.question_attempts
  for insert with check (auth.uid() = user_id);
