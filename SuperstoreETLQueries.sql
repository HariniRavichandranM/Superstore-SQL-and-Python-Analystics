USE SuperstoreDB;

--Loaded Flat CSV file into sql server.

--Data cleaning
--Checking for duplicate values, null values, Datatype, and data standardizaion

Select * from Rawdata --All Rawdata

SELECT * --Check for NUll Values
FROM Rawdata
WHERE 
    Row_ID IS NULL OR
    Order_ID IS NULL OR
    [Order_Date] IS NULL OR
    [Ship_Date] IS NULL OR
    [Ship_Mode] IS NULL OR
    [Customer_ID] IS NULL OR
    [Customer_Name] IS NULL OR
    Segment IS NULL OR
    Country IS NULL OR
    City IS NULL OR
    State IS NULL OR
    [Postal_Code] IS NULL OR
    Region IS NULL OR
    [Product_ID] IS NULL OR
    Category IS NULL OR
    [Sub_Category] IS NULL OR
    [Product_Name] IS NULL OR
    Sales IS NULL OR
    Quantity IS NULL OR
    Discount IS NULL OR
    Profit IS NULL; 

update Rawdata
set profit = 0
where row_id = 7345;

SELECT --Data type verificaton
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'rawdata';

select * from Rawdata;
--Quantity, Discount, Profit is nvarchar

SELECT * --Finding Non numeric values before casting
FROM Rawdata
WHERE 
	ISNUMERIC(Quantity) = 0 OR
	ISNUMERIC(Discount) = 0 OR
	ISNUMERIC(Profit) =0;

SELECT  --Testing using TRY_CAST
	TRY_CAST(Quantity AS int) AS Quantity_INT,
	TRY_CAST(Discount AS float) AS Discount_FLOAT,
	TRY_CAST(Profit AS float) AS Profit_FLOAT
FROM Rawdata;


ALTER TABLE Rawdata -- Alter the Datatypes 
ALTER COLUMN Quantity int ;
ALTER TABLE Rawdata
ALTER COLUMN Discount float;
ALTER TABLE Rawdata
ALTER COLUMN Profit float;

--Data Standardization
 --Removing leading or trailing spaces in cols
 UPDATE Rawdata SET Customer_ID= LTRIM(RTRIM(Customer_ID)); 
UPDATE Rawdata SET Customer_Name = LTRIM(RTRIM(Customer_Name)); 
UPDATE Rawdata SET City = LTRIM(RTRIM(CITY));
UPDATE Rawdata SET Category = LTRIM(RTRIM(CATEGORY));
UPDATE Rawdata SET Sub_Category = LTRIM(RTRIM(Sub_Category)) ;

-- converting into Uppercase(best for Grouping and joins)
 UPDATE Rawdata SET Customer_ID= UPPER(Customer_ID); 
UPDATE Rawdata SET Customer_Name = UPPER(Customer_Name);
UPDATE Rawdata SET City = UPPER(City);
UPDATE Rawdata SET Country = UPPER(Country);
UPDATE Rawdata SET Category = UPPER(Category);
UPDATE Rawdata SET Sub_Category= UPPER(Sub_Category);

--Fixing inconsistant data
UPDATE Rawdata SET Sub_Category = 'PHONES' WHERE Sub_Category = 'PHONEE';

-- Check for NULLs in numeric fields
SELECT COUNT(*) FROM Rawdata WHERE Sales IS NULL OR Profit IS NULL OR Discount IS NULL;

--Fill nulls with 0
UPDATE Rawdata SET Sales = 0 WHERE Sales IS NULL;
UPDATE Rawdata SET Profit = 0 WHERE Profit IS NULL;

--Data Normalization 
 -- Creating Dim and fact tables
 Select * from Rawdata;

 CREATE TABLE Customer_Dim ( --Create Customer_dim table
	Customer_key INT IDENTITY(1,1) PRIMARY KEY,
    Customer_ID NVARCHAR(50),
    Customer_Name NVARCHAR(100),
    Segment NVARCHAR(50),
);
select * from Rawdata;
select * from Customer_Dim;
INSERT INTO Customer_Dim(Customer_ID,Customer_Name,Segment) --INSERT into Customer_Dim table
SELECT DISTINCT
	Customer_ID,
	Customer_Name,
	Segment
FROM Rawdata
WHERE Customer_ID IS NOT NULL;

CREATE TABLE ADDRESS_DIM( --Create Address_Dim table
	Address_key INT IDENTITY(1,1) PRIMARY KEY,
	Customer_ID NVARCHAR(50),
	Country nvarchar(50),
	City NVARCHAR(50),
	State NVARCHAR(50),
	Postal_Code INT,
	Region NVARCHAR(50)
);

