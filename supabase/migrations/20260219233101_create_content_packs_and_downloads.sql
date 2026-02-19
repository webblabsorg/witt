-- Content packs (downloadable offline content)
create table public.content_packs (
  id uuid primary key default extensions.uuid_generate_v4(),
  name text not null,
  description text,
  pack_type text not null check (pack_type in ('exam', 'language', 'vocabulary', 'flashcards', 'games')),
  exam_id uuid references public.exams(id) on delete set null,
  language_code text,
  file_url text not null,
  file_size_bytes bigint not null,
  version int not null default 1,
  is_free boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.content_packs enable row level security;
create policy "Content packs are publicly readable" on public.content_packs
  for select using (is_active = true);

create trigger handle_content_packs_updated_at
  before update on public.content_packs
  for each row execute function extensions.moddatetime(updated_at);

-- User content downloads
create table public.user_content_downloads (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  pack_id uuid not null references public.content_packs(id) on delete cascade,
  downloaded_version int not null default 1,
  downloaded_at timestamptz not null default now(),
  last_synced_at timestamptz,
  unique (user_id, pack_id)
);

alter table public.user_content_downloads enable row level security;
create policy "Users can manage own downloads" on public.user_content_downloads
  for all using (auth.uid() = user_id);
