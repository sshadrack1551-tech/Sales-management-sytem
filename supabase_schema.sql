-- Business Solutions System - Supabase setup / repair
-- Run this entire script in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete set null,
  name text not null default 'My General Shop',
  created_at timestamptz not null default now()
);

-- Existing projects may have owner_id marked NOT NULL. This shared shop does not
-- require a single owner, so make the column nullable before creating the fresh shop.
alter table public.shops alter column owner_id drop not null;
create table if not exists public.products (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, name text not null, buying_price numeric(12,2) not null default 0, selling_price numeric(12,2) not null default 0, stock numeric(14,3) not null default 0, min_stock numeric(14,3) not null default 0, unit text not null default 'piece', stock_type text not null default 'normal', color text not null default 'Other', created_at timestamptz not null default now());
create table if not exists public.sales (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, product_id uuid references public.products(id) on delete set null, quantity numeric(14,3) not null, total numeric(12,2) not null default 0, cost_total numeric(12,2) not null default 0, gross_profit numeric(12,2) not null default 0, payment_method text not null default 'Cash', created_at timestamptz not null default now());
create table if not exists public.expenses (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, category text not null, amount numeric(12,2) not null default 0, note text, created_at timestamptz not null default now());
create table if not exists public.customers (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, name text not null, phone text, balance numeric(12,2) not null default 0, created_at timestamptz not null default now());
create table if not exists public.suppliers (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, name text not null, phone text, balance numeric(12,2) not null default 0, created_at timestamptz not null default now());
create table if not exists public.purchases (id uuid primary key default gen_random_uuid(), shop_id uuid not null references public.shops(id) on delete cascade, product_id uuid references public.products(id) on delete set null, quantity numeric(14,3) not null, total_cost numeric(12,2) not null default 0, supplier_id uuid references public.suppliers(id) on delete set null, created_at timestamptz not null default now());

alter table public.sales add column if not exists cost_total numeric(12,2) not null default 0;
alter table public.sales add column if not exists gross_profit numeric(12,2) not null default 0;
alter table public.products add column if not exists color text not null default 'Other';

alter table public.shops enable row level security; alter table public.products enable row level security; alter table public.sales enable row level security; alter table public.expenses enable row level security; alter table public.customers enable row level security; alter table public.suppliers enable row level security; alter table public.purchases enable row level security;

drop policy if exists "signed in shops" on public.shops; create policy "signed in shops" on public.shops for all to authenticated using (true) with check (true);
drop policy if exists "signed in products" on public.products; create policy "signed in products" on public.products for all to authenticated using (true) with check (true);
drop policy if exists "signed in sales" on public.sales; create policy "signed in sales" on public.sales for all to authenticated using (true) with check (true);
drop policy if exists "signed in expenses" on public.expenses; create policy "signed in expenses" on public.expenses for all to authenticated using (true) with check (true);
drop policy if exists "signed in customers" on public.customers; create policy "signed in customers" on public.customers for all to authenticated using (true) with check (true);
drop policy if exists "signed in suppliers" on public.suppliers; create policy "signed in suppliers" on public.suppliers for all to authenticated using (true) with check (true);
drop policy if exists "signed in purchases" on public.purchases; create policy "signed in purchases" on public.purchases for all to authenticated using (true) with check (true);

-- Fresh new shop for this deployment. Previous shop data is not used.
insert into public.shops (id, name)
values ('b3db87c9-070d-4a7d-b7c3-d579dd1cc078', 'My General Shop')
on conflict (id) do nothing;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.shops, public.products, public.sales, public.expenses, public.customers, public.suppliers, public.purchases to authenticated;

-- ============================================================
-- Theft-control / cashier audit log
-- ============================================================
create table if not exists public.shop_activity_logs (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  user_email text,
  action text not null,
  sale_id uuid references public.sales(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  product_name text,
  quantity numeric(14,3),
  amount numeric(12,2),
  details text,
  created_at timestamptz not null default now()
);

alter table public.shop_activity_logs enable row level security;
drop policy if exists "signed in audit read" on public.shop_activity_logs;
create policy "signed in audit read" on public.shop_activity_logs
  for select to authenticated using (true);
drop policy if exists "signed in audit insert" on public.shop_activity_logs;
create policy "signed in audit insert" on public.shop_activity_logs
  for insert to authenticated with check (true);
-- No UPDATE or DELETE policy is created: audit records are intentionally immutable.
grant select, insert on public.shop_activity_logs to authenticated;

-- Every completed POS sale is automatically copied to the immutable audit log.
create or replace function public.log_shop_sale()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  pname text;
begin
  select name into pname from public.products where id = new.product_id;
  insert into public.shop_activity_logs
    (shop_id,user_id,user_email,action,sale_id,product_id,product_name,quantity,amount,details,created_at)
  values
    (new.shop_id,auth.uid(),coalesce(auth.jwt()->>'email',''), 'SALE_COMPLETED',new.id,new.product_id,pname,new.quantity,new.total,'Payment: '||coalesce(new.payment_method,'Cash'),new.created_at);
  return new;
end;
$$;

drop trigger if exists trg_log_shop_sale on public.sales;
create trigger trg_log_shop_sale
after insert on public.sales
for each row execute function public.log_shop_sale();


-- Realtime synchronization: all signed-in devices receive shared shop changes.
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='shops') then
    execute 'alter publication supabase_realtime add table public.shops';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='products') then
    execute 'alter publication supabase_realtime add table public.products';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='sales') then
    execute 'alter publication supabase_realtime add table public.sales';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='expenses') then
    execute 'alter publication supabase_realtime add table public.expenses';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='customers') then
    execute 'alter publication supabase_realtime add table public.customers';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='suppliers') then
    execute 'alter publication supabase_realtime add table public.suppliers';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='purchases') then
    execute 'alter publication supabase_realtime add table public.purchases';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='shop_activity_logs') then
    execute 'alter publication supabase_realtime add table public.shop_activity_logs';
  end if;
end $$;
