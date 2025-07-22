use SuperstoreDB;

--Monthly sales Trend, Profit/lossanalysis
SELECT
	d.Year,
	D.Month,
	D.Month_name,
	Round(SUM(O.Sales),2) AS Total_Sales,
	SUM(CASE WHEN O.Profit>0 THEN O.PROFIT ELSE 0 END) AS Total_Profit,
	SUM(CASE WHEN O.Profit<0 THEN O.Profit ELSE 0 END ) AS Total_Loss
FROM Orders_Fact O
JOIN Date_Dim D ON O.Orderdatekey = D.Date_Key
GROUP BY d.Year,D.Month, D.Month_name
order by D.Year asc, Total_Sales desc ;

--Top 3 highest selling months in each year
WITH Monthly_Sales AS( --create cte for monthly sales
	SELECT
	d.Year,
	D.Month,
	D.Month_name,
	Round(SUM(O.Sales),2) AS Total_Sales,
	SUM(CASE WHEN O.Profit>0 THEN O.PROFIT ELSE 0 END) AS Total_Profit,
	SUM(CASE WHEN O.Profit<0 THEN O.Profit ELSE 0 END ) AS Total_Loss
FROM Orders_Fact O
JOIN Date_Dim D ON O.Orderdatekey = D.Date_Key
GROUP BY d.Year,D.Month, D.Month_name
),
Ranked_Month AS( -- create cte to rank monthly sales
 SELECT *, 
		RANK() OVER(
					PARTITION BY Year
					ORDER BY Total_Sales desc
					) AS RNK
FROM Monthly_Sales
)
select * from Ranked_Month WHERE RNK<=3;-- top 3 selling months

--TOP 3 Customers by sales each year
WITH Customer_Ttl_Sales AS( --total sales of cutomer by year
	SELECT 
		D.Year,
		C.Customer_ID,
		C.Customer_Name,
		SUM(O.Sales) AS Total_Sales
	FROM Orders_Fact O
	JOIN Customer_Dim C ON O.Customer_Key =C.Customer_key
	JOIN Date_Dim D ON O.Orderdatekey = D.Date_Key
	GROUP BY D.Year,c.Customer_ID, C.Customer_Name
	),
rnk_Customer_By_Sales AS( --rank customers
	SELECT *,
	RANK() OVER (PARTITION BY Year ORDER BY Total_Sales Desc) AS RNK
	FROM Customer_Ttl_Sales
)
SELECT * FROM rnk_Customer_By_Sales  WHERE RNK < =3; --select top 3 customer bys sales each year

--New customers  each YEAR
WITH Cust_First_Orders AS(
	SELECT 
		C.Customer_ID,
		
		MIN(D.Full_Date) AS First_Ord_Date
	FROM Orders_Fact O
	JOIN Date_Dim D ON O.Orderdatekey = D.Date_Key
	JOIN Customer_Dim C ON O.Customer_Key = C.Customer_key
	GROUP BY C.Customer_ID
),
New_Cust_per_year AS(
	SELECT
		YEAR(First_Ord_Date) AS Year,
		
		COUNT(Customer_ID)  AS total_new_Cust_that_year
	FROM Cust_First_Orders
	group by YEAR(First_Ord_Date)
),
New_cust_with_YoY AS(
	SELECT
		YEAR,
		
		total_new_Cust_that_year,
		round(
			case
				when LAG(total_new_Cust_that_year) over (Order by year) is null then null
				when LAG(total_new_Cust_that_year) over (Order by year) = 0.0 then null
				
				else
					((total_new_Cust_that_year - lag(total_new_Cust_that_year) over(order by year))*100.0)/LAG(total_new_Cust_that_year) over (order by year)
			end
		,2) as YoY_Growth_Percent
	FROM New_Cust_per_year
)
select * from New_cust_with_YoY
order by YEAR;

--YoY sales Change
WITH Yearlysales AS(
	SELECT
		D.Year,
		ROUND(SUM(O.Sales), 2) AS Total_Sales
	FROM Orders_Fact O
	JOIN Date_Dim D ON O.Orderdatekey = D.Date_Key
	GROUP BY D.Year
)
SELECT
	YEAR,
	Total_Sales,
	LAG(Total_Sales) OVER (ORDER BY YEAR) AS Previous_year_Sale,
	ROUND(
		CASE
			WHEN LAG(Total_Sales) OVER (ORDER BY YEAR) IS NULL THEN NULL
			ELSE ((Total_Sales - LAG(Total_Sales) OVER (ORDER BY YEAR))*100.0)/ LAG(Total_Sales) OVER (ORDER BY YEAR)
		END
	,2)AS YoY_Growth_Percent

FROM Yearlysales;

--Running Total of Sales per product category
SELECT
	D.Full_Date AS ORDER_DATE,
	P.Category,
	O.Sales,
	SUM(O.Sales) OVER (
						PARTITION BY P.CATEGORY
						ORDER BY D.fULL_DATE ASC

						) AS RUNNING_TOTAL_SALES
FROM Orders_Fact O 
JOIN Date_Dim D ON O.Orderdatekey = D.Date_Key
JOIN Product_dim P ON O.Product_Key = P.Product_Key;


-- Identifying Repeat Customers per Product Category
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    P.Category,
    COUNT(O.Order_ID) AS Total_Orders
FROM Orders_Fact O
JOIN Customer_Dim C ON O.Customer_Key = C.Customer_Key
JOIN Product_Dim P ON O.Product_Key = P.Product_Key
GROUP BY C.Customer_ID, C.Customer_Name, P.Category
HAVING COUNT(O.Order_ID) > 1
ORDER BY P.Category, Total_Orders DESC;


--Customers with same first name
WITH Cust_Firstandlast_Name AS (
    SELECT
        Customer_ID,
        Customer_Name,
        -- Get first name safely: if no space, take whole name
        CASE 
            WHEN CHARINDEX(' ', Customer_Name) > 0 THEN LEFT(Customer_Name, CHARINDEX(' ', Customer_Name) - 1)
            ELSE Customer_Name
        END AS First_name,
        -- Get last name safely: if no space, return NULL or empty
        CASE 
            WHEN CHARINDEX(' ', Customer_Name) > 0 THEN RIGHT(Customer_Name, LEN(Customer_Name) - CHARINDEX(' ', Customer_Name))
            ELSE NULL
        END AS Last_Name
    FROM Customer_Dim
),
firstnames AS (
    SELECT *,
        COUNT(*) OVER (PARTITION BY First_name) AS name_count
    FROM Cust_Firstandlast_Name
)
SELECT
    Customer_ID,
    Customer_Name,
    First_name
FROM firstnames
WHERE name_count > 1
ORDER BY Customer_Name;


