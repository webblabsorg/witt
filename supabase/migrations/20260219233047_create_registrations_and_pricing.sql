-- Exam registrations
create table public.exam_registrations (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade,
  exam_date date,
  target_score numeric,
  is_purchased boolean not null default false,
  purchase_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, exam_id)
);

alter table public.exam_registrations enable row level security;
create policy "Users can manage own registrations" on public.exam_registrations
  for all using (auth.uid() = user_id);

create trigger handle_exam_registrations_updated_at
  before update on public.exam_registrations
  for each row execute function extensions.moddatetime(updated_at);

-- Deferred RLS policy on questions for purchased exams
create policy "Users can read questions for purchased exams" on public.questions
  for select using (
    exists (
      select 1 from public.exam_registrations er
      where er.user_id = auth.uid() and er.exam_id = questions.exam_id and er.is_purchased = true
    )
  );

-- Pricing (per-exam pricing in USD base)
create table public.pricing (
  id uuid primary key default extensions.uuid_generate_v4(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  tier int not null check (tier between 1 and 5),
  price_usd numeric not null,
  bundle_discount_pct numeric not null default 0,
  description text,
  created_at timestamptz not null default now(),
  unique (exam_id, tier)
);

alter table public.pricing enable row level security;
create policy "Pricing is publicly readable" on public.pricing for select using (true);

-- Currency rates cache
create table public.currency_rates (
  id uuid primary key default extensions.uuid_generate_v4(),
  currency_code text not null unique,
  rate_to_usd numeric not null,
  symbol text,
  updated_at timestamptz not null default now()
);

alter table public.currency_rates enable row level security;
create policy "Currency rates are publicly readable" on public.currency_rates for select using (true);
