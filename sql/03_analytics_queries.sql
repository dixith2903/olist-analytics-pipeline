-- Q1: Overall KPIs
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(price) AS product_revenue,
    SUM(freight_value) AS freight_revenue,
    SUM(price + freight_value) AS total_revenue,
    ROUND(SUM(price + freight_value) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM fact_order_items
WHERE order_status = 'delivered';

Go

-- Q2: Monthly revenue (note: 2016 and 2018 are partial years)
SELECT 
    d.year, d.month,
    SUM(foi.price + foi.freight_value) AS revenue
FROM fact_order_items foi
JOIN dim_date d ON foi.purchase_date = d.full_date
WHERE foi.order_status = 'delivered'
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

Go

-- Q3: Best-selling product categories
SELECT TOP 10
    dp.category,
    COUNT(*) AS items_sold,
    SUM(foi.price) AS revenue
FROM fact_order_items foi
JOIN dim_product dp ON foi.product_id = dp.product_id
WHERE foi.order_status = 'delivered'
GROUP BY dp.category
ORDER BY revenue DESC;

Go

-- Q4: Revenue by customer state (São Paulo dominance)
SELECT TOP 10
    dc.customer_state,
    COUNT(DISTINCT foi.order_id) AS orders,
    SUM(foi.price + foi.freight_value) AS revenue
FROM fact_order_items foi
JOIN dim_customer dc ON foi.customer_id = dc.customer_id
WHERE foi.order_status = 'delivered'
GROUP BY dc.customer_state
ORDER BY revenue DESC;

Go

-- Q5: Seller leaderboard by revenue
SELECT TOP 10
    ds.seller_id,
    ds.seller_state,
    COUNT(DISTINCT foi.order_id) AS orders,
    SUM(foi.price) AS revenue
FROM fact_order_items foi
JOIN dim_seller ds ON foi.seller_id = ds.seller_id
WHERE foi.order_status = 'delivered'
GROUP BY ds.seller_id, ds.seller_state
ORDER BY revenue DESC;

Go

-- Q6: Categories with the worst review scores
SELECT TOP 10
    dp.category,
    COUNT(fr.review_id) AS review_count,
    ROUND(AVG(CAST(fr.review_score AS FLOAT)), 2) AS avg_score
FROM fact_order_items foi
JOIN fact_reviews fr ON foi.order_id = fr.order_id
JOIN dim_product dp ON foi.product_id = dp.product_id
GROUP BY dp.category
ORDER BY avg_score ASC;

Go

-- Q7: Payment type breakdown
SELECT 
    payment_type,
    COUNT(*) AS transactions,
    SUM(payment_value) AS total_value,
    ROUND(AVG(CAST(payment_installments AS FLOAT)), 1) AS avg_installments
FROM fact_payments
GROUP BY payment_type
ORDER BY total_value DESC;

Go

-- Q8: Which categories cost the most to ship (freight as % of order value)
SELECT TOP 10
    dp.category,
    SUM(foi.freight_value) AS freight,
    SUM(foi.price + foi.freight_value) AS order_value,
    ROUND(100.0 * SUM(foi.freight_value) / SUM(foi.price + foi.freight_value), 1) AS freight_pct
FROM fact_order_items foi
JOIN dim_product dp ON foi.product_id = dp.product_id
WHERE foi.order_status = 'delivered'
GROUP BY dp.category
ORDER BY freight_pct DESC;

Go

-- Q9: Revenue growth vs previous month, using LAG
;WITH monthly AS (
    SELECT d.year, d.month,
           SUM(foi.price + foi.freight_value) AS revenue
    FROM fact_order_items foi
    JOIN dim_date d ON foi.purchase_date = d.full_date
    WHERE foi.order_status = 'delivered'
    GROUP BY d.year, d.month
)
SELECT 
    year, month, revenue,
    LAG(revenue) OVER (ORDER BY year, month) AS prev_month,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year, month)) 
        / NULLIF(LAG(revenue) OVER (ORDER BY year, month), 0), 1) AS growth_pct
FROM monthly
ORDER BY year, month;

Go

-- Q10: Best category in each year, ranked with ROW_NUMBER
;WITH cat_year AS (
    SELECT 
        d.year, dp.category,
        SUM(foi.price + foi.freight_value) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY d.year 
                           ORDER BY SUM(foi.price + foi.freight_value) DESC) AS rn
    FROM fact_order_items foi
    JOIN dim_product dp ON foi.product_id = dp.product_id
    JOIN dim_date d ON foi.purchase_date = d.full_date
    WHERE foi.order_status = 'delivered'
    GROUP BY d.year, dp.category
)
SELECT year, category, revenue, rn AS rank_in_year
FROM cat_year
WHERE rn <= 3
ORDER BY year, rn;

Go

-- Q11: One-time vs repeat customers
-- customer_id is unique PER ORDER; customer_unique_id identifies the actual person
;WITH order_counts AS (
    SELECT dc.customer_unique_id,
           COUNT(DISTINCT foi.order_id) AS orders
    FROM fact_order_items foi
    JOIN dim_customer dc ON foi.customer_id = dc.customer_id
    GROUP BY dc.customer_unique_id
)
SELECT 
    CASE WHEN orders = 1 THEN 'one-time' ELSE 'repeat' END AS customer_type,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_counts), 1) AS pct
FROM order_counts
GROUP BY CASE WHEN orders = 1 THEN 'one-time' ELSE 'repeat' END;

