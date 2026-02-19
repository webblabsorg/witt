-- Flashcard decks
create table public.flashcard_decks (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  description text,
  exam_id uuid references public.exams(id) on delete set null,
  topic text,
  is_public boolean not null default false,
  card_count int not null default 0,
  language_code text not null default 'en',
  tags text[] default '{}',
  source text check (source in ('manual', 'ai_generated', 'imported', 'community')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.flashcard_decks enable row level security;
create policy "Users can read own decks" on public.flashcard_decks
  for select using (auth.uid() = user_id or is_public = true);
create policy "Users can insert own decks" on public.flashcard_decks
  for insert with check (auth.uid() = user_id);
create policy "Users can update own decks" on public.flashcard_decks
  for update using (auth.uid() = user_id);
create policy "Users can delete own decks" on public.flashcard_decks
  for delete using (auth.uid() = user_id);

create trigger handle_flashcard_decks_updated_at
  before update on public.flashcard_decks
  for each row execute function extensions.moddatetime(updated_at);

-- Flashcards
create table public.flashcards (
  id uuid primary key default extensions.uuid_generate_v4(),
  deck_id uuid not null references public.flashcard_decks(id) on delete cascade,
  front_text text not null,
  back_text text not null,
  front_media_url text,
  back_media_url text,
  audio_url text,
  hint text,
  tags text[] default '{}',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.flashcards enable row level security;
create policy "Users can read flashcards in accessible decks" on public.flashcards
  for select using (
    exists (
      select 1 from public.flashcard_decks d
      where d.id = flashcards.deck_id and (d.user_id = auth.uid() or d.is_public = true)
    )
  );
create policy "Users can insert flashcards in own decks" on public.flashcards
  for insert with check (
    exists (
      select 1 from public.flashcard_decks d
      where d.id = flashcards.deck_id and d.user_id = auth.uid()
    )
  );
create policy "Users can update flashcards in own decks" on public.flashcards
  for update using (
    exists (
      select 1 from public.flashcard_decks d
      where d.id = flashcards.deck_id and d.user_id = auth.uid()
    )
  );
create policy "Users can delete flashcards in own decks" on public.flashcards
  for delete using (
    exists (
      select 1 from public.flashcard_decks d
      where d.id = flashcards.deck_id and d.user_id = auth.uid()
    )
  );

-- Flashcard progress (SM-2 spaced repetition)
create table public.flashcard_progress (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  flashcard_id uuid not null references public.flashcards(id) on delete cascade,
  ease_factor numeric not null default 2.5,
  interval_days int not null default 0,
  repetitions int not null default 0,
  next_review_at timestamptz not null default now(),
  last_reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, flashcard_id)
);

alter table public.flashcard_progress enable row level security;
create policy "Users can manage own flashcard progress" on public.flashcard_progress
  for all using (auth.uid() = user_id);
