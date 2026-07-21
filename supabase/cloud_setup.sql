-- ERP Duo Print 3D Cloud v1.1.0
-- Execute no Supabase: SQL Editor > New query > Run

create extension if not exists pgcrypto;

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Duo Print 3D',
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'admin',
  created_at timestamptz not null default now()
);

create table if not exists public.erp_snapshots (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  app_version text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.erp_snapshots enable row level security;

create or replace function public.current_company_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select company_id from public.profiles where user_id = auth.uid()
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_company_id uuid;
begin
  insert into public.companies(name, created_by)
  values (coalesce(new.raw_user_meta_data ->> 'company_name', 'Duo Print 3D'), new.id)
  returning id into new_company_id;

  insert into public.profiles(user_id, company_id, full_name, role)
  values (
    new.id,
    new_company_id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    'admin'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create policy "company members read company"
on public.companies for select to authenticated
using (id = public.current_company_id());

create policy "users read own profile"
on public.profiles for select to authenticated
using (user_id = auth.uid());

create policy "users update own profile"
on public.profiles for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "users manage own snapshot"
on public.erp_snapshots for all to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

grant select on public.companies to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.erp_snapshots to authenticated;
