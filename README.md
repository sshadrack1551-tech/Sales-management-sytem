# Business Solutions System — Shared Multi-Device Shop

This version is designed for a single shared shop accessed by multiple authenticated phones/computers.

## Multi-device behavior
- Every device logs into the same Supabase project/account system.
- All authenticated users can read and change the shared shop data through RLS policies.
- Supabase Realtime is enabled for products, sales, expenses, customers, suppliers, purchases, shop settings and audit logs. Changes made on one device are refreshed on other open devices automatically.
- Sales use a database transaction (`complete_shop_order`) so simultaneous cashiers cannot oversell the same stock.
- Stock removals use an atomic database function (`decrement_product_stock`).
- The app uses a dedicated fresh shop ID, so previous shop records are not displayed.

## Setup
1. In the exact Supabase project used by this app, open SQL Editor.
2. Run the entire `supabase_schema.sql` once.
3. Deploy `index.html` to your hosting/GitHub Pages site.
4. Create/sign in with Supabase Auth accounts on each phone/computer.
5. All signed-in devices work on the same shared shop.

The shop starts empty: no products, sales, expenses or audit records.
