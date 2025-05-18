-- Changing column data types:
ALTER TABLE sales_data
MODIFY COLUMN Order_Date DATE,
MODIFY COLUMN Ship_Date DATE;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* **Basic:** */
--------------------------------------------------------------------------------
-- Task: 1. Find the total number of orders placed in each year. 
SELECT
	YEAR(Order_Date) AS Years,
	COUNT(Order_ID) AS Total_orders
FROM sales_data
GROUP BY YEAR(Order_Date)
ORDER BY Years;
-------------------------------------------------------------------------
-- Task: 2. List all products that have never been returned. 
SELECT
	Product_ID,
    Product_Name
FROM sales_data
WHERE (Returned = 'Not')
GROUP BY Product_Name, Product_ID;
-------------------------------------------------------------------------
-- Task: 3. List all orders placed by customers in the city of 'New York City'. 
SELECT *
FROM sales_data
WHERE City = 'New York City'
ORDER BY Order_Date;
----------------------------------------------------------------------
-- Task: 4. Count the number of unique customers in each state. 
SELECT
	State,
    COUNT(DISTINCT Customer_ID) AS No_of_Customers
FROM sales_data
GROUP BY State
ORDER BY No_of_Customers DESC;
------------------------------------------------------------------------
-- Task: 5. Find the customer who placed the largest single order in terms of quantity. 
SELECT
	Customer_ID,
    Customer_Name,
    Quantity
FROM sales_data
WHERE Quantity = (SELECT MAX(Quantity) FROM sales_data);
------------------------------------------------------------------------------
-- Task 6. Identify the customers who have placed more than 10 orders.
SELECT
	Customer_ID,
    Customer_Name,
    COUNT(Order_ID) AS Order_count
FROM sales_data
GROUP BY Customer_ID, Customer_Name
HAVING Order_count > 10
ORDER BY Order_count DESC;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* **Intermediate:** */
--------------------------------------------------------------------------------
-- Task 1. Calculate the average profit margin for each product category. 
 SELECT
	Category,
    ROUND( AVG(Profit),2) AS Avg_profit
 FROM sales_data
 GROUP BY Category
 ORDER BY Avg_profit DESC;
-------------------------------------------------------------------------------------------
-- Task 2. Calculate the total sales revenue for each year, grouped by customer segment. 
SELECT
	YEAR(Order_Date) AS YEARS,
    Segment,
    ROUND( SUM(Sales),2) AS Total_Sales,
    ROUND( SUM(Profit),2) AS Total_Profit
FROM sales_data
GROUP BY Segment, YEARS
ORDER BY YEARS, Total_Sales DESC;
------------------------------------------------------------------------------------------------
-- Task: 3. Identify the most popular shipping mode based on the number of orders. 
SELECT
	Ship_Mode AS Popular_shipping_mode,
    COUNT(Order_ID) AS No_of_orders
FROM sales_data
GROUP BY Ship_Mode
ORDER BY No_of_orders DESC
LIMIT 1;
------------------------------------------------------------------------------------------------
-- Task: 4. Find the customer with the longest time between their first and last orders. 
WITH Customer_1st_order AS ( SELECT
	Customer_ID,
    Customer_Name,
    MIN(Order_Date) AS First_order
FROM sales_data
GROUP BY Customer_ID,Customer_Name),

Customer_last_order AS ( 
	SELECT 
		Customer_ID,
        Customer_Name,
        MAX(Order_Date) AS Last_order
	FROM sales_data
	GROUP BY Customer_ID, Customer_Name)

SELECT 
	Customer_ID,
    Customer_Name,
    First_order,
    Last_order ,
	Longest_Time_diff,
    Longest_Time_diff_Rank
FROM (
SELECT 
	CFO.Customer_ID,
    CFO.Customer_Name,
    CFO.First_order,
    CLO.Last_order ,
    DATEDIFF(CLO.Last_order, CFO.First_order) AS Longest_Time_diff,
	RANK() OVER(ORDER BY DATEDIFF(CLO.Last_order, CFO.First_order) DESC) AS Longest_Time_diff_Rank
FROM Customer_1st_order CFO
JOIN Customer_last_order CLO
ON CFO.Customer_ID = CLO.Customer_ID
ORDER BY Longest_Time_diff DESC) AS A
WHERE Longest_Time_diff_Rank = 1;
----------------------------------------------------------------------------------------------------
-- Task 5. Determine the top 5 customers with the highest total sales amount. 
SELECT
	Customer_ID,
    Customer_Name,
    ROUND( SUM(Sales),2) AS Total_Sales
FROM sales_data
GROUP BY Customer_ID, Customer_Name
ORDER BY Total_Sales DESC
LIMIT 5;
---------------------------------------------------------------------------------------
-- Task 6. Calculate the total number of orders placed by each customer in the year 2016.
SELECT
	YEAR(Order_Date) AS Order_year,
	Customer_ID,
    Customer_Name,
    COUNT(Order_ID) AS Total_orders
FROM sales_data
WHERE YEAR(Order_Date) = 2016
GROUP BY Customer_ID, Customer_Name, Order_year
ORDER BY Total_orders DESC;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* **Advanced:** */
-------------------------------------------------------------------------------
-- Task 1. Calculate the average delivery time (from purchase to delivered timestamp) grouped by state. 
SELECT
	AVG( DATEDIFF(Ship_Date, Order_Date)) AS Delivery_time,
    State
