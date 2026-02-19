-- Game scores
create table public.game_scores (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  game_type text not null check (game_type in ('word_duel', 'quiz_royale', 'equation_rush', 'fact_or_fiction', 'crossword_builder', 'memory_match', 'timeline_challenge', 'spelling_bee', 'subject_boss_battles', 'brain_challenge')),
  score int not null default 0,
  time_spent_seconds int,
  is_multiplayer boolean not null default false,
  opponent_id uuid references public.users(id) on delete set null,
  result text check (result in ('win', 'loss', 'draw', 'completed')),
  created_at timestamptz not null default now()
);

alter table public.game_scores enable row level security;
create policy "Users can read own game scores" on public.game_scores
  for select using (auth.uid() = user_id);
create policy "Users can insert own game scores" on public.game_scores
  for insert with check (auth.uid() = user_id);

-- Vocabulary lists
create table public.vocab_lists (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  language_code text not null default 'en',
  exam_id uuid references public.exams(id) on delete set null,
  word_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.vocab_lists enable row level security;
create policy "Users can manage own vocab lists" on public.vocab_lists
  for all using (auth.uid() = user_id);

create trigger handle_vocab_lists_updated_at
  before update on public.vocab_lists
  for each row execute function extensions.moddatetime(updated_at);

-- Vocabulary words
create table public.vocab_words (
  id uuid primary key default extensions.uuid_generate_v4(),
  list_id uuid not null references public.vocab_lists(id) on delete cascade,
  word text not null,
  definition text not null,
  pronunciation text,
  audio_url text,
  example_sentence text,
  part_of_speech text,
  difficulty text check (difficulty in ('easy', 'medium', 'hard')),
  mastery_level int not null default 0 check (mastery_level between 0 and 5),
  created_at timestamptz not null default now()
);

alter table public.vocab_words enable row level security;
create policy "Users can manage vocab words in own lists" on public.vocab_words
  for all using (
    exists (
      select 1 from public.vocab_lists vl
      where vl.id = vocab_words.list_id and vl.user_id = auth.uid()
    )
  );
