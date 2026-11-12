
-- سامانه مدیریت فعالیت‌ها

create extension if not exists pgcrypto;

create table if not exists public.spaces (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete cascade,
  name text not null,
  sort_order integer default 0,
  created_at timestamptz default now()
);

alter table public.profiles
  add column if not exists space_id uuid references public.spaces(id) on delete set null;

alter table public.reports
  add column if not exists space_id uuid references public.spaces(id) on delete set null;

alter table public.spaces enable row level security;

drop policy if exists "Admins manage spaces" on public.spaces;
create policy "Admins manage spaces"
on public.spaces
for all
to authenticated
using ((auth.jwt()->'app_metadata'->>'role') = 'admin')
with check ((auth.jwt()->'app_metadata'->>'role') = 'admin');

drop policy if exists "Members read assigned spaces" on public.spaces;
create policy "Members read assigned spaces"
on public.spaces
for select
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.user_id = auth.uid()
      and p.space_id = spaces.id
  )
);

drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile"
on public.profiles
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users insert own reports" on public.reports;
create policy "Users insert own reports"
on public.reports
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users update own reports" on public.reports;
create policy "Users update own reports"
on public.reports
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
