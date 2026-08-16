# 📊 Data Analytics SQL Project

## 📌 Project Overview

This project demonstrates **SQL-based data analytics using MySQL** on a sales data warehouse. The objective is to transform raw sales, customer, and product data into meaningful business insights using SQL queries, aggregations, joins, window functions, CTEs, subqueries, and analytical views.

The project focuses on understanding **sales performance, customer behavior, product performance, customer segmentation, and purchasing patterns**.

---

## 🎯 Business Objectives

The analysis aims to answer key business questions such as:

* How are sales changing over time?
* What are the yearly and monthly sales trends?
* What is the cumulative sales performance?
* How many customers and orders are generated over time?
* Which customers contribute the most revenue?
* How frequently do customers purchase?
* How long have customers been active?
* How can customers be segmented based on spending and purchasing history?
* What is the average order value?
* What is the average monthly customer spending?
* Which products and categories contribute to sales?
* How can customer-level information be prepared for further reporting and analysis?

---

## 🗂️ Dataset Structure

The project uses a simple data warehouse structure containing:

### Fact Table

**`gold.fact_sales`**

Contains transactional sales information such as:

* `order_number`
* `product_key`
* `customer_key`
* `order_date`
* `shipping_date`
* `due_date`
* `sales_amount`
* `quantity`
* `price`

### Dimension Tables

**`gold.dim_customers`**

Contains customer-related information:

* `customer_key`
* `customer_id`
* `customer_number`
* `first_name`
* `last_name`
* `country`
* `marital_status`
* `gender`
* `birthdate`
* `create_date`

**`gold.dim_products`**

Contains product-related information including:

* Product details
* Category
* Subcategory
* Product cost
* Product name

---

## 🛠️ Tools & Technologies

* **MySQL**
* **MySQL Workbench**
* SQL
* GitHub

---

## 🧠 SQL Concepts Used

This project covers a range of SQL concepts used in real-world data analytics:

### Basic SQL

* `SELECT`
* `WHERE`
* `ORDER BY`
* `GROUP BY`
* `HAVING`
* `DISTINCT`

### Aggregate Functions

* `SUM()`
* `COUNT()`
* `AVG()`
* `MIN()`
* `MAX()`

### Date Functions

* `YEAR()`
* `MONTH()`
* `DATE_FORMAT()`
* `TIMESTAMPDIFF()`
* `CURDATE()`

### Joins

* `LEFT JOIN`

### Advanced SQL

* Common Table Expressions (**CTEs**)
* Derived tables / subqueries
* Window functions
* Cumulative calculations
* Customer-level aggregations
* `CASE` statements
* SQL Views

---

## 📈 Key Analysis Performed

### 1. Sales Trend Analysis

Analyzed sales performance by:

* Year
* Month
* Total sales
* Total quantity
* Number of customers

This helps identify changes in sales performance over time.

---

### 2. Cumulative Sales Analysis

Used SQL window functions to calculate running sales totals.

Example:

```sql
SUM(total_sales) OVER (
    ORDER BY order_year
) AS cumulative_sales
```

The analysis follows the approach:

```text
Raw Transactions
       ↓
Yearly Aggregation
       ↓
Total Sales by Year
       ↓
Window Function
       ↓
Cumulative Sales
```

---

### 3. Customer Analysis

Customer-level metrics were calculated using:

* Total orders
* Total sales
* Total quantity purchased
* Total products purchased
* First order date
* Last order date
* Customer lifespan
* Average order value
* Average monthly spending
* Recency

---

### 4. Customer Segmentation

Customers were categorized based on their purchasing behavior and history.

Example segments include:

* **VIP** – Customers with long purchasing history and high spending
* **Regular** – Customers with long purchasing history and lower spending
* **New** – Customers with shorter purchasing history

This segmentation can help businesses design targeted customer strategies.

---

### 5. Customer Age Analysis

Customer age was calculated using MySQL's `TIMESTAMPDIFF()` function:

```sql
TIMESTAMPDIFF(
    YEAR,
    birthdate,
    CURDATE()
) AS age
```

Age groups were then used for customer analysis.

---

### 6. Product Analysis

Joined sales and product information to analyze:

* Product sales
* Product quantity
* Product categories
* Product subcategories
* Product costs
* Customer purchasing patterns

---

## 👁️ SQL View

A reusable customer reporting view was created:

```text
datawarehouseanalytics.gold.report_customers
```

The view combines customer and sales information into an analytical dataset containing fields such as:

* Customer name
* Age
* Age group
* Customer segment
* Recency
* Total orders
* Total sales
* Total quantity
* Total products
* Last order date
* Customer lifespan
* Average order value
* Average monthly spending

This view can be used as a source for future reporting and dashboard development.

---

## 🔍 Example SQL

### Yearly Sales

```sql
SELECT
    YEAR(order_date) AS order_year,
    SUM(sales_amount) AS total_sales
FROM `datawarehouseanalytics`.`gold.fact_sales`
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY order_year;
```

### Cumulative Sales

```sql
SELECT
    order_year,
    total_sales,
    SUM(total_sales) OVER (
        ORDER BY order_year
    ) AS cumulative_sales
FROM (
    SELECT
        YEAR(order_date) AS order_year,
        SUM(sales_amount) AS total_sales
    FROM `datawarehouseanalytics`.`gold.fact_sales`
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date)
) AS yearly_sales
ORDER BY order_year;
```

### Customer Aggregation

```sql
SELECT
    customer_key,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    TIMESTAMPDIFF(
        MONTH,
        MIN(order_date),
        MAX(order_date)
    ) AS lifespan
FROM base_query
GROUP BY customer_key;
```

---

## 📂 Project Structure

```text
Data_Analytics_SQL/
│
├── README.md
│
├── Data/
│   └── dataset files
│
├── SQL/
│   └── Data_Analytics_SQL.sql
│
└── Outputs/
    └── query results / screenshots
```

---

## 💡 Key Learnings

Through this project, I strengthened my ability to:

* Analyze transactional data using SQL
* Work with fact and dimension tables
* Perform business-oriented aggregations
* Analyze sales trends
* Use SQL window functions for cumulative analysis
* Build customer-level analytical datasets
* Use CTEs and subqueries for multi-step analysis
* Calculate customer metrics using date functions
* Perform customer segmentation using `CASE`
* Create reusable SQL views
* Translate business questions into SQL queries

---

## 🚀 Future Improvements

Potential extensions to this project include:

* Building a **Power BI dashboard** using the SQL view
* Adding product profitability analysis
* Performing customer cohort analysis
* Adding customer retention analysis
* Calculating year-over-year growth
* Creating product ranking analysis using window functions
* Adding more advanced customer segmentation

---

## 👤 Author

**R Subasakthi Vaishnavi**

Aspiring Data Analyst | SQL | Power BI | Excel | Looker Studio

---

⭐ **If you find this project useful, feel free to explore the SQL queries and analysis.**
