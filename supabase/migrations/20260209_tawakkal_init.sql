-- Tawakkal v1 baseline schema
-- Execute in Supabase SQL editor or migration pipeline.

create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  preferred_lang text default 'id',
  created_at timestamptz not null default now()
);

create table if not exists public.user_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  surah_id integer not null,
  difficulty text not null check (difficulty in ('easy', 'medium', 'hard')),
  stage_status text not null default 'in_progress',
  score integer not null default 0,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (user_id, surah_id, difficulty)
);

create table if not exists public.user_streaks (
  user_id uuid primary key references auth.users (id) on delete cascade,
  current_streak integer not null default 0,
  longest_streak integer not null default 0,
  last_active_date date,
  freeze_tokens integer not null default 0
);

create table if not exists public.user_xp_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  event_type text not null,
  xp_delta integer not null,
  source_ref text,
  created_at timestamptz not null default now()
);

create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  badge_code text not null,
  awarded_at timestamptz not null default now(),
  meta_json jsonb not null default '{}'::jsonb
);

create table if not exists public.quiz_bank (
  quiz_id text primary key,
  surah_id integer not null,
  difficulty text not null check (difficulty in ('easy', 'medium', 'hard')),
  language text not null default 'id',
  questions_json jsonb not null,
  grounding_refs_json jsonb not null default '[]'::jsonb,
  version integer not null default 1,
  created_at timestamptz not null default now()
);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  quiz_id text not null references public.quiz_bank (quiz_id) on delete cascade,
  answers_json jsonb not null,
  score integer not null default 0,
  feedback_json jsonb,
  attempted_at timestamptz not null default now()
);

create table if not exists public.bookmarks_cloud (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  surah_id integer not null,
  ayah_number integer not null,
  created_at timestamptz not null default now(),
  unique (user_id, surah_id, ayah_number)
);

create table if not exists public.notes_cloud (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  surah_id integer not null,
  ayah_number integer not null,
  note_text text not null,
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  unique (user_id, surah_id, ayah_number)
);

create table if not exists public.audio_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  reciter_id text not null,
  surah_id integer not null,
  created_at timestamptz not null default now(),
  unique (user_id, reciter_id, surah_id)
);

create table if not exists public.content_versions (
  key text primary key,
  version integer not null,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.user_progress enable row level security;
alter table public.user_streaks enable row level security;
alter table public.user_xp_ledger enable row level security;
alter table public.user_badges enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.bookmarks_cloud enable row level security;
alter table public.notes_cloud enable row level security;
alter table public.audio_favorites enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
      and policyname = 'profiles_owner_rw'
  ) then
    create policy profiles_owner_rw on public.profiles
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'user_progress',
    'user_streaks',
    'user_xp_ledger',
    'user_badges',
    'quiz_attempts',
    'bookmarks_cloud',
    'notes_cloud',
    'audio_favorites'
  ]
  loop
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = table_name
        and policyname = table_name || '_owner_rw'
    ) then
      execute format(
        'create policy %I on public.%I using (auth.uid() = user_id) with check (auth.uid() = user_id)',
        table_name || '_owner_rw',
        table_name
      );
    end if;
  end loop;
end $$;

-- Optional policy for quiz bank read access.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'quiz_bank'
      and policyname = 'quiz_bank_read_all_authenticated'
  ) then
    create policy quiz_bank_read_all_authenticated on public.quiz_bank
      for select to authenticated using (true);
  end if;
end $$;
