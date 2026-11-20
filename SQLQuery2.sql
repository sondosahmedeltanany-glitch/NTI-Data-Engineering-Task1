USE OlistStoreDB;
GO

-- Q1. الأداء العام (الطلبات الـ delivered)
SELECT COUNT(DISTINCT o.o_id)                           AS total_orders,
       SUM(oi.price)                                    AS total_revenue,
       ROUND(SUM(oi.price) / COUNT(DISTINCT o.o_id), 2) AS avg_order_value
FROM Orders o
JOIN Order_Item oi ON oi.o_id = o.o_id
WHERE o.o_status = 'delivered';

-- Q2. توزيع الطلبات حسب الحالة
SELECT o_status,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM Orders
GROUP BY o_status
ORDER BY orders DESC;

-- Q3. الإيراد شهر بشهر
SELECT YEAR(o.purchase_timestamp)  AS yr,
       MONTH(o.purchase_timestamp) AS mon,
       COUNT(DISTINCT o.o_id)      AS orders,
       SUM(oi.price)               AS revenue
FROM Orders o
JOIN Order_Item oi ON oi.o_id = o.o_id
WHERE o.o_status = 'delivered'
GROUP BY YEAR(o.purchase_timestamp), MONTH(o.purchase_timestamp)
ORDER BY yr, mon;