-- ── Multiplayer queue + sessions ──────────────────────────────────────────

create table if not exists public.multiplayer_queue (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  game_id text not null,
  created_at timestamptz not null default now(),
  unique (user_id, game_id)
);

alter table public.multiplayer_queue enable row level security;

create policy "Users can manage own queue entry"
  on public.multiplayer_queue for all
  using (auth.uid() = user_id);

create index idx_multiplayer_queue_game on public.multiplayer_queue(game_id, created_at);

-- ── Multiplayer sessions ──────────────────────────────────────────────────

create table if not exists public.multiplayer_sessions (
  id uuid primary key default extensions.uuid_generate_v4(),
  game_id text not null,
  player1_id uuid not null references public.users(id) on delete cascade,
  player2_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'completed', 'abandoned')),
  winner_id uuid references public.users(id) on delete set null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  check (player1_id <> player2_id)
);

alter table public.multiplayer_sessions enable row level security;

create policy "Players can read own sessions"
  on public.multiplayer_sessions for select
  using (auth.uid() = player1_id or auth.uid() = player2_id);

create policy "Players can update own sessions"
  on public.multiplayer_sessions for update
  using (auth.uid() = player1_id or auth.uid() = player2_id);

create index idx_multiplayer_sessions_players
  on public.multiplayer_sessions(player1_id, player2_id);

-- ── Matchmaking function: pair two waiting players ─────────────────────────
-- Called by a Supabase Edge Function or cron job every few seconds.

create or replace function public.match_players(p_game_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_p1 uuid;
  v_p2 uuid;
  v_q1 uuid;
  v_q2 uuid;
begin
  -- Pick the two oldest waiting players for this game
  select id, user_id into v_q1, v_p1
  from public.multiplayer_queue
  where game_id = p_game_id
  order by created_at asc
  limit 1;

  select id, user_id into v_q2, v_p2
  from public.multiplayer_queue
  where game_id = p_game_id and user_id <> v_p1
  order by created_at asc
  limit 1;

  if v_p1 is null or v_p2 is null then return; end if;

  -- Create session
  insert into public.multiplayer_sessions (game_id, player1_id, player2_id)
  values (p_game_id, v_p1, v_p2);

  -- Remove both from queue
  delete from public.multiplayer_queue where id in (v_q1, v_q2);
end;
$$;
