# Business Solutions System — New Shop

This package uses a dedicated NEW shop ID and starts with no historical shop data.

Run `supabase_schema.sql` in the Supabase SQL Editor, then deploy `index.html`. If you previously ran an older version, this corrected SQL safely makes `shops.owner_id` nullable before creating the shared fresh shop.

Initial state: 0 sales, KSh 0 sales, KSh 0 gross profit, KSh 0 expenses, no products/stock, customers, suppliers, purchases, or audit history.

All authenticated devices using this package share this same new shop through Supabase.


## Multi-device and product colour update
- The shop uses one shared Supabase shop ID so authenticated phones and computers see the same records.
- Supabase Realtime subscriptions refresh products, sales, expenses and audit activity on other signed-in devices.
- The Products form includes selectable colours: Black, Green, Blue, White, Red, Yellow, Orange, Purple, Pink, Brown, Grey and Other.
- Product colour is stored in Supabase, so it remains the same across devices.
- Run the full `supabase_schema.sql` after updating an existing database; it adds the `products.color` column and enables Realtime publication for the shared tables.
