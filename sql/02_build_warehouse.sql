CREATE TABLE dim_customer (
    customer_id VARCHAR(40) PRIMARY KEY,
    customer_unique_id VARCHAR(40),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5),
    lat FLOAT,
    lng FLOAT
);

INSERT INTO dim_customer
SELECT customer_id, customer_unique_id, customer_city, customer_state,
       CAST(lat AS FLOAT), CAST(lng AS FLOAT)
FROM clean_customers;

Go

CREATE TABLE dim_seller (
    seller_id VARCHAR(40) PRIMARY KEY,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5),
    lat FLOAT,
    lng FLOAT
);

INSERT INTO dim_seller
SELECT seller_id, seller_city, seller_state,
       CAST(lat AS FLOAT), CAST(lng AS FLOAT)
FROM clean_sellers;

Go

CREATE TABLE dim_product (
    product_id VARCHAR(40) PRIMARY KEY,
    category VARCHAR(60),
    weight_g INT,
    length_cm INT,
    height_cm INT,
    width_cm INT
);

INSERT INTO dim_product
SELECT product_id, product_category_name_english,
       CAST(product_weight_g AS INT), CAST(product_length_cm AS INT),
       CAST(product_height_cm AS INT), CAST(product_width_cm AS INT)
FROM clean_products;

Go

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,      -- YYYYMMDD, e.g. 20171002
    full_date DATE,
    [year] INT,
    [quarter] INT,
    [month] INT,
    month_name VARCHAR(10),
    month_year VARCHAR(10)         -- '2017-10', sortable
);

;WITH dates AS (
    SELECT CAST('2016-01-01' AS DATE) AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date) FROM dates
    WHERE full_date < '2018-12-31'
)
INSERT INTO dim_date
SELECT
    CAST(CONVERT(CHAR(8), full_date, 112) AS INT),
    full_date,
    YEAR(full_date),
    DATEPART(QUARTER, full_date),
    MONTH(full_date),
    DATENAME(MONTH, full_date),
    CONVERT(CHAR(7), full_date, 120)
FROM dates
OPTION (MAXRECURSION 2000);

Go

CREATE TABLE fact_order_items (
    order_id VARCHAR(40),
    order_item_id INT,
    product_id VARCHAR(40),
    seller_id VARCHAR(40),
    customer_id VARCHAR(40),
    order_status VARCHAR(20),
    purchase_date DATE,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    delivery_days INT,
    delivery_delay_days INT,       -- negative = early, positive = late
    PRIMARY KEY (order_id, order_item_id)
);

INSERT INTO fact_order_items
SELECT
    i.order_id,
    CAST(i.order_item_id AS INT),
    i.product_id,
    i.seller_id,
    o.customer_id,
    o.order_status,
    CAST(o.order_purchase_timestamp AS DATE),
    CAST(i.price AS DECIMAL(10,2)),
    CAST(i.freight_value AS DECIMAL(10,2)),
    DATEDIFF(DAY, CAST(o.order_purchase_timestamp AS DATETIME),
                 CAST(o.order_delivered_customer_date AS DATETIME)),
    DATEDIFF(DAY, CAST(o.order_estimated_delivery_date AS DATETIME),
                 CAST(o.order_delivered_customer_date AS DATETIME))
FROM clean_items i
JOIN clean_orders o ON i.order_id = o.order_id;

Go

CREATE TABLE fact_payments (
    order_id VARCHAR(40),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

INSERT INTO fact_payments
SELECT order_id, CAST(payment_sequential AS INT), payment_type,
       CAST(payment_installments AS INT), CAST(payment_value AS DECIMAL(10,2))
FROM clean_payments;

Go

CREATE TABLE fact_reviews (
    review_id VARCHAR(60),
    order_id VARCHAR(40),
    review_score INT,
    review_date DATE
);

INSERT INTO fact_reviews
SELECT review_id, order_id, CAST(review_score AS INT),
       CAST(review_creation_date AS DATE)
FROM clean_reviews;

Go