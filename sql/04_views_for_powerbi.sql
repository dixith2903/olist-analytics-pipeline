-- ============================================
-- Olist Marketplace Warehouse
-- File: 04_views_for_powerbi.sql
-- Purpose: Business-ready views for Power BI
-- ============================================

-- Main sales view: facts + all dimension attributes in one place
CREATE VIEW vw_sales AS
SELECT
    foi.order_id,
    foi.order_item_id,
    foi.purchase_date,
    d.year,
    d.month,
    d.month_name,
    d.month_year,
    foi.order_status,
    dp.category,
    dc.customer_state,
    dc.customer_city,
    dc.lat AS customer_lat,
    dc.lng AS customer_lng,
	ds.seller_id,
    ds.seller_state,
    ds.seller_city,
    ds.lat AS seller_lat,
    ds.lng AS seller_lng,
    foi.price,
    foi.freight_value,
    foi.price + foi.freight_value AS order_value,
    foi.delivery_days,
    foi.delivery_delay_days
FROM fact_order_items foi
JOIN dim_date d ON foi.purchase_date = d.full_date
LEFT JOIN dim_product dp ON foi.product_id = dp.product_id
LEFT JOIN dim_customer dc ON foi.customer_id = dc.customer_id
LEFT JOIN dim_seller ds ON foi.seller_id = ds.seller_id;
GO

-- Payments view
CREATE VIEW vw_payments AS
SELECT 
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM fact_payments;
GO

-- Reviews view
CREATE VIEW vw_reviews AS
SELECT 
    order_id,
    review_score,
    review_date
FROM fact_reviews;
GO