FROM sales_data
GROUP BY State
ORDER BY Delivery_time DESC;
-------------------------------------------------------------------------------------
-- Task 2. Perform a cohort analysis to calculate retention rates of customers grouped by their first purchase month. 
WITH First_Purchase AS (
    SELECT 
        Customer_ID,
        MIN(Order_Date) AS First_Purchase_Date
    FROM sales_data
    GROUP BY Customer_ID
),

First_Purchase_Month AS (
    SELECT 
        Customer_ID,
        YEAR(First_Purchase_Date) AS First_Purchase_Year,
        MONTH(First_Purchase_Date) AS First_Purchase_Month
    FROM First_Purchase
),
Subsequent_Purchases AS (
	SELECT
		s.Customer_ID,
        YEAR(s.Order_Date) AS Purchase_Year,
        MONTH(s.Order_Date) AS Purchase_Month
    FROM sales_data s
)
SELECT
    fp.First_Purchase_Year,
    fp.First_Purchase_Month,
    sp.Purchase_Year,
    sp.Purchase_Month,
    COUNT(DISTINCT sp.Customer_ID) AS Customers_with_Purchase,
    COUNT(DISTINCT fp.Customer_ID) AS Cohort_Size,
    (COUNT(DISTINCT sp.Customer_ID) / COUNT(DISTINCT fp.Customer_ID)) * 100 AS Retention_Rate
FROM First_Purchase_Month fp
LEFT JOIN Subsequent_Purchases sp
    ON fp.Customer_ID = sp.Customer_ID
    AND (sp.Purchase_Year > fp.First_Purchase_Year OR
         (sp.Purchase_Year = fp.First_Purchase_Year AND sp.Purchase_Month >= fp.First_Purchase_Month))
GROUP BY fp.First_Purchase_Year, fp.First_Purchase_Month, sp.Purchase_Year, sp.Purchase_Month
ORDER BY fp.First_Purchase_Year, fp.First_Purchase_Month, sp.Purchase_Year, sp.Purchase_Month;
-------------------------------------------------------------------------------------------------------
-- Task 3. Identify the most popular product category for each year based on the number of orders. 
SELECT
	Order_Year,
    Category AS Popular_Category ,
    No_of_Orders
FROM (
SELECT
    YEAR(Order_Date) AS Order_Year,
	Category,
    COUNT(Order_ID) AS No_of_Orders,
    RANK() OVER(PARTITION BY YEAR(Order_Date) ORDER BY COUNT(Order_ID) DESC) AS Category_Rank
FROM sales_data
GROUP BY Order_Year, Category) AS A
WHERE Category_Rank = 1;
------------------------------------------------------------------------------
-- Task 4. Calculate the lifetime value (LTV) of each customer based on their purchase history. 
SELECT
	Customer_ID,
    Customer_Name,
    ROUND(SUM(Sales),2) AS LTV_of_Customer,
    COUNT(Order_ID) AS Total_Orders
FROM sales_data
GROUP BY Customer_ID, Customer_Name
ORDER BY LTV_of_Customer DESC;
---------------------------------------------------------------------------------
-- Task 5. Identify categories & sub categories with profit percentage to total profit.
SELECT
	Category,
    Sub_Category,
    Total_Orders,
    Over_all_profit,
    Total_Cat_Profit,
    ROUND((Total_Cat_Profit *100 / Over_all_profit),2) AS Cat_profit_percentage
FROM (
SELECT
	Category,
    Sub_Category,
    COUNT(Order_ID) AS Total_Orders,
	ROUND( SUM(Profit),2) AS Total_Cat_Profit,
    (SELECT ROUND( SUM(Profit),2) FROM sales_data) AS Over_all_profit,
    (SELECT ROUND( AVG(Profit),2) FROM sales_data) AS Over_all_avg_profit
FROM sales_data
GROUP BY Category, Sub_Category) AS A
ORDER BY Cat_profit_percentage DESC;
-------------------------------------------------------------------------------------------
-- Task 6.Find the top 3 cities with the highest average order value.
SELECT
	City,
    COUNT(Order_ID) AS Total_orders,
    ROUND( SUM( Sales),2) AS Total_sales,
	ROUND(SUM(Sales) / COUNT(Order_ID),2) AS Avg_Order_Value
FROM sales_data
GROUP BY City
ORDER BY Avg_Order_value DESC
LIMIT 3;
----------------------------------------------------------------------------------
-- Task 7. **Calculate the percentage of orders that were shipped on the same day they were placed.**
-- Method -1 using cte:
WITH get_sameday_shipped_orders AS ( SELECT
	COUNT(*) AS Sameday_shipped_orders
FROM sales_data
WHERE Order_Date = Ship_Date)
SELECT
	COUNT(*) AS Total_orders,
    Sameday_shipped_orders,
    ROUND (Sameday_shipped_orders*100 / COUNT(*) , 2) AS Sameday_shipped_orders_percentage
FROM sales_data, get_sameday_shipped_orders
GROUP BY Sameday_shipped_orders;
-- method -2 with sub query
SELECT
	COUNT(*) AS TOTAL_ORDERS,
    (SELECT COUNT(*) FROM sales_data WHERE Order_Date = Ship_Date) AS SAMEDAY_ORDERS,
    ROUND( (SELECT COUNT(*) FROM sales_data WHERE Order_Date = Ship_Date)*100 / COUNT(*),2) AS Sameday_shipped_orders_percentage
FROM sales_data;














