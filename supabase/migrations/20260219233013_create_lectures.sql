-- Lectures
create table public.lectures (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  subject text,
  exam_id uuid references public.exams(id) on delete set null,
  audio_url text,
  duration_seconds int,
  file_size_bytes bigint,
  status text not null default 'uploaded' check (status in ('uploaded', 'transcribing', 'summarizing', 'ready', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.lectures enable row level security;
create policy "Users can manage own lectures" on public.lectures
  for all using (auth.uid() = user_id);

create trigger handle_lectures_updated_at
  before update on public.lectures
  for each row execute function extensions.moddatetime(updated_at);

-- Lecture transcripts
create table public.lecture_transcripts (
  id uuid primary key default extensions.uuid_generate_v4(),
  lecture_id uuid not null references public.lectures(id) on delete cascade,
  content text not null,
  language_code text not null default 'en',
  provider text check (provider in ('whisper', 'manual')),
  created_at timestamptz not null default now()
);

alter table public.lecture_transcripts enable row level security;
create policy "Users can read transcripts of own lectures" on public.lecture_transcripts
  for select using (
    exists (
      select 1 from public.lectures l
      where l.id = lecture_transcripts.lecture_id and l.user_id = auth.uid()
    )
  );
create policy "System can insert transcripts" on public.lecture_transcripts
  for insert with check (
    exists (
      select 1 from public.lectures l
      where l.id = lecture_transcripts.lecture_id and l.user_id = auth.uid()
    )
  );

-- Lecture summaries
create table public.lecture_summaries (
  id uuid primary key default extensions.uuid_generate_v4(),
  lecture_id uuid not null references public.lectures(id) on delete cascade,
  summary text not null,
  key_points jsonb default '[]',
  provider text check (provider in ('groq', 'openai')),
  created_at timestamptz not null default now()
);

alter table public.lecture_summaries enable row level security;
create policy "Users can read summaries of own lectures" on public.lecture_summaries
  for select using (
    exists (
      select 1 from public.lectures l
      where l.id = lecture_summaries.lecture_id and l.user_id = auth.uid()
    )
  );
create policy "System can insert summaries" on public.lecture_summaries
  for insert with check (
    exists (
      select 1 from public.lectures l
      where l.id = lecture_summaries.lecture_id and l.user_id = auth.uid()
    )
  );
