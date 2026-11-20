/* =====================================================================
   OlistStoreDB - Views and Indexes
   Run AFTER the tables are created and the data is loaded.
   Safe to re-run (uses CREATE OR ALTER / DROP INDEX IF EXISTS).
   ===================================================================== */
USE OlistStoreDB;
GO

/* =====================================================================
   PART 1: INDEXES
   Primary keys already have clustered indexes, so these cover:
   - foreign key columns used in joins
   - columns used often in WHERE / GROUP BY
   ===================================================================== */

-- Orders: join to Customer, filter by status, group by purchase date
DROP INDEX IF EXISTS ix_orders_c_id ON Orders;
CREATE NONCLUSTERED INDEX ix_orders_c_id
    ON Orders (c_id);

DROP INDEX IF EXISTS ix_orders_status_purchase ON Orders;
CREATE NONCLUSTERED INDEX ix_orders_status_purchase
    ON Orders (o_status, purchase_timestamp);

-- Order_Item: PK is (o_id, o_item_id), so index the other two foreign keys
DROP INDEX IF EXISTS ix_order_item_p_id ON Order_Item;
CREATE NONCLUSTERED INDEX ix_order_item_p_id
    ON Order_Item (p_id)
    INCLUDE (price, freight_value);

DROP INDEX IF EXISTS ix_order_item_s_id ON Order_Item;
CREATE NONCLUSTERED INDEX ix_order_item_s_id
    ON Order_Item (s_id)
    INCLUDE (price, freight_value);

-- Review: PK starts with r_id, so o_id needs its own index for joins
DROP INDEX IF EXISTS ix_review_o_id ON Review;
CREATE NONCLUSTERED INDEX ix_review_o_id
    ON Review (o_id)
    INCLUDE (r_score);

-- Order_Payment: filter / group by payment type
DROP INDEX IF EXISTS ix_order_payment_type ON Order_Payment;
CREATE NONCLUSTERED INDEX ix_order_payment_type
    ON Order_Payment (payment_type)
    INCLUDE (payment_value);

-- Customer / Sellers / Product: common lookup and grouping columns
DROP INDEX IF EXISTS ix_customer_unique_id ON Customer;
CREATE NONCLUSTERED INDEX ix_customer_unique_id
    ON Customer (c_unique_id);

DROP INDEX IF EXISTS ix_customer_state ON Customer;
CREATE NONCLUSTERED INDEX ix_customer_state
    ON Customer (c_state);

DROP INDEX IF EXISTS ix_sellers_state ON Sellers;
CREATE NONCLUSTERED INDEX ix_sellers_state
    ON Sellers (s_state);

DROP INDEX IF EXISTS ix_product_category ON Product;
CREATE NONCLUSTERED INDEX ix_product_category
    ON Product (p_category_name);
GO

/* =====================================================================
   PART 2: VIEWS
   ===================================================================== */

-- ---------------------------------------------------------------------
-- View 1: one row per order with customer info, totals and delivery info
-- ---------------------------------------------------------------------
CREATE OR ALTER VIEW vw_order_details AS
SELECT  o.o_id,
        o.o_status,
        o.purchase_timestamp,
        o.o_delivered_customer_date,
        o.o_estimated_delivery_date,
        c.c_id,
        c.c_unique_id,
        c.c_city,
        c.c_state,
        ISNULL(i.items_count, 0)   AS items_count,
        ISNULL(i.items_value, 0)   AS items_value,
        ISNULL(i.freight_total, 0) AS freight_total,
        ISNULL(p.paid_value, 0)    AS paid_value,
        DATEDIFF(DAY, o.purchase_timestamp, o.o_delivered_customer_date) AS delivery_days,
        CASE
            WHEN o.o_delivered_customer_date IS NULL THEN NULL
            WHEN o.o_delivered_customer_date > o.o_estimated_delivery_date THEN 1
            ELSE 0
        END AS is_late
FROM Orders o
JOIN Customer c ON c.c_id = o.c_id
LEFT JOIN (SELECT o_id,
                  COUNT(*)           AS items_count,
                  SUM(price)         AS items_value,
                  SUM(freight_value) AS freight_total
           FROM Order_Item
           GROUP BY o_id) i ON i.o_id = o.o_id
