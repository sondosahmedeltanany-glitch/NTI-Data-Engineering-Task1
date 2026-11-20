 SELECT 'Customer' AS tbl, COUNT(*) AS final_cnt FROM Customer
UNION ALL SELECT 'Sellers',       COUNT(*) FROM Sellers
UNION ALL SELECT 'Product',       COUNT(*) FROM Product
UNION ALL SELECT 'Orders',        COUNT(*) FROM Orders
UNION ALL SELECT 'Order_Item',    COUNT(*) FROM Order_Item
UNION ALL SELECT 'Order_Payment', COUNT(*) FROM Order_Payment
UNION ALL SELECT 'Review',        COUNT(*) FROM Review;

SELECT TOP 100 * FROM Orders;
SELECT TOP 100 * FROM Order_Item;