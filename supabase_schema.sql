-- Business Solutions System - Supabase setup / repair
-- Run this entire script in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete set null,
  name text not null default 'My General Shop',
  created_at timestamptz not null default now()
);
create table if not exists public.products (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, name text not null, buying_price numeric(12,2) not null default 0, selling_price numeric(12,2) not null default 0, stock numeric(14,3) not null default 0, min_stock numeric(14,3) not null default 0, unit text not null default 'piece', stock_type text not null default 'normal', created_at timestamptz not null default now());
create table if not exists public.sales (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, product_id uuid references public.products(id) on delete set null, quantity numeric(14,3) not null, total numeric(12,2) not null default 0, cost_total numeric(12,2) not null default 0, gross_profit numeric(12,2) not null default 0, payment_method text not null default 'Cash', created_at timestamptz not null default now());
create table if not exists public.expenses (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, category text not null, amount numeric(12,2) not null default 0, note text, created_at timestamptz not null default now());
create table if not exists public.customers (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, name text not null, phone text, balance numeric(12,2) not null default 0, created_at timestamptz not null default now());
create table if not exists public.suppliers (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, name text not null, phone text, balance numeric(12,2) not null default 0, created_at timestamptz not null default now());
create table if not exists public.purchases (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, product_id uuid references public.products(id) on delete set null, quantity numeric(14,3) not null, total_cost numeric(12,2) not null default 0, supplier_id uuid references public.suppliers(id) on delete set null, created_at timestamptz not null default now());

alter table public.sales add column if not exists cost_total numeric(12,2) not null default 0;
alter table public.sales add column if not exists gross_profit numeric(12,2) not null default 0;

alter table public.shops enable row level security; alter table public.products enable row level security; alter table public.sales enable row level security; alter table public.expenses enable row level security; alter table public.customers enable row level security; alter table public.suppliers enable row level security; alter table public.purchases enable row level security;

drop policy if exists "signed in shops" on public.shops; create policy "signed in shops" on public.shops for all to authenticated using (true) with check (true);
drop policy if exists "signed in products" on public.products; create policy "signed in products" on public.products for all to authenticated using (true) with check (true);
drop policy if exists "signed in sales" on public.sales; create policy "signed in sales" on public.sales for all to authenticated using (true) with check (true);
drop policy if exists "signed in expenses" on public.expenses; create policy "signed in expenses" on public.expenses for all to authenticated using (true) with check (true);
drop policy if exists "signed in customers" on public.customers; create policy "signed in customers" on public.customers for all to authenticated using (true) with check (true);
drop policy if exists "signed in suppliers" on public.suppliers; create policy "signed in suppliers" on public.suppliers for all to authenticated using (true) with check (true);
drop policy if exists "signed in purchases" on public.purchases; create policy "signed in purchases" on public.purchases for all to authenticated using (true) with check (true);

-- Ensure there is one shared shop. If none exists, the first signed-in app session creates it.

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.shops, public.products, public.sales, public.expenses, public.customers, public.suppliers, public.purchases to authenticated;
