-- Community posts (Q&A forum)
create table public.community_posts (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  body text not null,
  exam_id uuid references public.exams(id) on delete set null,
  subject text,
  tags text[] default '{}',
  upvotes int not null default 0,
  reply_count int not null default 0,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.community_posts enable row level security;
create policy "Community posts are publicly readable" on public.community_posts
  for select using (true);
create policy "Users can insert own posts" on public.community_posts
  for insert with check (auth.uid() = user_id);
create policy "Users can update own posts" on public.community_posts
  for update using (auth.uid() = user_id);
create policy "Users can delete own posts" on public.community_posts
  for delete using (auth.uid() = user_id);

create trigger handle_community_posts_updated_at
  before update on public.community_posts
  for each row execute function extensions.moddatetime(updated_at);

-- Community replies
create table public.community_replies (
  id uuid primary key default extensions.uuid_generate_v4(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  body text not null,
  upvotes int not null default 0,
  is_accepted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.community_replies enable row level security;
create policy "Community replies are publicly readable" on public.community_replies
  for select using (true);
create policy "Users can insert own replies" on public.community_replies
  for insert with check (auth.uid() = user_id);
create policy "Users can update own replies" on public.community_replies
  for update using (auth.uid() = user_id);
create policy "Users can delete own replies" on public.community_replies
  for delete using (auth.uid() = user_id);

create trigger handle_community_replies_updated_at
  before update on public.community_replies
  for each row execute function extensions.moddatetime(updated_at);

-- Study groups
create table public.study_groups (
  id uuid primary key default extensions.uuid_generate_v4(),
  name text not null,
  description text,
  exam_id uuid references public.exams(id) on delete set null,
  created_by uuid not null references public.users(id) on delete cascade,
  is_public boolean not null default true,
  member_count int not null default 1,
  max_members int not null default 50,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.study_groups enable row level security;
create policy "Public groups are readable" on public.study_groups
  for select using (is_public = true);
create policy "Users can create groups" on public.study_groups
  for insert with check (auth.uid() = created_by);
create policy "Creators can update groups" on public.study_groups
  for update using (auth.uid() = created_by);

create trigger handle_study_groups_updated_at
  before update on public.study_groups
  for each row execute function extensions.moddatetime(updated_at);

-- Study group members
create table public.study_group_members (
  id uuid primary key default extensions.uuid_generate_v4(),
  group_id uuid not null references public.study_groups(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'moderator', 'member')),
  joined_at timestamptz not null default now(),
  unique (group_id, user_id)
);

alter table public.study_group_members enable row level security;
create policy "Group members are readable by group members" on public.study_group_members
  for select using (
    exists (
      select 1 from public.study_group_members sgm
      where sgm.group_id = study_group_members.group_id and sgm.user_id = auth.uid()
    )
  );
create policy "Users can join groups" on public.study_group_members
  for insert with check (auth.uid() = user_id);
create policy "Users can leave groups" on public.study_group_members
  for delete using (auth.uid() = user_id);
