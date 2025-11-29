create table zepto_dataset (Category text ,name VARCHAR(255) NOT NULL,mrp integer ,discountPercent integer,availableQuantity integer,discountedSellingPrice integer,weightInGms integer 
,outOfStock BOOLEAN DEFAULT TRUE ,quantity integer)


ALTER TABLE zepto_dataset RENAME TO zepto;
select * from zepto limit 20;
select count(*) from zepto;

SELECT * FROM zepto
LIMIT 10;

--null values
SELECT * FROM zepto
WHERE name IS NULL
OR
category IS NULL
OR
mrp IS NULL
OR
discountPercent IS NULL
OR
discountedSellingPrice IS NULL
OR
weightInGms IS NULL
OR
availableQuantity IS NULL
OR
outOfStock IS NULL
OR
quantity IS NULL;

--different product categories
SELECT DISTINCT category
FROM zepto
ORDER BY category;

--products in stock vs out of stock
SELECT outOfStock, COUNT(sku_id)
FROM zepto
GROUP BY outOfStock;

--product names present multiple times
SELECT name, COUNT(sku_id) AS "Number of SKUs"
FROM zepto
GROUP BY name
HAVING count(sku_id) > 1
ORDER BY count(sku_id) DESC;

--data cleaning

--products with price = 0
SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;

--convert paise to rupees
UPDATE zepto
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;

SELECT mrp, discountedSellingPrice FROM zepto;

--data analysis

-- Q1. Find the top 10 best-value products based on the discount percentage.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

--Q2.What are the Products with High MRP but Out of Stock

SELECT DISTINCT name,mrp
FROM zepto
WHERE outOfStock = TRUE and mrp > 300
ORDER BY mrp DESC;

--Q3.Calculate Estimated Revenue for each category
SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue;

-- Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
SELECT category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6. Find the price per gram for products above 100g and sort by best value.
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;

--Q7.Group the products into categories like Low, Medium, Bulk.
SELECT DISTINCT name, weightInGms,
CASE WHEN weightInGms < 1000 THEN 'Low'
	WHEN weightInGms < 5000 THEN 'Medium'
	ELSE 'Bulk'
	END AS weight_category
FROM zepto;

--Q8.What is the Total Inventory Weight Per Category 
SELECT category,
SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight;
--Q9.Compute total revenue per category and rank each category by total sales.
WITH category_sales AS (
    SELECT
        category,
        SUM(quantity * discountedSellingPrice) AS total_revenue
    FROM zepto
    GROUP BY category
)
SELECT
    category,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_sales;

--Q10. Identify the top-selling product by revenue within each category.

WITH product_sales AS (
    SELECT
        category,
        name,
        SUM(quantity * discountedSellingPrice) AS product_revenue
    FROM zepto
    GROUP BY category, name
),
ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY product_revenue DESC) AS rn
    FROM product_sales
)
SELECT 
    category,
    name AS top_product,
    product_revenue
FROM ranked
WHERE rn = 1;
--Q11. For each category, find the heaviest product by weight.

WITH weight_rank AS (
    SELECT
        category,
        name,
        weightInGms,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY weightInGms DESC) AS rn
    FROM zepto
)
SELECT 
    category,
    name AS heaviest_product,
    weightInGms
FROM weight_rank
WHERE rn = 1;

--Q12. Determine stock health by calculating % of out-of-stock products per category.

WITH stock_stats AS (
    SELECT
        category,
        COUNT(*) FILTER (WHERE outOfStock = TRUE) AS out_items,
        COUNT(*) AS total_items
    FROM zepto
    GROUP BY category
)
SELECT
    category,
    ROUND((out_items::DECIMAL / total_items) * 100, 2) AS out_of_stock_percentage
FROM stock_stats
ORDER BY out_of_stock_percentage DESC;

--Q13. Calculate average discount offered per category and rank categories by discount.

WITH discount_summary AS (
    SELECT
        category,
        AVG(discountPercent) AS avg_discount
    FROM zepto
    GROUP BY category
)
SELECT
    category,
    avg_discount,
    DENSE_RANK() OVER (ORDER BY avg_discount DESC) AS discount_rank
FROM discount_summary;


