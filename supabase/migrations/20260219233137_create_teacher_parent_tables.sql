-- Teacher classes
create table public.teacher_classes (
  id uuid primary key default extensions.uuid_generate_v4(),
  teacher_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  description text,
  class_code text not null unique,
  exam_id uuid references public.exams(id) on delete set null,
  student_count int not null default 0,
  max_students int not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.teacher_classes enable row level security;
create policy "Teachers can manage own classes" on public.teacher_classes
  for all using (auth.uid() = teacher_id);

create trigger handle_teacher_classes_updated_at
  before update on public.teacher_classes
  for each row execute function extensions.moddatetime(updated_at);

-- Class students (join table)
create table public.class_students (
  id uuid primary key default extensions.uuid_generate_v4(),
  class_id uuid not null references public.teacher_classes(id) on delete cascade,
  student_id uuid not null references public.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique (class_id, student_id)
);

alter table public.class_students enable row level security;
create policy "Students can read own membership" on public.class_students
  for select using (auth.uid() = student_id);
create policy "Students can join classes" on public.class_students
  for insert with check (auth.uid() = student_id);
create policy "Students can leave classes" on public.class_students
  for delete using (auth.uid() = student_id);

-- Cross-referencing policies (added after both tables exist)
create policy "Students can read classes they belong to" on public.teacher_classes
  for select using (
    exists (
      select 1 from public.class_students cs
      where cs.class_id = teacher_classes.id and cs.student_id = auth.uid()
    )
  );
create policy "Teachers can manage class students" on public.class_students
  for all using (
    exists (
      select 1 from public.teacher_classes tc
      where tc.id = class_students.class_id and tc.teacher_id = auth.uid()
    )
  );

-- Class assignments
create table public.class_assignments (
  id uuid primary key default extensions.uuid_generate_v4(),
  class_id uuid not null references public.teacher_classes(id) on delete cascade,
  teacher_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  description text,
  assignment_type text not null check (assignment_type in ('quiz', 'flashcards', 'mock_test', 'homework', 'reading')),
  content_id uuid,
  due_date timestamptz,
  max_score numeric,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.class_assignments enable row level security;
create policy "Teachers can manage own assignments" on public.class_assignments
  for all using (auth.uid() = teacher_id);
create policy "Students can read assignments for their classes" on public.class_assignments
  for select using (
    exists (
      select 1 from public.class_students cs
      where cs.class_id = class_assignments.class_id and cs.student_id = auth.uid()
    )
  );

create trigger handle_class_assignments_updated_at
  before update on public.class_assignments
  for each row execute function extensions.moddatetime(updated_at);

-- Parent links
create table public.parent_links (
  id uuid primary key default extensions.uuid_generate_v4(),
  parent_id uuid not null references public.users(id) on delete cascade,
  child_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'active', 'revoked')),
  link_code text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (parent_id, child_id)
);

alter table public.parent_links enable row level security;
create policy "Parents can manage own links" on public.parent_links
  for all using (auth.uid() = parent_id);
create policy "Children can read links to them" on public.parent_links
  for select using (auth.uid() = child_id);
create policy "Children can update link status" on public.parent_links
  for update using (auth.uid() = child_id);

create trigger handle_parent_links_updated_at
  before update on public.parent_links
  for each row execute function extensions.moddatetime(updated_at);