SELECT * FROM ADDRESS_DIM;

INSERT INTO ADDRESS_DIM(Customer_ID,Country,City,State,Postal_Code,Region)
SELECT DISTINCT
	Customer_ID,
	Country,
	City,
	State,
	Postal_Code,
	Region
FROM Rawdata
WHERE Customer_ID IS NOT NULL;

ALTER TABLE ADDRESS_dim ADD Customer_key int; -- adding customer_key to address_dim table
Select * from ADDRESS_DIM;

UPDATE A --update customer_key in the address_dim
SET A.Customer_key = C.Customer_key
FROM ADDRESS_DIM A
JOIN Customer_Dim C ON A.Customer_ID= C.Customer_ID;

ALTER TABLE ADDRESS_DIM --Drop Customer_ID col
DROP COLUMN Customer_ID;

CREATE TABLE Product_dim(--Create Product_dim table
	Product_Key NVARCHAR(50),
    Product_ID NVARCHAR(50),
    Product_Name NVARCHAR(150),
    Sub_Category NVARCHAR(50),
    Category NVARCHAR(50)	
); 
--Add Surrogate Keys to Product_Dim
ALTER TABLE Product_dim ADD NEW_KEY int iDentity(1,1) PRIMARY KEY;
ALTER TABLE Product_Dim DROP COLUMN Product_key;
EXEC sp_rename 'Product_Dim.NEW_KEY','Product_Key','COLUMN';

INSERT INTO Product_dim(Product_ID,Product_Name,Category,Sub_Category) -- insert into products_dim
SELECT DISTINCT
	Product_ID,
	Product_Name,
	Category,
	Sub_Category
FROM Rawdata
WHERE Product_ID IS NOT NULL;
SELECT * FROM Product_dim;

CREATE TABLE Orders_Fact ( --Create Order_fact table
	Order_key INT IDENTITY(1,1) PRIMARY KEY,
    Order_ID NVARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Customer_Key INT,
	Product_Key INT,
    Sales FLOAT,
    Quantity tinyINT,
    Discount FLOAT,
    Profit FLOAT,
    FOREIGN KEY (Customer_KEY) REFERENCES Customer_Dim(Customer_Key),
    FOREIGN KEY (Product_Key) REFERENCES Product_Dim(Product_Key)
);

ALTER TABLE Orders_fact ADD Address_Key INT;
--Insert records into Dimension tables

INSERT INTO Orders_Fact(Order_ID,Order_Date,Ship_Date,Customer_Key,Product_Key,Sales,Quantity,Discount,Profit, Address_Key)
SELECT DISTINCT
	R.Order_ID,
	R.Order_Date,
	R.Ship_Date,
	C.Customer_key,
	P.Product_Key,
	R.Sales,
	R.Quantity,
	R.Discount,
	R.Profit,
	A.Address_key
FROM Rawdata R
JOIN Customer_Dim C ON R.Customer_ID =C.Customer_ID
JOIN Product_dim P ON R.Product_ID = p.Product_ID
JOIN ADDRESS_DIM A ON A.Customer_key = C.Customer_key AND R.Postal_Code = A.Postal_Code AND R.City = A.City AND R.State = A.State AND R.Country = A.Country
WHERE R.Customer_ID IS NOT NULL
	AND R.Product_ID IS NOT NULL;

SELECT MIN(Order_Date), MAX(Order_Date)
FROM Orders_Fact;
SELECT MIN(Ship_Date), MAX(Ship_Date)
FROM Orders_Fact;


CREATE TABLE Date_Dim(--create Date_dim table
	Date_Key INT PRIMARY KEY,
	Full_Date DATE,
	Day INT,
	Month INT,
	Month_name NVARCHAR(50),
	Quarter INT,
	Year INT,
	Day_oF_Week INT,
	Day_Name NVARCHAR(50),
	IS_Weekend BIT
);
alter table date_dim drop column day_of_week;

DECLARE @start_date DATE = '2011-01-02';
DECLARE @end_date DATE = '2015-01-07';
WITH calender AS( -- CTE generate date and insert into date_dim Table
	SELECT @start_date as datevalue
	UNION ALL
	SELECT DATEADD(DAY,1,datevalue)
	from calender
	WHERE datevalue < @end_date
)

