# Business Solutions System — New Shop

This package uses a dedicated NEW shop ID and starts with no historical shop data.

Run `supabase_schema.sql` in the Supabase SQL Editor, then deploy `index.html`. If you previously ran an older version, this corrected SQL safely makes `shops.owner_id` nullable before creating the shared fresh shop.

Initial state: 0 sales, KSh 0 sales, KSh 0 gross profit, KSh 0 expenses, no products/stock, customers, suppliers, purchases, or audit history.

All authenticated devices using this package share this same new shop through Supabase.
