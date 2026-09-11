CREATE DATABASE OlistWarehouse;
GO
USE OlistWarehouse;
GO
SELECT 'orders' AS tbl, COUNT(*) AS rows FROM clean_orders
UNION ALL SELECT 'items', COUNT(*) FROM clean_items
UNION ALL SELECT 'customers', COUNT(*) FROM clean_customers
UNION ALL SELECT 'sellers', COUNT(*) FROM clean_sellers
UNION ALL SELECT 'products', COUNT(*) FROM clean_products
UNION ALL SELECT 'payments', COUNT(*) FROM clean_payments
UNION ALL SELECT 'reviews', COUNT(*) FROM clean_reviews;