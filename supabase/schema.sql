-- Mikoto — Supabase schema
-- Run this in Supabase Dashboard → SQL Editor → New query → Run.
-- Safe to re-run (uses IF NOT EXISTS / on conflict).

-- =========================================================
-- Tables
-- =========================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  plan text not null default 'free',
  cycle text not null default 'monthly',
  balance int not null default 15,
  trial_active boolean not null default false,
  trial_ends_at timestamptz,
  renewal_date timestamptz not null default (now() + interval '1 month'),
  total_generated int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_styles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.photos (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  style_id text not null,
  storage_path text not null,
  created_at timestamptz not null default now()
);

create index if not exists photos_user_created_idx on public.photos (user_id, created_at desc);

-- =========================================================
-- Row Level Security
-- =========================================================

alter table public.profiles enable row level security;
alter table public.user_styles enable row level security;
alter table public.photos enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "own styles" on public.user_styles;
create policy "own styles" on public.user_styles
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "own photos" on public.photos;
create policy "own photos" on public.photos
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =========================================================
-- Auto-create profile row on signup
-- =========================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'name')
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================
-- Storage bucket for generated photos (private)
-- =========================================================

insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;

drop policy if exists "own photo objects" on storage.objects;
create policy "own photo objects" on storage.objects
  for all to authenticated
  using (bucket_id = 'photos' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'photos' and auth.uid()::text = (storage.foldername(name))[1]);