LEFT JOIN (SELECT o_id,
                  SUM(payment_value) AS paid_value
           FROM Order_Payment
           GROUP BY o_id) p ON p.o_id = o.o_id;
GO

-- ---------------------------------------------------------------------
-- View 2: orders by status with percentage of total
-- ---------------------------------------------------------------------
CREATE OR ALTER VIEW vw_order_status_summary AS
SELECT  o_status,
        COUNT(*) AS orders,
        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM Orders
GROUP BY o_status;
GO

-- ---------------------------------------------------------------------
-- View 3: monthly revenue (delivered orders only, item price only)
-- ---------------------------------------------------------------------
CREATE OR ALTER VIEW vw_monthly_revenue AS
SELECT  YEAR(o.purchase_timestamp)  AS yr,
        MONTH(o.purchase_timestamp) AS mon,
        COUNT(DISTINCT o.o_id)      AS orders,
        SUM(oi.price)               AS revenue,
        ROUND(SUM(oi.price) / COUNT(DISTINCT o.o_id), 2) AS avg_order_value
FROM Orders o
JOIN Order_Item oi ON oi.o_id = o.o_id
WHERE o.o_status = 'delivered'
GROUP BY YEAR(o.purchase_timestamp), MONTH(o.purchase_timestamp);
GO

-- ---------------------------------------------------------------------
-- View 4: sales by product category (delivered orders only)
-- ---------------------------------------------------------------------
CREATE OR ALTER VIEW vw_sales_by_category AS
SELECT  ISNULL(p.p_category_name, 'unknown') AS category,
        COUNT(DISTINCT oi.o_id)              AS orders,
        COUNT(*)                             AS units_sold,
        SUM(oi.price)                        AS revenue,
        ROUND(AVG(oi.price), 2)              AS avg_item_price
FROM Order_Item oi
JOIN Orders  o ON o.o_id  = oi.o_id
JOIN Product p ON p.p_id  = oi.p_id
WHERE o.o_status = 'delivered'
GROUP BY ISNULL(p.p_category_name, 'unknown');
GO

-- ---------------------------------------------------------------------
-- View 5: seller performance (delivered orders only)
-- Review score is averaged per order first, so orders with several
-- reviews do not inflate revenue or item counts.
-- ---------------------------------------------------------------------
CREATE OR ALTER VIEW vw_seller_performance AS
SELECT  s.s_id,
        s.s_city,
        s.s_state,
        COUNT(*)                          AS orders,
        SUM(so.items)                     AS items_sold,
        SUM(so.revenue)                   AS revenue,
        ROUND(AVG(r.avg_score), 2)        AS avg_review_score
FROM Sellers s
JOIN (SELECT oi.s_id, oi.o_id,
             COUNT(*)      AS items,
             SUM(oi.price) AS revenue
      FROM Order_Item oi
      JOIN Orders o ON o.o_id = oi.o_id
      WHERE o.o_status = 'delivered'
      GROUP BY oi.s_id, oi.o_id) so ON so.s_id = s.s_id
LEFT JOIN (SELECT o_id,
                  AVG(CAST(r_score AS DECIMAL(5, 2))) AS avg_score
           FROM Review
           GROUP BY o_id) r ON r.o_id = so.o_id
GROUP BY s.s_id, s.s_city, s.s_state;
GO

/* =====================================================================
   PART 3: QUICK TESTS
   ===================================================================== */

-- List the indexes that were created
SELECT  OBJECT_NAME(i.object_id) AS table_name,
        i.name                   AS index_name,
        i.type_desc
FROM sys.indexes i
WHERE i.name LIKE 'ix[_]%'
ORDER BY table_name, index_name;

-- Try the views
SELECT TOP 10 * FROM vw_order_details ORDER BY purchase_timestamp DESC;
SELECT * FROM vw_order_status_summary ORDER BY orders DESC;
SELECT * FROM vw_monthly_revenue ORDER BY yr, mon;
SELECT TOP 10 * FROM vw_sales_by_category ORDER BY revenue DESC;
SELECT TOP 10 * FROM vw_seller_performance ORDER BY revenue DESC;
