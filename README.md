#  Superstore Sales and Customer Analytics

##  About

This project analyses Superstore's sales data to uncover trends in customer behaviour, high-performing product categories, and regional sales patterns. The goal is to deliver actionable insights that improve sales strategy and business decisions.

The analysis is powered by **SQL Server** for ETL and business logic, and **Python** for exploratory data analysis and visualisation.

---

## Project Objectives

- Clean and normalise raw sales data using SQL  
- Create a star schema for structured reporting  
- Write analytical SQL queries for business KPIs  
- Visualize the output using Python (Pandas, Matplotlib, Seaborn, Plotly)  
- Provide insights on sales performance, customer loyalty, and category trends

---

## 🗃️ Dataset Overview

The dataset contains historical sales transactions, customer information, product details, and shipping data. It was originally loaded from CSV format and ingested into a SQL Server database.

### Key Fields:
- `OrderID`, `CustomerID`, `Customer_name`, `ProductID`, `OrderDate`, `ShipDate`  
- `Sales`, `Quantity`, `Discount`, `Profit`  
- `Region`, `Country`, `State`, `City`, `Segment`, `Product_Name`, `Category`, `Sub-Category`,

---

## Tools Used

| Tool         | Purpose                              |
|--------------|---------------------------------------|
| SQL Server   | Data ingestion, cleaning, transformation, querying |
| Python       | Data analysis, charts, and visualization |
| Jupyter Lab  | Notebook environment for Python EDA   |
| Excel/CSV    | Raw data source                       |

---

##  Approach

### 1. Data Ingestion

- Loaded raw CSV file into SQL Server  
- Created staging and backup tables  
- Verified data types, nulls, and inconsistencies  

### 2. Data Cleaning & Transformation

- Removed NULLs and duplicate entries  
- Standardised categorical fields 
- Converted Quantity (INT), Discount (FLOAT), Profit (FLOAT)  
- Removed trailing spaces and uppercased text fields  
- Parsed date fields to standard DATE format

### 3. Schema Design

Created a **Star Schema**:
- `customers_dim`
- `product_dim`
- `address_dim`
- `date_dim`
- `orders_fact`

Surrogate keys and consistent foreign keys were used to maintain referential integrity.

### 4. Views for Reporting

Created SQL views to simplify reporting:
- `vw_Sales_Summary_Category` – Sales and profit by category  
- `vw_Customer_Profitability` – Profitability by customer  
- `vw_Sales_Summary_Time` – Monthly/yearly trends  
- `vw_Returning_Customers` – Customer retention tracking  

---

##  Business Analysis (SQL)

### Monthly and Yearly Trends:
- Monthly Sales and Profit/Loss
- Top 3 Highest Selling Months per Year
- YoY Sales Growth (using `LAG()`)

### Customer Behaviour:
- Top 3 Customers by Year
- New Customer Acquisition by Year
- Repeat Customers by Product Category

### Product Performance:
- Running Total Sales per Category
- Most Frequent Product Buyers
- Category-wise Profitability

### Name-Based Insights:
- Customers with the same first name used charindex()

---

## Python Visualizations

Used `Pandas`, `Matplotlib`, `Seaborn`, and `Plotly` for:
- Sales and profit trends over time  
- Category-wise sales distribution  
- Customer segmentation by region and segment  
- Repeat vs. new customers  
- Heatmaps and bar plots for region vs sales  

---

## Key SQL Features Used

- **Window Functions**: `RANK()`, `LAG()`, `SUM() OVER`  
- **CTEs**: Clean modular query design  
- **String Functions**: `LEFT()`, `RIGHT()`, `CHARINDEX()`  
- **Date Functions**: `DATEPART()`, `FORMAT()`  
- **Aggregations**: `GROUP BY`, `HAVING`, conditional `SUM()`  

---