INSERT INTO Date_Dim(Date_Key, Full_Date,Day,Month,Month_name,Quarter ,Year,Day_Name,IS_Weekend) -- insert into date_dim table
SELECT 
	CONVERT(INT, FORMAT(datevalue,'yyyyMMdd')) AS Date_Key,
	datevalue as Full_date,
	day(datevalue) as day,
	MONTH(datevalue) as Month,
	DATENAME(MONTH, datevalue) as Month_name,
	DATEPART(QUARTER, datevalue) as Quarter,
	YEAR(datevalue) as Year,
	DATENAME(WEEKDAY, datevalue) as Day_Name,
	case
		when DATENAME(WEEKDAY, datevalue) in ('Saturday','Sunday') THEN 1
		ELSE 0
	end as is_weekend
FROM calender
OPTION (MAXRECURSION 32767);

--Create order_fact and Date_dim relationship 
ALTER TABLE Orders_Fact ADD Orderdatekey INT; --add orderdatekey col
ALTER TABLE Orders_Fact ADD Shipdatekey INT;--add shipdatekey col

UPDATE Orders_Fact --update orderdatekey, shipdatekey cols
SET 
	Orderdatekey = DD1.date_key,
	Shipdatekey = DD2.Date_key
FROM Orders_Fact 
join Date_dim DD1 ON Orders_Fact.ORDER_DATE = DD1.Full_Date
join Date_dim DD2 ON Orders_Fact.SHIP_DATE = DD2.Full_Date;

ALTER TABLE Orders_Fact DROP COLUMN Order_date;
ALTER TABLE Orders_Fact DROP COLUMN Ship_date;

select * from Orders_Fact;
-- Adding additional calculated Cols
ALTER TABLE Orders_Fact ADD Cost_Per_Unit FLOAT;
ALTER TABLE Orders_fact ADD Discount_flag bit;
ALTER TABLE Orders_fact ADD IS_Loss Bit;

update Orders_Fact
set cost_per_unit = round((Sales - Profit)/nullif(Quantity,0) ,2) ,
	Discount_flag = CASE WHEN Discount > 0 THEN 1 
						ELSE 0 
					END ,
	IS_Loss = CASE WHEN Profit < 0 THEN 1 
		ELSE 0
	END; 

-- Create Views
Alter VIEW vw_Sales_Summary_Time AS-- Create view for Total sales, profit, and quantity by date,
SELECT 
	D.Year,
	D.Quarter,
	D.Month,
	D.Month_name,
	D.DAY,
	D.DAY_nAME,
	SUM(O.Sales) AS Total_Sales,
	sum(O.Profit) as Total_Profit,
	SUM(O.Quantity) AS Total_Quantity
FROM Orders_Fact O
JOIN Date_Dim D ON O.Orderdatekey = D.Date_Key
GROUP BY D.Year, D.Quarter,D.Month,D.Month_name, d.Day,d.Day_Name;

select * from vw_Sales_Summary_time order by YEAR, quarter, month, day;

CREATE VIEW vw_Sales_Summary_Category AS --Sales, profit, quantity by category, subcategory
 SELECT
	P.Category,
	P.Sub_Category,
	SUM(O.Sales) AS Total_Sales,
	ROUND(SUM(o.Profit),2) AS Total_Profit,
	SUM(O.Quantity) AS No_of_Products_Sold
FROM Orders_Fact O
JOIN Product_dim P ON O.Product_Key= P.Product_Key
GROUP BY P.Category,P.Sub_Category;


ALTER VIEW vw_Sales_Summary_Region AS --view as Sales, Profit, Quantity by Region, country, city
SELECT 
	A.Region,
	A.Country,
	A.City,
	P.Category ,
	P.Product_Name ,
	--Aggreagated metrics per Regio, country, city
	ROUND(SUM(O.Sales) OVER (PARTITION BY A.Region, A. Country, A.City),2) AS Total_Sales,
	ROUND(SUM(O.Profit) OVER (PARTITION BY A.Region, A. Country, A.City),2) AS Total_profit,
	ROUND(SUM(Quantity)OVER (PARTITION BY A.Region, A. Country, A.City),2) AS Total_Quantity
FROM Orders_Fact O
JOIN ADDRESS_DIM A ON O.Address_Key = A.Address_key
join Product_dim p on o.Product_Key = p.Product_Key;

select * from vw_Sales_Summary_region;

CREATE VIEW vw_Customer_Profitability AS -- Sales, profit, quantity by customer view
SELECT 
	C.Customer_ID,
	
	ROUND(SUM(O.Sales),2) AS Total_Sales,
	ROUND(SUM(O.Profit),2) AS Total_profit,
	ROUND(SUM(Quantity),2) AS Total_Quantity
FROM Orders_Fact O
JOIN Customer_Dim C ON O.Customer_Key =C.Customer_key
GROUP BY Customer_ID;

SELECT * FROM vw_Customer_Profitability
ORDER BY Total_Profit DESC;














