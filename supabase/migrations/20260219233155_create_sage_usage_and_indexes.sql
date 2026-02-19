-- Sage AI usage tracking
create table public.sage_usage (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  messages_today int not null default 0,
  messages_this_month int not null default 0,
  attachments_today int not null default 0,
  last_message_at timestamptz,
  daily_reset_at timestamptz not null default (date_trunc('day', now() at time zone 'UTC') + interval '1 day'),
  monthly_reset_at timestamptz not null default (date_trunc('month', now() at time zone 'UTC') + interval '1 month'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

alter table public.sage_usage enable row level security;
create policy "Users can manage own sage usage" on public.sage_usage
  for all using (auth.uid() = user_id);

create trigger handle_sage_usage_updated_at
  before update on public.sage_usage
  for each row execute function extensions.moddatetime(updated_at);

-- Sage conversations
create table public.sage_conversations (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text,
  mode text not null default 'chat' check (mode in ('chat', 'explain', 'homework', 'quiz', 'planning', 'flashcard_gen', 'lecture_summary')),
  message_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.sage_conversations enable row level security;
create policy "Users can manage own conversations" on public.sage_conversations
  for all using (auth.uid() = user_id);

create trigger handle_sage_conversations_updated_at
  before update on public.sage_conversations
  for each row execute function extensions.moddatetime(updated_at);

-- Sage messages
create table public.sage_messages (
  id uuid primary key default extensions.uuid_generate_v4(),
  conversation_id uuid not null references public.sage_conversations(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  provider text check (provider in ('groq', 'openai')),
  tokens_used int,
  attachment_url text,
  created_at timestamptz not null default now()
);

alter table public.sage_messages enable row level security;
create policy "Users can manage own messages" on public.sage_messages
  for all using (auth.uid() = user_id);

-- Performance indexes
create index idx_questions_exam_id on public.questions(exam_id);
create index idx_questions_section_id on public.questions(section_id);
create index idx_questions_difficulty on public.questions(difficulty);
create index idx_question_attempts_user_id on public.question_attempts(user_id);
create index idx_question_attempts_question_id on public.question_attempts(question_id);
create index idx_flashcard_progress_user_next_review on public.flashcard_progress(user_id, next_review_at);
create index idx_study_sessions_user_id on public.study_sessions(user_id);
create index idx_user_progress_user_exam on public.user_progress(user_id, exam_id);
create index idx_community_posts_exam_id on public.community_posts(exam_id);
create index idx_sage_messages_conversation_id on public.sage_messages(conversation_id);
create index idx_exam_registrations_user_id on public.exam_registrations(user_id);
