-- Users table (extends Supabase auth.users)
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  role text not null default 'student' check (role in ('student', 'teacher', 'parent')),
  education_level text check (education_level in ('middle_school', 'high_school', 'college', 'graduate_school', 'professional', 'other')),
  country_code text,
  language_code text not null default 'en',
  currency_code text not null default 'USD',
  timezone text,
  study_time_daily text check (study_time_daily in ('15min', '30min', '1hour', '2hours_plus')),
  learning_preferences text[] default '{}',
  subjects text[] default '{}',
  onboarding_completed boolean not null default false,
  onboarding_step int not null default 0,
  subscription_tier text not null default 'free' check (subscription_tier in ('free', 'premium_monthly', 'premium_yearly')),
  subscription_expires_at timestamptz,
  streak_count int not null default 0,
  streak_last_date date,
  xp_total int not null default 0,
  xp_level int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.users enable row level security;

create policy "Users can read own profile" on public.users for select using (auth.uid() = id);
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.users for insert with check (auth.uid() = id);

create trigger handle_users_updated_at before update on public.users
  for each row execute function extensions.moddatetime(updated_at);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();