Go

-- Q12: Top sellers ranked — shows difference between RANK and DENSE_RANK
;WITH seller_rev AS (
    SELECT ds.seller_id, ds.seller_state,
           SUM(foi.price + foi.freight_value) AS revenue
    FROM fact_order_items foi
    JOIN dim_seller ds ON foi.seller_id = ds.seller_id
    WHERE foi.order_status = 'delivered'
    GROUP BY ds.seller_id, ds.seller_state
)
SELECT TOP 10
    seller_id, seller_state, revenue,
    RANK() OVER (ORDER BY revenue DESC) AS [rank],
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS dense_rank
FROM seller_rev
ORDER BY revenue DESC;

Go

-- Q13: Cumulative revenue over time (running total)
;WITH monthly AS (
    SELECT d.year, d.month,
           SUM(foi.price + foi.freight_value) AS revenue
    FROM fact_order_items foi
    JOIN dim_date d ON foi.purchase_date = d.full_date
    WHERE foi.order_status = 'delivered'
    GROUP BY d.year, d.month
)
SELECT 
    year, month, revenue,
    SUM(revenue) OVER (ORDER BY year, month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM monthly
ORDER BY year, month;

Go

-- Q14: Daily revenue smoothed with 7-day moving average
;WITH daily AS (
    SELECT foi.purchase_date,
           SUM(foi.price + foi.freight_value) AS revenue
    FROM fact_order_items foi
    WHERE foi.order_status = 'delivered'
    GROUP BY foi.purchase_date
)
SELECT TOP 30
    purchase_date, revenue,
    ROUND(AVG(revenue) OVER (ORDER BY purchase_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0) AS moving_avg_7d
FROM daily
ORDER BY purchase_date DESC;

Go

-- Q15: Delivery reliability trend (negative/zero delay = on time)
SELECT 
    d.year, d.month,
    COUNT(*) AS items,
    ROUND(100.0 * SUM(CASE WHEN foi.delivery_delay_days <= 0 THEN 1 ELSE 0 END) 
        / COUNT(*), 1) AS on_time_pct
FROM fact_order_items foi
JOIN dim_date d ON foi.purchase_date = d.full_date
WHERE foi.order_status = 'delivered'
GROUP BY d.year, d.month
ORDER BY year, month;

Go

-- Q16: Which seller states ship latest?
SELECT 
    ds.seller_state,
    COUNT(*) AS items,
    ROUND(100.0 * SUM(CASE WHEN foi.delivery_delay_days > 0 THEN 1 ELSE 0 END) 
        / COUNT(*), 1) AS late_pct,
    ROUND(AVG(CAST(foi.delivery_delay_days AS FLOAT)), 1) AS avg_delay_days
FROM fact_order_items foi
JOIN dim_seller ds ON foi.seller_id = ds.seller_id
WHERE foi.order_status = 'delivered'
GROUP BY ds.seller_state
ORDER BY late_pct DESC;

Go

-- Q17: Star distribution — expect bimodal (many 5s, notable 1s)
SELECT 
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM fact_reviews
GROUP BY review_score
ORDER BY review_score;

Go

-- Q18: Best-selling individual products
SELECT TOP 10
    foi.product_id, dp.category,
    COUNT(*) AS times_sold,
    SUM(foi.price) AS revenue
FROM fact_order_items foi
JOIN dim_product dp ON foi.product_id = dp.product_id
WHERE foi.order_status = 'delivered'
GROUP BY foi.product_id, dp.category
ORDER BY revenue DESC;

Go

-- Q19: Avg delivery days by category
SELECT TOP 10
    dp.category,
    ROUND(AVG(CAST(foi.delivery_days AS FLOAT)), 1) AS avg_delivery_days
FROM fact_order_items foi
JOIN dim_product dp ON foi.product_id = dp.product_id
WHERE foi.order_status = 'delivered' AND foi.delivery_days IS NOT NULL
GROUP BY dp.category
ORDER BY avg_delivery_days DESC;

Go

-- Q20: Does late delivery destroy review scores? (the correlation query)
;WITH delivery_reviews AS (
    SELECT DISTINCT
        foi.order_id,
        foi.delivery_delay_days,
        fr.review_score
    FROM fact_order_items foi
    JOIN fact_reviews fr ON foi.order_id = fr.order_id
    WHERE foi.order_status = 'delivered'
)
SELECT 
    CASE 
        WHEN delivery_delay_days < 0 THEN 'early'
        WHEN delivery_delay_days = 0 THEN 'on_time'
        WHEN delivery_delay_days BETWEEN 1 AND 3 THEN 'late_1_3_days'
        WHEN delivery_delay_days BETWEEN 4 AND 7 THEN 'late_4_7_days'
        ELSE 'late_8_plus_days'
    END AS delivery_bucket,
    COUNT(*) AS orders,
    ROUND(AVG(CAST(review_score AS FLOAT)), 2) AS avg_review_score
FROM delivery_reviews
GROUP BY CASE 
        WHEN delivery_delay_days < 0 THEN 'early'
        WHEN delivery_delay_days = 0 THEN 'on_time'
        WHEN delivery_delay_days BETWEEN 1 AND 3 THEN 'late_1_3_days'
        WHEN delivery_delay_days BETWEEN 4 AND 7 THEN 'late_4_7_days'
        ELSE 'late_8_plus_days'
    END
ORDER BY avg_review_score DESC;

Go